import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/log.dart';
import '../domain/entitlement.dart';
import '../domain/shop_catalog.dart';
import 'entitlement_repository.dart';
import 'purchase_store.dart';

/// Where the purchase flow currently stands. One value: the screen renders
/// it, and nothing can be simultaneously "buying" and "failed".
enum PurchasePhase {
  idle,
  loading,
  storeUnavailable,
  ready,
  purchasing,
  verifying,
  success,
  restored,
  error,
}

/// The one owner of the store connection.
///
/// Registered permanently at boot so the purchase stream has exactly one
/// subscriber for the app's whole life (§: a purchase can arrive at ANY
/// time — a pending card payment clearing, an unfinished transaction
/// redelivered on launch — not just while the shop is open). Navigation,
/// login/logout and app resume never add a second listener because nothing
/// else ever subscribes.
///
/// Trust model: a store event is only ever a *claim*. An item is granted by
/// the server after verifying the purchase with Google/Apple; this class
/// forwards the claim, adopts the server's answer, and only then completes
/// the transaction with the store. A verification failure leaves the
/// transaction open so the store redelivers it later.
///
/// Ownership is per item: five products, five independent entitlements
/// (ShopCatalog). A player may own none, one, several or all.
class PurchaseController extends GetxController {
  PurchaseController({
    required this.store,
    required this.entitlements,
    DateTime Function()? clock,
    this.restoreFallbackDelay = const Duration(seconds: 8),
  }) : _clock = clock ?? DateTime.now;

  final PurchaseStore store;
  final EntitlementRepository entitlements;
  final DateTime Function() _clock;

  /// How long a restore may sit silent before the server is re-read and the
  /// UI settled. Injectable so tests need not wait the real eight seconds.
  final Duration restoreFallbackDelay;

  /// The server's rows, one per owned item (any status).
  final RxList<OwnedEntitlement> owned = RxList<OwnedEntitlement>();

  /// Store metadata by product id — the ONLY source of displayed prices.
  final RxMap<String, StoreProduct> products = RxMap<String, StoreProduct>();

  /// Product ids the store did not return (not yet created in the console, or
  /// not available in this territory). The shop shows these as unavailable —
  /// never with an invented price.
  final RxSet<String> unavailableProducts = RxSet<String>();

  final Rx<PurchasePhase> phase = PurchasePhase.idle.obs;
  final Rxn<PurchaseError> lastError = Rxn<PurchaseError>();

  /// Product id of the purchase currently in flight, so the shop can spin
  /// exactly one card. Null when idle or restoring.
  final RxnString busyProductId = RxnString();

  StreamSubscription<List<StorePurchase>>? _sub;
  Timer? _restoreFallback;

  /// Store transactions already verified in this session, so a redelivered
  /// update cannot trigger a second grant round-trip.
  final Set<String> _handled = <String>{};

  /// Whether the player owns [entitlement] (e.g. `table.gold`) right now,
  /// on the server's word. False while signed out or offline with no cached
  /// read — ownership is never assumed.
  bool owns(String entitlement) {
    final now = _clock();
    for (final e in owned) {
      if (e.entitlement == entitlement && e.isActiveAt(now)) return true;
    }
    return false;
  }

  /// Whether the product with [productId] is owned.
  bool ownsProduct(String productId) {
    final p = ShopCatalog.byId(productId);
    return p != null && owns(p.entitlement);
  }

  String get platformName => GetPlatform.isIOS ? 'ios' : 'android';

  @override
  void onInit() {
    super.onInit();
    // The single subscription (§16). Errors are logged, never thrown: a
    // store hiccup must not take the app down.
    _sub = store.purchases.listen(
      _onUpdates,
      onError: (Object e) => Log.d('purchase stream: $e'),
    );
    unawaited(refreshEntitlements());
  }

  @override
  void onClose() {
    _restoreFallback?.cancel();
    unawaited(_sub?.cancel());
    _sub = null;
    super.onClose();
  }

  /// Loads store metadata for all five products. Ends in exactly one of
  /// ready / storeUnavailable — never a forever-spinner. Products the store
  /// does not know land in [unavailableProducts] rather than failing the
  /// whole shop.
  Future<void> load() async {
    if (phase.value == PurchasePhase.loading) return;
    phase.value = PurchasePhase.loading;
    lastError.value = null;
    unawaited(refreshEntitlements());
    try {
      if (!await store.isAvailable()) {
        phase.value = PurchasePhase.storeUnavailable;
        return;
      }
      final result = await store.queryProducts(ShopCatalog.productIds);
      products.assignAll({for (final p in result.found) p.id: p});
      unavailableProducts.assignAll(result.notFound.toSet());
      phase.value = PurchasePhase.ready;
    } catch (e) {
      Log.d('purchase load: $e');
      phase.value = PurchasePhase.storeUnavailable;
    }
  }

