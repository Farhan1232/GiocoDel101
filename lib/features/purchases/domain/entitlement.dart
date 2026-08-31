/// What the server says the player owns.
///
/// The authoritative record lives in `public.user_entitlements` — one row per
/// owned item, keyed `(user_id, entitlement)` — written only by the
/// `verify-purchase` Edge Function after a store-side verification
/// (docs/IAP_ARCHITECTURE.md). The client can read its own rows and nothing
/// else; nothing in the app ever *decides* ownership locally.
class OwnedEntitlement {
  const OwnedEntitlement({
    required this.entitlement,
    required this.status,
    required this.productId,
    required this.platform,
    this.purchasedAt,
    this.expiresAt,
  });

  /// The entitlement key, e.g. `table.gold` (ShopCatalog maps product ↔ key).
  final String entitlement;

  final EntitlementStatus status;
  final String productId;

  /// `android` or `ios` — where the purchase was made.
  final String platform;
  final DateTime? purchasedAt;

  /// Null for a lifetime (non-consumable) product. All five shop cosmetics
  /// are non-consumable, so this stays null for them; the column exists so a
  /// future subscription would be a data change, not a schema change.
  final DateTime? expiresAt;

  /// Whether the entitlement grants its item at [now]. A revoked or expired
  /// row never does; an active row with an expiry only until that instant.
  bool isActiveAt(DateTime now) {
    if (status != EntitlementStatus.active) return false;
    final until = expiresAt;
    return until == null || until.isAfter(now);
  }

  static OwnedEntitlement? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    return OwnedEntitlement(
      entitlement: row['entitlement'] as String? ?? '',
      status: EntitlementStatus.parse(row['status'] as String?),
      productId: row['product_id'] as String? ?? '',
      platform: row['platform'] as String? ?? '',
      purchasedAt: DateTime.tryParse(row['purchased_at'] as String? ?? ''),
      expiresAt: DateTime.tryParse(row['expires_at'] as String? ?? ''),
    );
  }
}

enum EntitlementStatus {
  active,
  expired,
  revoked;

  static EntitlementStatus parse(String? value) => switch (value) {
    'active' => EntitlementStatus.active,
    'revoked' => EntitlementStatus.revoked,
    _ => EntitlementStatus.expired,
  };
}

/// Everything the purchase flow can fail with, each mapped to its own line
/// of localized copy — the UI never shows a raw server string.
enum PurchaseError {
  storeUnavailable,
  productMissing,
  cancelled,
  paymentFailed,
  verificationFailed,
  verificationUnavailable,
  alreadyOwnedElsewhere,
  nothingToRestore,
  network,
  notSignedIn,
  unknown,
}

class PurchaseException implements Exception {
  const PurchaseException(this.error, [this.detail]);

  final PurchaseError error;
  final String? detail;

  @override
  String toString() =>
      'PurchaseException(${error.name}${detail == null ? '' : ': $detail'})';
}
