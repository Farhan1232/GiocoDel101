// Session 7 — the purchase flow, against fakes.
//
// The store and the verification server are both faked, which is exactly the
// honest scope of an automated IAP test: what CAN be proven here is the
// controller's behaviour — states that always settle, verification before
// completion, idempotent redelivery, a bounded listener count, and that a
// failed verification never eats the transaction. What CANNOT be proven here
// is Google Play / App Store behaviour; docs/IAP_STORE_SETUP.md carries that
// checklist.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:gioco_del_101/features/purchases/application/entitlement_repository.dart';
import 'package:gioco_del_101/features/purchases/application/purchase_controller.dart';
import 'package:gioco_del_101/features/purchases/application/purchase_store.dart';
import 'package:gioco_del_101/features/purchases/domain/entitlement.dart';

class FakeStore implements PurchaseStore {
  bool available = true;
  List<StoreProduct> products = [
    const StoreProduct(
      id: 'gioco101_premium',
      title: 'Premium',
      description: 'Sblocca il Premium.',
      price: '€4,99',
    ),
  ];

  int listeners = 0;
  int buys = 0;
  int restores = 0;
  final List<StorePurchase> completed = [];
  late final StreamController<List<StorePurchase>> _events =
      StreamController<List<StorePurchase>>.broadcast(
        onListen: () => listeners++,
        onCancel: () => listeners--,
      );

  void emit(StorePurchase p) => _events.add([p]);

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<StoreProducts> queryProducts(Set<String> ids) async => StoreProducts(
    found: [
      for (final p in products)
        if (ids.contains(p.id)) p,
    ],
    notFound: [
      for (final id in ids)
        if (!products.any((p) => p.id == id)) id,
    ],
  );

  @override
  Stream<List<StorePurchase>> get purchases => _events.stream;

  @override
  Future<void> buyNonConsumable(StoreProduct product) async {
    buys++;
  }

  @override
  Future<void> restorePurchases() async {
    restores++;
  }

  @override
  Future<void> complete(StorePurchase purchase) async {
    completed.add(purchase);
  }
}

class FakeEntitlements implements EntitlementRepository {
  PremiumEntitlement? serverRow;
  PurchaseError? failVerifyWith;
  int verifyCalls = 0;
  final List<String?> verifiedTransactions = [];

  @override
  Future<PremiumEntitlement?> status() async => serverRow;

  @override
  Future<PremiumEntitlement> verify({
    required String platform,
    required String productId,
    required String verificationData,
    String? transactionId,
  }) async {
    verifyCalls++;
    verifiedTransactions.add(transactionId);
    final failure = failVerifyWith;
    if (failure != null) throw PurchaseException(failure);
    return serverRow = PremiumEntitlement(
      status: EntitlementStatus.active,
      productId: productId,
      platform: platform,
      purchasedAt: DateTime.utc(2026, 8, 31),
    );
  }
}