  /// Starts the store's own payment sheet for one product. The outcome
  /// arrives on the purchase stream, not here.
  Future<void> buy(String productId) async {
    final p = products[productId];
    if (p == null ||
        phase.value == PurchasePhase.purchasing ||
        phase.value == PurchasePhase.verifying) {
      return;
    }
    busyProductId.value = productId;
    phase.value = PurchasePhase.purchasing;
    lastError.value = null;
    try {
      await store.buyNonConsumable(p);
    } catch (e) {
      Log.d('purchase buy: $e');
      _fail(PurchaseError.paymentFailed);
    }
  }

  /// "Ripristina acquisti". Restorations arrive on the purchase stream (one
  /// event per owned non-consumable); if none does, the fallback re-reads the
  /// server and settles the UI either way. Restoring never charges.
  Future<void> restore() async {
    if (phase.value == PurchasePhase.purchasing ||
        phase.value == PurchasePhase.verifying) {
      return;
    }
    busyProductId.value = null;
    phase.value = PurchasePhase.purchasing;
    lastError.value = null;
    try {
      await store.restorePurchases();
    } catch (e) {
      Log.d('purchase restore: $e');
      _fail(PurchaseError.storeUnavailable);
      return;
    }
    _restoreFallback?.cancel();
    _restoreFallback = Timer(restoreFallbackDelay, () async {
      if (phase.value != PurchasePhase.purchasing) return;
      await refreshEntitlements();
      if (owned.any((e) => e.isActiveAt(_clock()))) {
        busyProductId.value = null;
        phase.value = PurchasePhase.restored;
      } else {
        _fail(PurchaseError.nothingToRestore);
      }
    });
  }

  Future<void> refreshEntitlements() async {
    try {
      owned.assignAll(await entitlements.status());
    } on PurchaseException catch (e) {
      // Offline: keep whatever was last read; never invent an answer.
      Log.d('entitlement status: ${e.error.name}');
    } catch (e) {
      Log.d('entitlement status: $e');
    }
  }

  Future<void> _onUpdates(List<StorePurchase> updates) async {
    for (final update in updates) {
      switch (update.status) {
        case StorePurchaseStatus.pending:
          busyProductId.value = update.productId;
          phase.value = PurchasePhase.purchasing;
        case StorePurchaseStatus.cancelled:
          await _complete(update);
          if (phase.value == PurchasePhase.purchasing ||
              phase.value == PurchasePhase.verifying) {
            _fail(PurchaseError.cancelled);
          }
        case StorePurchaseStatus.error:
          await _complete(update);
          _fail(PurchaseError.paymentFailed);
        case StorePurchaseStatus.purchased:
        case StorePurchaseStatus.restored:
          await _deliver(update);
      }
    }
  }

  Future<void> _deliver(StorePurchase update) async {
    _restoreFallback?.cancel();
    // Idempotency: the same transaction redelivered (app restart, resume,
    // both `purchased` and `restored` events) is verified once.
    final key =
        update.transactionId ??
        '${update.productId}:${update.verificationData.hashCode}';
    if (_handled.contains(key)) {
      await _complete(update);
      return;
    }
    _handled.add(key);
    busyProductId.value = update.productId;
    phase.value = PurchasePhase.verifying;
    try {
      final granted = await entitlements.verify(
        platform: platformName,
        productId: update.productId,
        verificationData: update.verificationData,
        transactionId: update.transactionId,
      );
      _adopt(granted);
      // Only a verified, granted purchase is completed with the store.
      await _complete(update);
      busyProductId.value = null;
      phase.value = update.status == StorePurchaseStatus.restored
          ? PurchasePhase.restored
          : PurchasePhase.success;
      lastError.value = null;
    } on PurchaseException catch (e) {
      // NOT completed: the store keeps the transaction open and redelivers
      // it, so a transient server failure cannot eat a payment. Retryable.
      _handled.remove(key);
      _fail(e.error);
    } catch (e) {
      Log.d('purchase verify: $e');
      _handled.remove(key);
      _fail(PurchaseError.verificationFailed);
    }
  }

  /// Merges one server-granted row into [owned] without waiting for a full
  /// re-read (which still happens on the next load()).
  void _adopt(OwnedEntitlement granted) {
    final next = [
      for (final e in owned)
        if (e.entitlement != granted.entitlement) e,
      granted,
    ];
    owned.assignAll(next);
  }

  Future<void> _complete(StorePurchase update) async {
    if (!update.pendingComplete) return;
    try {
      await store.complete(update);
    } catch (e) {
      Log.d('purchase complete: $e');
    }
  }

  void _fail(PurchaseError error) {
    busyProductId.value = null;
    lastError.value = error;
    phase.value = PurchasePhase.error;
  }
}
