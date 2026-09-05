import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';

import '../../../core/utils/motion.dart';
import '../../game/domain/player_type.dart';
import '../domain/settings_model.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/storage/settings_storage.dart';
import '../../../app/theme/card_backs.dart';
import '../../../app/theme/deck_styles.dart';
import '../../../app/theme/table_gadgets.dart';
import '../../../app/theme/table_themes.dart';

/// Owns the player's preferences and keeps the services that depend on them
/// in step. Nothing else in the app reads settings from storage directly.
class SettingsController extends GetxController {
  SettingsController(this._storage);

  final SettingsStorage _storage;

  /// Answers "does this account own that entitlement?" for the paid
  /// cosmetics. Wired by InitialBinding to PurchaseController.owns — the
  /// server's word, never local storage. Left null (everything paid stays
  /// locked) in tests and builds without a purchase stack.
  bool Function(String entitlement)? entitlementCheck;

  final Rx<SettingsModel> _settings = const SettingsModel().obs;

  SettingsModel get settings => _settings.value;

  /// The active language, on its own observable.
  ///
  /// Deliberately *not* derived from [settings]: the app shell rebuilds the
  /// entire `GetMaterialApp` when this changes, and reading the whole settings
  /// blob there would make every unrelated preference toggle — sound, avatar,
  /// a coach mark — rebuild the whole app and the navigator with it.
  final RxString _localeCode = 'it'.obs;

  /// The active language, narrowed to one the app actually ships.
  Locale get locale => Strings.resolve(Locale(_localeCode.value));

  bool get onboardingComplete => settings.onboardingComplete;

  /// The active theme — falling back to the default if the selected one is
  /// no longer unlocked (a revoked purchase, another account signing in).
  TableTheme get theme => isThemeUnlocked(settings.themeId)
      ? TableThemes.byId(settings.themeId)
      : TableThemes.napoliNotte;

  CardBackDesign get cardBack => isCardBackUnlocked(settings.cardBackId)
      ? CardBacks.byId(settings.cardBackId)
      : CardBacks.oro;

  DeckStyle get deckStyle => isDeckStyleUnlocked(settings.deckStyleId)
      ? DeckStyles.byId(settings.deckStyleId)
      : DeckStyles.napoletane;

  /// The active gadget, or null when none is selected or owned.
  TableGadget? get gadget {
    final g = TableGadgets.byId(settings.gadgetId);
    if (g == null || !isGadgetUnlocked(g.id)) return null;
    return g;
  }

  @override
  void onInit() {
    super.onInit();
    _settings.value = _storage.load();
    _apply();
    // §43 — resume the loop for a player who left it switched on.
    if (settings.musicEnabled) {
      AudioService.instance.startMusic();
    }
  }

  /// Pushes preferences into the singletons that act on them.
  void _apply() {
    final s = settings;
    // Controllers and services read copy without a BuildContext, so the
    // resolved bundle has to be swapped here rather than in the widget tree.
    Strings.use(Locale(s.localeCode));
    // Rx dedupes, so this only notifies when the language actually changed.
    _localeCode.value = s.localeCode;
    Motion.speedFactor = s.animationSpeed.factor;
    CardStyle.deckStyleId = isDeckStyleUnlocked(s.deckStyleId)
        ? s.deckStyleId
        : DeckStyles.napoletane.id;
    Motion.reduceMotion = s.reduceMotion;
    HapticService.instance.configure(enabled: s.hapticsEnabled);
    AudioService.instance.configure(
      sound: s.soundEnabled,
      music: s.musicEnabled,
    );
  }

  Future<void> _update(SettingsModel next) async {
    _settings.value = next;
    _apply();
    await _storage.save(next);
  }

  Future<void> setSound(bool value) =>
      _update(settings.copyWith(soundEnabled: value));

  Future<void> setMusic(bool value) async {
    await _update(settings.copyWith(musicEnabled: value));
    if (value) {
      await AudioService.instance.startMusic();
    } else {
      await AudioService.instance.stopMusic();
    }
  }

  Future<void> setHaptics(bool value) =>
      _update(settings.copyWith(hapticsEnabled: value));

  Future<void> setAnimationSpeed(AnimationSpeed value) =>
      _update(settings.copyWith(animationSpeed: value));

  Future<void> setReduceMotion(bool value) =>
      _update(settings.copyWith(reduceMotion: value));

