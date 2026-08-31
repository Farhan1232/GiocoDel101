import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/log.dart';
import '../domain/entitlement.dart';
import '../domain/purchase_config.dart';
import 'entitlement_repository.dart';
import 'purchase_store.dart';

/// Where the purchase flow currently stands. One value: the screen renders
/// it, and nothing can be simultaneously "buying" and "failed".
enum PurchasePhase {
  idle,
  loading,
  storeUnavailable,
  productMissing,
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
/// redelivered on launch — not just while the premium screen is open).
///
/// Trust model: a store event is only ever a *claim*. Premium is granted by
/// the server after verifying the purchase with Google/Apple; this class
/// forwards the claim, adopts the server's answer, and only then completes
/// the transaction with the store. A verification failure leaves the
/// transaction open so the store redelivers it later.
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

  final Rxn<PremiumEntitlement> entitlement = Rxn<PremiumEntitlement>();
  final Rxn<StoreProduct> product = Rxn<StoreProduct>();
  final Rx<PurchasePhase> phase = PurchasePhase.idle.obs;
  final Rxn<PurchaseError> lastError = Rxn<PurchaseError>();

  StreamSubscription<List<StorePurchase>>? _sub;
  Timer? _restoreFallback;

  /// Store transactions already verified in this session, so a redelivered
  /// update cannot trigger a second grant round-trip.
  final Set<String> _handled = <String>{};

  /// The server's word, evaluated now. False while offline with no cached
  /// read — premium is never assumed.
  bool get isPremium => entitlement.value?.isActiveAt(_clock()) ?? false;

  String get platformName => GetPlatform.isIOS ? 'ios' : 'android';

  String get premiumProductId => GetPlatform.isIOS
      ? PurchaseConfig.iosPremiumId
      : PurchaseConfig.androidPremiumId;

  @override
  void onInit() {
    super.onInit();
    // The single subscription (§20). Errors are logged, never thrown: a
    // store hiccup must not take the app down.
    _sub = store.purchases.listen(
      _onUpdates,
      onError: (Object e) => Log.d('purchase stream: $e'),
    );
    unawaited(refreshEntitlement());
  }

  @override
  void onClose() {
    _restoreFallback?.cancel();
    unawaited(_sub?.cancel());
    _sub = null;
    super.onClose();
  }

  /// Loads the store product for the premium screen. Ends in exactly one of
  /// ready / storeUnavailable / productMissing — never a forever-spinner.
  Future<void> load() async {
    if (phase.value == PurchasePhase.loading) return;
    phase.value = PurchasePhase.loading;
    lastError.value = null;
    unawaited(refreshEntitlement());
    try {
      if (!await store.isAvailable()) {
        phase.value = PurchasePhase.storeUnavailable;
        return;
      }
      final result = await store.queryProducts({premiumProductId});
      if (result.found.isEmpty) {
        product.value = null;
        phase.value = PurchasePhase.productMissing;
        return;
      }
      product.value = result.found.first;
      phase.value = PurchasePhase.ready;
    } catch (e) {
      Log.d('purchase load: $e');
      phase.value = PurchasePhase.storeUnavailable;
    }
  }

  /// Starts the store's own payment sheet. The outcome arrives on the
  /// purchase stream, not here.
  Future<void> buy() async {
    final p = product.value;
    if (p == null || phase.value == PurchasePhase.purchasing) return;
    phase.value = PurchasePhase.purchasing;
    lastError.value = null;
    try {
      await store.buyNonConsumable(p);
    } catch (e) {
      Log.d('purchase buy: $e');
      _fail(PurchaseError.paymentFailed);
    }
  }

  /// "Ripristina acquisti". Restorations arrive on the purchase stream; if
  /// none does, the fallback re-reads the server and settles the UI either
  /// way. Restoring never charges.
  Future<void> restore() async {
    if (phase.value == PurchasePhase.purchasing) return;
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
      await refreshEntitlement();
      if (isPremium) {
        phase.value = PurchasePhase.restored;
      } else {
        _fail(PurchaseError.nothingToRestore);
      }
    });
  }

  Future<void> refreshEntitlement() async {
    try {
      entitlement.value = await entitlements.status();
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
    phase.value = PurchasePhase.verifying;
    try {
      entitlement.value = await entitlements.verify(
        platform: platformName,
        productId: update.productId,
        verificationData: update.verificationData,
        transactionId: update.transactionId,
      );
      // Only a verified, granted purchase is completed with the store.
      await _complete(update);
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

  Future<void> _complete(StorePurchase update) async {
    if (!update.pendingComplete) return;
    try {
      await store.complete(update);
    } catch (e) {
      Log.d('purchase complete: $e');
    }
  }

  void _fail(PurchaseError error) {
    lastError.value = error;
    phase.value = PurchasePhase.error;
  }
}
