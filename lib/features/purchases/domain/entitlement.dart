/// What the server says the player owns.
///
/// The authoritative record lives in `public.user_entitlements`, written only
/// by the `verify-purchase` Edge Function after a store-side verification
/// (docs/IAP_ARCHITECTURE.md). The client can read its own row and nothing
/// else; nothing in the app ever *decides* premium locally.
class PremiumEntitlement {
  const PremiumEntitlement({
    required this.status,
    required this.productId,
    required this.platform,
    this.purchasedAt,
    this.expiresAt,
  });

  final EntitlementStatus status;
  final String productId;

  /// `android` or `ios` — where the purchase was made.
  final String platform;
  final DateTime? purchasedAt;

  /// Null for a lifetime (non-consumable) product; set for subscriptions.
  final DateTime? expiresAt;

  /// Whether the entitlement grants premium at [now]. A revoked or expired
  /// row never does; an active row with an expiry only until that instant.
  bool isActiveAt(DateTime now) {
    if (status != EntitlementStatus.active) return false;
    final until = expiresAt;
    return until == null || until.isAfter(now);
  }

  static PremiumEntitlement? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    return PremiumEntitlement(
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
