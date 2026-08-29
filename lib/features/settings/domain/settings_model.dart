import '../../game/domain/player_type.dart';

/// §30 — how quickly cards move.
enum AnimationSpeed {
  normal(1.0),
  fast(0.6);

  const AnimationSpeed(this.factor);

  /// Multiplier applied to every animation duration in the game.
  final double factor;

  String get key => name;

  static AnimationSpeed fromKey(String key) => AnimationSpeed.values
      .firstWhere((s) => s.key == key, orElse: () => AnimationSpeed.normal);
}

/// Everything on the Settings tab (§39), persisted as one JSON blob.
class SettingsModel {
  const SettingsModel({
    this.soundEnabled = true,
    this.musicEnabled = false,
    this.hapticsEnabled = true,
    this.animationSpeed = AnimationSpeed.normal,
    this.reduceMotion = false,
    this.highContrast = false,
    this.largeCardMode = false,
    this.themeId = 'napoli_notte',
    this.cardBackId = 'oro',
    this.defaultDifficulty = BotDifficulty.normal,
    this.playerName = 'Giocatore',
    this.avatarId = 'lucia',
    this.unlockedThemes = const ['napoli_notte'],
    this.unlockedCardBacks = const ['oro'],
    this.seenCoachMarks = const [],
  });

  final bool soundEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;
  final AnimationSpeed animationSpeed;
  final bool reduceMotion;
  final bool highContrast;
  final bool largeCardMode;
  final String themeId;
  final String cardBackId;
  final BotDifficulty defaultDifficulty;
  final String playerName;
  final String avatarId;

  /// §33 — themes are earned locally, never bought.
  final List<String> unlockedThemes;
  final List<String> unlockedCardBacks;

  /// §65 — ids of the first-run tips already shown.
  final List<String> seenCoachMarks;

  SettingsModel copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
    AnimationSpeed? animationSpeed,
    bool? reduceMotion,
    bool? highContrast,
    bool? largeCardMode,
    String? themeId,
    String? cardBackId,
    BotDifficulty? defaultDifficulty,
    String? playerName,
    String? avatarId,
    List<String>? unlockedThemes,
    List<String>? unlockedCardBacks,
    List<String>? seenCoachMarks,
  }) =>
      SettingsModel(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        musicEnabled: musicEnabled ?? this.musicEnabled,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        animationSpeed: animationSpeed ?? this.animationSpeed,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        highContrast: highContrast ?? this.highContrast,
        largeCardMode: largeCardMode ?? this.largeCardMode,
        themeId: themeId ?? this.themeId,
        cardBackId: cardBackId ?? this.cardBackId,
        defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
        playerName: playerName ?? this.playerName,
        avatarId: avatarId ?? this.avatarId,
        unlockedThemes: unlockedThemes ?? this.unlockedThemes,
        unlockedCardBacks: unlockedCardBacks ?? this.unlockedCardBacks,
        seenCoachMarks: seenCoachMarks ?? this.seenCoachMarks,
      );

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'musicEnabled': musicEnabled,
        'hapticsEnabled': hapticsEnabled,
        'animationSpeed': animationSpeed.key,
        'reduceMotion': reduceMotion,
        'highContrast': highContrast,
        'largeCardMode': largeCardMode,
        'themeId': themeId,
        'cardBackId': cardBackId,
        'defaultDifficulty': defaultDifficulty.key,
        'playerName': playerName,
        'avatarId': avatarId,
        'unlockedThemes': unlockedThemes,
        'unlockedCardBacks': unlockedCardBacks,
        'seenCoachMarks': seenCoachMarks,
      };

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    const fallback = SettingsModel();
    List<String> strings(Object? raw, List<String> or) {
      if (raw is! List) return or;
      final list = raw.whereType<String>().toList();
      return list.isEmpty ? or : list;
    }

    return SettingsModel(
      soundEnabled: json['soundEnabled'] as bool? ?? fallback.soundEnabled,
      musicEnabled: json['musicEnabled'] as bool? ?? fallback.musicEnabled,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? fallback.hapticsEnabled,
      animationSpeed:
          AnimationSpeed.fromKey(json['animationSpeed'] as String? ?? 'normal'),
      reduceMotion: json['reduceMotion'] as bool? ?? fallback.reduceMotion,
      highContrast: json['highContrast'] as bool? ?? fallback.highContrast,
      largeCardMode: json['largeCardMode'] as bool? ?? fallback.largeCardMode,
      themeId: json['themeId'] as String? ?? fallback.themeId,
      cardBackId: json['cardBackId'] as String? ?? fallback.cardBackId,
      defaultDifficulty:
          BotDifficulty.fromKey(json['defaultDifficulty'] as String? ?? 'normal'),
      playerName: json['playerName'] as String? ?? fallback.playerName,
      avatarId: json['avatarId'] as String? ?? fallback.avatarId,
      unlockedThemes:
          strings(json['unlockedThemes'], fallback.unlockedThemes),
      unlockedCardBacks:
          strings(json['unlockedCardBacks'], fallback.unlockedCardBacks),
      seenCoachMarks: (json['seenCoachMarks'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }
}
