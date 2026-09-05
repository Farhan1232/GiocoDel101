import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';

export '../../l10n/gen/app_localizations.dart';

/// Context-free access to the localized copy (§38/§55).
///
/// Widgets could use `AppLocalizations.of(context)`, but controllers and
/// services have no context and still need to name a card or a reaction. So
/// the resolved bundle is held here and swapped whenever the locale changes.
///
/// Italian is the base language: [supported] lists it first and it is the
/// template ARB, so a key missing a translation falls back to Italian rather
/// than to English.
class Strings {
  const Strings._();

  /// Every locale the app ships. Italian first — it is the primary language.
  static const List<Locale> supported = [Locale('it'), Locale('en')];

  static const Locale fallback = Locale('it');

  static Locale _locale = fallback;
  static AppLocalizations _current = lookupAppLocalizations(fallback);

  /// The localized strings. Never null: [use] only accepts supported locales.
  static AppLocalizations get s => _current;

  static Locale get locale => _locale;

  /// Swaps the active language. Call before the first frame, or rebuild after.
  static void use(Locale locale) {
    final resolved = resolve(locale);
    _locale = resolved;
    _current = lookupAppLocalizations(resolved);
  }

  /// Narrows any locale to one the app actually ships, matching on language
  /// code alone so `en_GB` and `en_US` both land on English.
  static Locale resolve(Locale? locale) {
    if (locale == null) return fallback;
    for (final candidate in supported) {
      if (candidate.languageCode == locale.languageCode) return candidate;
    }
    return fallback;
  }
}

/// The pieces ARB cannot express directly.
extension AppLocalizationsExtras on AppLocalizations {
  /// §23 — exactly eight reaction lines. ARB has no list type, so they are
  /// eight keys joined here rather than eight call sites.
  List<String> get reactions8 => [
    reaction1,
    reaction2,
    reaction3,
    reaction4,
    reaction5,
    reaction6,
    reaction7,
    reaction8,
  ];

  /// 'it' or 'en' — used by the settings language row.
  String get languageCode => localeName;
}