  Future<void> setHighContrast(bool value) =>
      _update(settings.copyWith(highContrast: value));

  Future<void> setLargeCards(bool value) =>
      _update(settings.copyWith(largeCardMode: value));

  Future<void> setTheme(String id) async {
    if (!isThemeUnlocked(id)) return;
    // The table dressing brings its own card back unless the player has
    // deliberately chosen another unlocked one.
    final t = TableThemes.byId(id);
    final back = isCardBackUnlocked(t.cardBackId)
        ? t.cardBackId
        : settings.cardBackId;
    await _update(settings.copyWith(themeId: id, cardBackId: back));
  }

  Future<void> setCardBack(String id) async {
    if (!isCardBackUnlocked(id)) return;
    await _update(settings.copyWith(cardBackId: id));
  }

  Future<void> setDeckStyle(String id) async {
    if (!isDeckStyleUnlocked(id)) return;
    await _update(settings.copyWith(deckStyleId: id));
  }

  /// Selects a gadget, or clears it with ''.
  Future<void> setGadget(String id) async {
    if (id.isNotEmpty && !isGadgetUnlocked(id)) return;
    await _update(settings.copyWith(gadgetId: id));
  }

  Future<void> setDefaultDifficulty(BotDifficulty value) =>
      _update(settings.copyWith(defaultDifficulty: value));

  Future<void> setPlayerName(String value) {
    final trimmed = value.trim();
    return _update(
      settings.copyWith(playerName: trimmed.isEmpty ? 'Giocatore' : trimmed),
    );
  }

  Future<void> setAvatar(String id) => _update(settings.copyWith(avatarId: id));

  /// §9 — Italian and English. Rebuilds the whole tree through [locale].
  Future<void> setLocale(Locale value) async {
    final resolved = Strings.resolve(value);
    if (resolved.languageCode == settings.localeCode) return;
    await _update(settings.copyWith(localeCode: resolved.languageCode));
  }

  Future<void> completeOnboarding() =>
      _update(settings.copyWith(onboardingComplete: true));

  /// A paid cosmetic is unlocked by its server entitlement alone; a free
  /// one by its achievement (or from the start). Ownership never comes from
  /// local storage — [entitlementCheck] asks the purchase stack, which asks
  /// the server.
  bool _ownsEntitlement(String? entitlementId) =>
      entitlementId == null || (entitlementCheck?.call(entitlementId) ?? false);

  bool isThemeUnlocked(String id) {
    final t = TableThemes.byId(id);
    if (t.entitlementId != null) return _ownsEntitlement(t.entitlementId);
    return t.unlockAchievementId == null ||
        settings.unlockedThemes.contains(id);
  }

  bool isCardBackUnlocked(String id) {
    final b = CardBacks.byId(id);
    if (b.entitlementId != null) return _ownsEntitlement(b.entitlementId);
    return b.unlockAchievementId == null ||
        settings.unlockedCardBacks.contains(id);
  }

  bool isDeckStyleUnlocked(String id) =>
      _ownsEntitlement(DeckStyles.byId(id).entitlementId);

  bool isGadgetUnlocked(String id) {
    final g = TableGadgets.byId(id);
    return g != null && _ownsEntitlement(g.entitlementId);
  }

  /// Re-applies derived state (the deck style push) after the purchase
  /// stack learns about new ownership.
  void refreshCosmetics() => _apply();

  /// §33/§41 — called when an achievement is earned.
  Future<void> unlock({String? themeId, String? cardBackId}) async {
    final themes = List<String>.of(settings.unlockedThemes);
    final backs = List<String>.of(settings.unlockedCardBacks);
    var changed = false;
    if (themeId != null && !themes.contains(themeId)) {
      themes.add(themeId);
      changed = true;
    }
    if (cardBackId != null && !backs.contains(cardBackId)) {
      backs.add(cardBackId);
      changed = true;
    }
    if (!changed) return;
    await _update(
      settings.copyWith(unlockedThemes: themes, unlockedCardBacks: backs),
    );
  }

  /// §65 — first-run coach marks are shown exactly once each.
  bool hasSeenCoachMark(String id) => settings.seenCoachMarks.contains(id);

  Future<void> markCoachMarkSeen(String id) async {
    if (hasSeenCoachMark(id)) return;
    await _update(
      settings.copyWith(seenCoachMarks: [...settings.seenCoachMarks, id]),
    );
  }
}
