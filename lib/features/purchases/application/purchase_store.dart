import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// The seam between the purchase flow and the store plugin, so the
/// controller and its tests never touch `InAppPurchase.instance` directly
/// (§: one place subscribes to the purchase stream, everything else asks).
abstract class PurchaseStore {
  Future<bool> isAvailable();

  Future<StoreProducts> queryProducts(Set<String> ids);

  /// The store's purchase updates. Subscribed to exactly once, by
  /// [PurchaseController] — never by a widget.
  Stream<List<StorePurchase>> get purchases;

  Future<void> buyNonConsumable(StoreProduct product);

  Future<void> restorePurchases();

  /// Acknowledges/finishes a delivered transaction with the store. Skipping
  /// this refunds the player on Android after three days.
  Future<void> complete(StorePurchase purchase);
}

class StoreProducts {
  const StoreProducts({required this.found, required this.notFound});

  final List<StoreProduct> found;
  final List<String> notFound;
}

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.details,
  });

  final String id;
  final String title;
  final String description;

  /// The store's own localized price string — never composed locally.
  final String price;

  /// The plugin object needed to start a purchase; null in fakes.
  final ProductDetails? details;
}

enum StorePurchaseStatus { pending, purchased, restored, cancelled, error }

class StorePurchase {
  const StorePurchase({
    required this.productId,
    required this.status,
    required this.verificationData,
    this.transactionId,
    this.pendingComplete = false,
    this.details,
  });

  final String productId;
  final StorePurchaseStatus status;

  /// What the server verifies: the purchase token on Android, the receipt /
  /// transaction on iOS. Opaque to the client.
  final String verificationData;
  final String? transactionId;
  final bool pendingComplete;

  /// The plugin object needed to complete the transaction; null in fakes.
  final PurchaseDetails? details;
}

/// The real store, behind the official `in_app_purchase` plugin
/// (flutter.dev). Only mapping lives here — no decisions.
class InAppPurchaseStore implements PurchaseStore {
  InAppPurchaseStore._(this._plugin);

  factory InAppPurchaseStore() => InAppPurchaseStore._(InAppPurchase.instance);

  final InAppPurchase _plugin;

  @override
  Future<bool> isAvailable() => _plugin.isAvailable();

  @override
  Future<StoreProducts> queryProducts(Set<String> ids) async {
    final response = await _plugin.queryProductDetails(ids);
    return StoreProducts(
      found: [
        for (final p in response.productDetails)
          StoreProduct(
            id: p.id,
            title: p.title,
            description: p.description,
            price: p.price,
            details: p,
          ),
      ],
      notFound: response.notFoundIDs,
    );
  }

  @override
  Stream<List<StorePurchase>> get purchases => _plugin.purchaseStream.map(
    (updates) => [for (final u in updates) _map(u)],
  );

  StorePurchase _map(PurchaseDetails details) => StorePurchase(
    productId: details.productID,
    status: switch (details.status) {
      PurchaseStatus.pending => StorePurchaseStatus.pending,
      PurchaseStatus.purchased => StorePurchaseStatus.purchased,
      PurchaseStatus.restored => StorePurchaseStatus.restored,
      PurchaseStatus.canceled => StorePurchaseStatus.cancelled,
      PurchaseStatus.error => StorePurchaseStatus.error,
    },
    verificationData: details.verificationData.serverVerificationData,
    transactionId: details.purchaseID,
    pendingComplete: details.pendingCompletePurchase,
    details: details,
  );

  @override
  Future<void> buyNonConsumable(StoreProduct product) async {
    final details = product.details;
    if (details == null) return;
    await _plugin.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  @override
  Future<void> restorePurchases() => _plugin.restorePurchases();

  @override
  Future<void> complete(StorePurchase purchase) async {
    final details = purchase.details;
    if (details == null) return;
    await _plugin.completePurchase(details);
  }
}

/// Tests, the web build and desktop hosts: no store, and honestly so.
class UnavailablePurchaseStore implements PurchaseStore {
  const UnavailablePurchaseStore();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<StoreProducts> queryProducts(Set<String> ids) async =>
      StoreProducts(found: const [], notFound: ids.toList());

  @override
  Stream<List<StorePurchase>> get purchases => const Stream.empty();

  @override
  Future<void> buyNonConsumable(StoreProduct product) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> complete(StorePurchase purchase) async {}
}
