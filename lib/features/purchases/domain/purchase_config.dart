/// Store product identifiers.
///
/// ⚠ The defaults below are PLACEHOLDERS, not production identifiers: the
/// client has not yet created the products in Google Play Console / App Store
/// Connect (docs/IAP_STORE_SETUP.md is the checklist). When the real IDs
/// exist, either update the defaults here or pass them at build time:
///
///   flutter build appbundle --release \
///     --dart-define=PREMIUM_PRODUCT_ID_ANDROID=... \
///     --dart-define=PREMIUM_PRODUCT_ID_IOS=...
///
/// The provisional model is a single one-time (non-consumable) "Premium"
/// unlock — the simplest thing that matches "integration of the purchase
/// system" with no pricing brief. The server schema already carries an
/// `expires_at`, so moving to a subscription later is a data change, not a
/// schema change; what premium *unlocks* is also still the client's call
/// (docs/IAP_ARCHITECTURE.md §"Open decisions").
class PurchaseConfig {
  const PurchaseConfig._();

  static const String androidPremiumId = String.fromEnvironment(
    'PREMIUM_PRODUCT_ID_ANDROID',
    defaultValue: 'gioco101_premium',
  );

  static const String iosPremiumId = String.fromEnvironment(
    'PREMIUM_PRODUCT_ID_IOS',
    defaultValue: 'gioco101_premium',
  );
}
