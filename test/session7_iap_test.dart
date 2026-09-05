// Sessions 7–8 — the purchase flow, against fakes.
//
// The store and the verification server are both faked, which is exactly the
// honest scope of an automated IAP test: what CAN be proven here is the
// controller's behaviour — states that always settle, verification before
// completion, idempotent redelivery, a bounded listener count, per-item
// entitlements, and that a failed verification never eats the transaction.
// What CANNOT be proven here is Google Play / App Store behaviour;
// docs/IAP_STORE_SETUP.md carries that checklist.
//
// Session 8 moved the model from one placeholder "premium" product to the
// five cosmetic non-consumables (ShopCatalog): every case below runs against
// real catalog ids, and no test relies on a hard-coded displayed price — the
// price is whatever metadata the (fake) store returns.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:gioco_del_101/features/purchases/application/entitlement_repository.dart';
import 'package:gioco_del_101/features/purchases/application/purchase_controller.dart';
import 'package:gioco_del_101/features/purchases/application/purchase_store.dart';
import 'package:gioco_del_101/features/purchases/domain/entitlement.dart';
import 'package:gioco_del_101/features/purchases/domain/shop_catalog.dart';

class FakeStore implements PurchaseStore {
  bool available = true;

  /// Store metadata for every catalog product; the price strings stand in
  /// for whatever localized value the real store would return.
  List<StoreProduct> products = [
    for (final p in ShopCatalog.products)
      StoreProduct(
        id: p.id,
        title: p.id,
        description: 'store description',
        price: 'PRICE(${p.id})',
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
  /// Server rows by entitlement key — the multi-item authoritative state.
  final Map<String, OwnedEntitlement> rows = {};
  PurchaseError? failVerifyWith;
  int verifyCalls = 0;
  final List<String?> verifiedTransactions = [];

  void grantServerSide(String productId) {
    final p = ShopCatalog.byId(productId)!;
    rows[p.entitlement] = OwnedEntitlement(
      entitlement: p.entitlement,
      status: EntitlementStatus.active,
      productId: productId,
      platform: 'android',
      purchasedAt: DateTime.utc(2026, 1, 1),
    );
  }

  @override
  Future<List<OwnedEntitlement>> status() async => rows.values.toList();

  @override
  Future<OwnedEntitlement> verify({
    required String platform,
    required String productId,
    required String verificationData,
    String? transactionId,
  }) async {
    verifyCalls++;
    verifiedTransactions.add(transactionId);
    final failure = failVerifyWith;
    if (failure != null) throw PurchaseException(failure);
    final product = ShopCatalog.byId(productId);
    if (product == null) {
      // The server's allow-list: an unknown product is refused before any
      // store call (verify.ts).
      throw const PurchaseException(PurchaseError.productMissing);
    }
    return rows[product.entitlement] = OwnedEntitlement(
      entitlement: product.entitlement,
      status: EntitlementStatus.active,
      productId: productId,
      platform: platform,
      purchasedAt: DateTime.utc(2026, 8, 31),
    );
  }
}

StorePurchase _purchase({
  String productId = ShopCatalog.tableGoldId,
  StorePurchaseStatus status = StorePurchaseStatus.purchased,
  String txn = 'GPA.1234',
  bool pendingComplete = true,
}) => StorePurchase(
  productId: productId,
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

  group('catalog', () {
    test('exactly the five canonical products, five distinct entitlements', () {
      expect(ShopCatalog.productIds, {
        'gioco101_table_gold',
        'gioco101_table_classic',
        'gioco101_deck_special',
        'gioco101_cardback_gold',
        'gioco101_gadget_01',
      });
      expect(
        {for (final p in ShopCatalog.products) p.entitlement},
        {
          'table.gold',
          'table.classic',
          'deck.special',
          'cardback.gold',
          'gadget.01',
        },
      );
    });
  });

  group('loading always settles (§21)', () {
    test('store unavailable', () async {
      store.available = false;
      await c.load();
      expect(c.phase.value, PurchasePhase.storeUnavailable);
    });

    test(
      'missing products land in unavailableProducts, shop still loads',
      () async {
        store.products = store.products
            .where((p) => p.id != ShopCatalog.gadgetId)
            .toList();
        await c.load();
        expect(c.phase.value, PurchasePhase.ready);
        expect(c.products.length, 4);
        expect(c.unavailableProducts, {ShopCatalog.gadgetId});
      },
    );

    test('every price comes from the store metadata, not from code', () async {
      await c.load();
      expect(c.phase.value, PurchasePhase.ready);
      for (final p in ShopCatalog.products) {
        expect(
          c.products[p.id]!.price,
          'PRICE(${p.id})',
          reason: 'displayed price must be the store\'s own string',
        );
      }
    });
  });

  group('purchase states', () {
    test('pending shows as purchasing, on the right product', () async {
      await c.load();
      store.emit(_purchase(status: StorePurchaseStatus.pending));
      await _settle();
      expect(c.phase.value, PurchasePhase.purchasing);
      expect(c.busyProductId.value, ShopCatalog.tableGoldId);
    });

    test('cancelled settles as a cancelled error, nothing granted', () async {
      await c.load();
      await c.buy(ShopCatalog.tableGoldId);
      store.emit(
        _purchase(status: StorePurchaseStatus.cancelled, pendingComplete: true),
      );
      await _settle();
      expect(c.phase.value, PurchasePhase.error);
      expect(c.lastError.value, PurchaseError.cancelled);
      expect(c.owns('table.gold'), isFalse);
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
        await c.buy(ShopCatalog.tableGoldId);
        expect(store.buys, 1);
        store.emit(_purchase());
        await _settle();
        expect(server.verifyCalls, 1);
        expect(server.verifiedTransactions, ['GPA.1234']);
        expect(c.phase.value, PurchasePhase.success);
        expect(c.owns('table.gold'), isTrue);
        expect(store.completed, hasLength(1));
      },
    );

    test('every product grants ITS entitlement and no other', () async {
      await c.load();
      var txn = 0;
      for (final p in ShopCatalog.products) {
        store.emit(_purchase(productId: p.id, txn: 'GPA.${txn++}'));
        await _settle();
        expect(c.owns(p.entitlement), isTrue, reason: p.id);
      }
      // Five purchases, five distinct entitlements, all owned at once.
      expect(server.verifyCalls, 5);
      for (final p in ShopCatalog.products) {
        expect(c.ownsProduct(p.id), isTrue);
      }
    });

    test(
      'owning one item does not own the others (no global premium)',
      () async {
        await c.load();
        store.emit(_purchase(productId: ShopCatalog.deckSpecialId));
        await _settle();
        expect(c.owns('deck.special'), isTrue);
        expect(c.owns('table.gold'), isFalse);
        expect(c.owns('table.classic'), isFalse);
        expect(c.owns('cardback.gold'), isFalse);
        expect(c.owns('gadget.01'), isFalse);
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
        expect(c.owns('table.gold'), isFalse);
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
        expect(c.owns('table.gold'), isTrue);
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
      expect(c.owns('table.gold'), isTrue);
    });

    test('verification server unreachable never grants anything', () async {
      await c.load();
      server.failVerifyWith = PurchaseError.network;
      store.emit(_purchase());
      await _settle();
      expect(c.owned, isEmpty);
      expect(c.lastError.value, PurchaseError.network);
    });

    test(
      'a product the server does not know is refused, nothing granted',
      () async {
        await c.load();
        store.emit(_purchase(productId: 'gioco101_premium', txn: 'GPA.legacy'));
        await _settle();
        expect(c.phase.value, PurchasePhase.error);
        expect(c.owned, isEmpty);
        expect(
          store.completed,
          isEmpty,
          reason: 'an unverifiable claim is never completed',
        );
      },
    );
  });

  group('restore (§17)', () {
    test('one restored transaction verifies and settles as restored', () async {
      await c.load();
      await c.restore();
      expect(store.restores, 1);
      store.emit(
        _purchase(status: StorePurchaseStatus.restored, txn: 'GPA.old'),
      );
      await _settle();
      expect(c.phase.value, PurchasePhase.restored);
      expect(c.owns('table.gold'), isTrue);
      expect(store.buys, 0, reason: 'restoring must never charge');
    });

    test('multiple owned items all restore', () async {
      await c.load();
      await c.restore();
      store.emit(
        _purchase(
          productId: ShopCatalog.tableGoldId,
          status: StorePurchaseStatus.restored,
          txn: 'GPA.a',
        ),
      );
      store.emit(
        _purchase(
          productId: ShopCatalog.cardBackGoldId,
          status: StorePurchaseStatus.restored,
          txn: 'GPA.b',
        ),
      );
      store.emit(
        _purchase(
          productId: ShopCatalog.gadgetId,
          status: StorePurchaseStatus.restored,
          txn: 'GPA.c',
        ),
      );
      await _settle();
      expect(c.owns('table.gold'), isTrue);
      expect(c.owns('cardback.gold'), isTrue);
      expect(c.owns('gadget.01'), isTrue);
      expect(c.owns('table.classic'), isFalse);
      expect(store.buys, 0);
    });

    test('all five owned restore together', () async {
      await c.load();
      await c.restore();
      var txn = 0;
      for (final p in ShopCatalog.products) {
        store.emit(
          _purchase(
            productId: p.id,
            status: StorePurchaseStatus.restored,
            txn: 'GPA.all.${txn++}',
          ),
        );
      }
      await _settle();
      for (final p in ShopCatalog.products) {
        expect(c.owns(p.entitlement), isTrue, reason: p.id);
      }
    });

    test('duplicate restore callback verifies once', () async {
      await c.load();
      await c.restore();
      store.emit(
        _purchase(status: StorePurchaseStatus.restored, txn: 'GPA.dup'),
      );
      store.emit(
        _purchase(status: StorePurchaseStatus.restored, txn: 'GPA.dup'),
      );
      await _settle();
      expect(server.verifyCalls, 1);
      expect(c.owns('table.gold'), isTrue);
    });

    test('nothing to restore settles instead of spinning forever', () async {
      await c.load();
      await c.restore();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(c.phase.value, PurchasePhase.error);
      expect(c.lastError.value, PurchaseError.nothingToRestore);
    });

    test(
      'restore finds the entitlements server-side even with no event',
      () async {
        await c.load();
        server.grantServerSide(ShopCatalog.deckSpecialId);
        server.grantServerSide(ShopCatalog.gadgetId);
        await c.restore();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(c.phase.value, PurchasePhase.restored);
        expect(c.owns('deck.special'), isTrue);
        expect(c.owns('gadget.01'), isTrue);
      },
    );

    test(
      'restore failure then retry succeeds after app-restart-like reload',
      () async {
        await c.load();
        server.grantServerSide(ShopCatalog.tableClassicId);
        server.failVerifyWith = PurchaseError.network;
        await c.restore();
        store.emit(
          _purchase(
            productId: ShopCatalog.tableClassicId,
            status: StorePurchaseStatus.restored,
            txn: 'GPA.retry',
          ),
        );
        await _settle();
        expect(c.phase.value, PurchasePhase.error);
        // Retry — the network is back.
        server.failVerifyWith = null;
        await c.restore();
        store.emit(
          _purchase(
            productId: ShopCatalog.tableClassicId,
            status: StorePurchaseStatus.restored,
            txn: 'GPA.retry',
          ),
        );
        await _settle();
        expect(c.phase.value, PurchasePhase.restored);
        expect(c.owns('table.classic'), isTrue);
      },
    );
  });

  group('entitlement is the server\'s word (§13)', () {
    test('expired entitlement does not own', () async {
      server.rows['table.gold'] = OwnedEntitlement(
        entitlement: 'table.gold',
        status: EntitlementStatus.active,
        productId: ShopCatalog.tableGoldId,
        platform: 'android',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      await c.refreshEntitlements();
      expect(c.owns('table.gold'), isFalse);
    });

    test('revoked entitlement does not own', () async {
      server.rows['deck.special'] = const OwnedEntitlement(
        entitlement: 'deck.special',
        status: EntitlementStatus.revoked,
        productId: ShopCatalog.deckSpecialId,
        platform: 'android',
      );
      await c.refreshEntitlements();
      expect(c.owns('deck.special'), isFalse);
    });

    test(
      'lifetime rows (null expiry) own forever — the non-consumable shape',
      () async {
        server.grantServerSide(ShopCatalog.cardBackGoldId);
        await c.refreshEntitlements();
        expect(c.owns('cardback.gold'), isTrue);
        final row = c.owned.single;
        expect(
          row.expiresAt,
          isNull,
          reason: 'shop cosmetics are permanent non-consumables',
        );
      },
    );

    test('no backend: nothing is granted and nothing crashes', () async {
      final offline = PurchaseController(
        store: const UnavailablePurchaseStore(),
        entitlements: const NoBackendEntitlementRepository(),
      );
      offline.onInit();
      await offline.load();
      expect(offline.phase.value, PurchasePhase.storeUnavailable);
      expect(offline.owned, isEmpty);
      offline.onClose();
    });
  });

  group('listener lifecycle (§16)', () {
    test('exactly one stream subscription, cancelled on close', () async {
      expect(store.listeners, 1);
      await c.load();
      await c.buy(ShopCatalog.tableGoldId);
      await c.restore();
      store.emit(_purchase());
      await _settle();
      expect(store.listeners, 1, reason: 'nothing may resubscribe');
      c.onClose();
      await _settle();
      expect(store.listeners, 0, reason: 'onClose must cancel');
      // tearDown will call onClose again; that must be harmless.
    });

    test('load/buy/restore cycles never add a second listener', () async {
      // The shop screen mounting and unmounting calls load() each time; a
      // sign-out/sign-in refreshes entitlements. None of that touches the
      // stream subscription, which belongs to the permanent controller.
      for (var i = 0; i < 5; i++) {
        await c.load();
        await c.refreshEntitlements();
        await c.buy(ShopCatalog.gadgetId);
        store.emit(_purchase(productId: ShopCatalog.gadgetId, txn: 'GPA.$i'));
        await _settle();
      }
      expect(store.listeners, 1);
    });

    test(
      'duplicate transaction callbacks stay idempotent across phases',
      () async {
        await c.load();
        store.emit(_purchase(txn: 'GPA.same'));
        store.emit(_purchase(txn: 'GPA.same'));
        store.emit(
          _purchase(txn: 'GPA.same', status: StorePurchaseStatus.restored),
        );
        await _settle();
        expect(server.verifyCalls, 1);
        expect(c.owns('table.gold'), isTrue);
      },
    );
  });
}
