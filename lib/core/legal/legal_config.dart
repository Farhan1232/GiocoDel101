/// §legal — the owner details the app cannot invent.
///
/// Everything here is a build-time value the CLIENT must provide before a
/// production store submission (docs/IAP_STORE_SETUP.md lists them). The
/// legal screens render correctly with all of them empty — a missing value
/// shows an honest "not yet designated" line instead of a fabricated company
/// name, address or email. Do NOT scatter placeholder strings through
/// widgets; this is the one place they live.
///
///   flutter build appbundle --release \
///     --dart-define=LEGAL_ENTITY_NAME="..." \
///     --dart-define=LEGAL_SUPPORT_EMAIL="..." \
///     --dart-define=LEGAL_PRIVACY_EMAIL="..." \
///     --dart-define=LEGAL_COUNTRY="..." \
///     --dart-define=PRIVACY_POLICY_URL="https://..." \
///     --dart-define=TERMS_URL="https://..."
class LegalConfig {
  const LegalConfig._();

  /// The legal name of the person or company publishing the game.
  static const String entityName = String.fromEnvironment('LEGAL_ENTITY_NAME');

  /// Where players reach the publisher for support.
  static const String supportEmail = String.fromEnvironment(
    'LEGAL_SUPPORT_EMAIL',
  );

  /// Contact for privacy requests (may equal [supportEmail]).
  static const String privacyEmail = String.fromEnvironment(
    'LEGAL_PRIVACY_EMAIL',
  );

  /// Country whose law governs the terms (governing-law clause).
  static const String country = String.fromEnvironment('LEGAL_COUNTRY');

  /// Where the hosted privacy policy lives (REQUIRED by Google Play and the
  /// App Store; docs/legal/privacy-policy.html is the document to host).
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
  );

  /// Where the hosted terms live (recommended; docs/legal/terms-and-conditions.html).
  static const String termsUrl = String.fromEnvironment('TERMS_URL');

  /// Shown as "Last updated" on both legal screens.
  static const String lastUpdated = '2026-09-01';

  static bool get hasEntityName => entityName.trim().isNotEmpty;
  static bool get hasSupportEmail => supportEmail.trim().isNotEmpty;
  static bool get hasPrivacyEmail =>
      privacyEmail.trim().isNotEmpty || hasSupportEmail;
  static bool get hasCountry => country.trim().isNotEmpty;

  /// The privacy contact, falling back to the support address.
  static String get effectivePrivacyEmail =>
      privacyEmail.trim().isNotEmpty ? privacyEmail : supportEmail;
}