StorePurchase _purchase({
  StorePurchaseStatus status = StorePurchaseStatus.purchased,
  String txn = 'GPA.1234',
  bool pendingComplete = true,
}) => StorePurchase(
  productId: 'gioco101_premium',
  status: status,
  verificationData: 'opaque-token',
  transactionId: txn,
  pendingComplete: pendingComplete,
);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late FakeStore store;
  late FakeEntitlements server;
  late PurchaseController c;

  setUp(() {
    store = FakeStore();
    server = FakeEntitlements();
    c = PurchaseController(
      store: store,
      entitlements: server,
      restoreFallbackDelay: const Duration(milliseconds: 60),
    );
    c.onInit();
  });

  tearDown(() {
    c.onClose();
  });

  group('loading always settles (§21)', () {
    test('store unavailable', () async {
      store.available = false;
      await c.load();
      expect(c.phase.value, PurchasePhase.storeUnavailable);
    });

    test('product missing in the store', () async {
      store.products = [];
      await c.load();
      expect(c.phase.value, PurchasePhase.productMissing);
      expect(c.product.value, isNull);
    });

    test('product found: price comes from the store, not from code', () async {
      await c.load();
      expect(c.phase.value, PurchasePhase.ready);
      expect(c.product.value!.price, '€4,99');
    });
  });

  group('purchase states', () {
    test('pending shows as purchasing', () async {
      await c.load();
      store.emit(_purchase(status: StorePurchaseStatus.pending));
      await _settle();
      expect(c.phase.value, PurchasePhase.purchasing);
    });

    test('cancelled settles as a cancelled error, nothing granted', () async {
      await c.load();
      await c.buy();
      store.emit(
        _purchase(status: StorePurchaseStatus.cancelled, pendingComplete: true),
      );
      await _settle();
      expect(c.phase.value, PurchasePhase.error);
      expect(c.lastError.value, PurchaseError.cancelled);
      expect(c.isPremium, isFalse);
      expect(store.completed, hasLength(1), reason: 'abandoned txn is closed');
    });

    test('store error settles as paymentFailed', () async {
      await c.load();
      store.emit(_purchase(status: StorePurchaseStatus.error));
      await _settle();
      expect(c.phase.value, PurchasePhase.error);
      expect(c.lastError.value, PurchaseError.paymentFailed);
    });

    test(
      'success: verified with the server BEFORE completing, then granted',
      () async {
        await c.load();
        await c.buy();
        expect(store.buys, 1);
        store.emit(_purchase());
        await _settle();
        expect(server.verifyCalls, 1);
        expect(server.verifiedTransactions, ['GPA.1234']);
        expect(c.phase.value, PurchasePhase.success);
        expect(c.isPremium, isTrue);
        expect(store.completed, hasLength(1));
      },
    );

    test(
      'verification failure: transaction left open, retry succeeds',
      () async {
        await c.load();
        server.failVerifyWith = PurchaseError.verificationFailed;
        store.emit(_purchase());
        await _settle();
        expect(c.phase.value, PurchasePhase.error);
        expect(c.isPremium, isFalse);
        expect(
          store.completed,
          isEmpty,
          reason:
              'completing an unverified purchase would eat the payment: the '
              'store must keep it open and redeliver it',
        );
        // The store redelivers the same transaction; this time the server is up.
        server.failVerifyWith = null;
        store.emit(_purchase());
        await _settle();
        expect(server.verifyCalls, 2);
        expect(c.phase.value, PurchasePhase.success);
        expect(c.isPremium, isTrue);
      },
    );

    test('duplicate delivery verifies once and only completes again', () async {
      await c.load();
      store.emit(_purchase());
      await _settle();
      store.emit(_purchase()); // app resume redelivers the same transaction
      await _settle();
      expect(server.verifyCalls, 1, reason: 'no double grant round-trip');
      expect(store.completed, hasLength(2));
      expect(c.isPremium, isTrue);
    });

    test('verification server unreachable never grants premium', () async {
      await c.load();
      server.failVerifyWith = PurchaseError.network;
      store.emit(_purchase());
      await _settle();
      expect(c.isPremium, isFalse);
      expect(c.lastError.value, PurchaseError.network);
    });
  });

  group('restore (§22)', () {
    test('a restored transaction verifies and settles as restored', () async {
      await c.load();
      await c.restore();
      expect(store.restores, 1);
      store.emit(
        _purchase(status: StorePurchaseStatus.restored, txn: 'GPA.old'),
      );
      await _settle();
      expect(c.phase.value, PurchasePhase.restored);
      expect(c.isPremium, isTrue);
      expect(store.buys, 0, reason: 'restoring must never charge');
    });

    test('nothing to restore settles instead of spinning forever', () async {
      await c.load();
      await c.restore();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(c.phase.value, PurchasePhase.error);
      expect(c.lastError.value, PurchaseError.nothingToRestore);
    });

    test(
      'restore finds the entitlement server-side even with no event',
      () async {
        await c.load();
        server.serverRow = PremiumEntitlement(
          status: EntitlementStatus.active,
          productId: 'gioco101_premium',
          platform: 'android',
          purchasedAt: DateTime.utc(2026, 1, 1),
        );
        await c.restore();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(c.phase.value, PurchasePhase.restored);
        expect(c.isPremium, isTrue);
      },
    );
  });

  group('entitlement is the server\'s word (§23)', () {
    test('expired entitlement is not premium', () async {
      server.serverRow = PremiumEntitlement(
        status: EntitlementStatus.active,
        productId: 'p',
        platform: 'android',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      await c.refreshEntitlement();
      expect(c.isPremium, isFalse);
    });

    test('revoked entitlement is not premium', () async {
      server.serverRow = const PremiumEntitlement(
        status: EntitlementStatus.revoked,
        productId: 'p',
        platform: 'android',
      );
      await c.refreshEntitlement();
      expect(c.isPremium, isFalse);
    });

    test('active with a future expiry is premium until then', () async {
      server.serverRow = PremiumEntitlement(
        status: EntitlementStatus.active,
        productId: 'p',
        platform: 'android',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      await c.refreshEntitlement();
      expect(c.isPremium, isTrue);
    });

    test('no backend: nothing is granted and nothing crashes', () async {
      final offline = PurchaseController(
        store: const UnavailablePurchaseStore(),
        entitlements: const NoBackendEntitlementRepository(),
      );
      offline.onInit();
      await offline.load();
      expect(offline.phase.value, PurchasePhase.storeUnavailable);
      expect(offline.isPremium, isFalse);
      offline.onClose();
    });
  });

  group('listener lifecycle (§20)', () {
    test('exactly one stream subscription, cancelled on close', () async {
      expect(store.listeners, 1);
      await c.load();
      await c.buy();
      await c.restore();
      store.emit(_purchase());
      await _settle();
      expect(store.listeners, 1, reason: 'nothing may resubscribe');
      c.onClose();
      await _settle();
      expect(store.listeners, 0, reason: 'onClose must cancel');
      // tearDown will call onClose again; that must be harmless.
    });
  });
}
