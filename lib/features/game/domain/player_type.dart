/// How a seat at the table is driven.
///
/// §64 — a future `humanRemote` value can be added here without touching the
/// engine: the engine only ever asks "is this seat driven by a local human?"
enum PlayerType {
  humanLocal,
  bot;

  String get key => name;

  static PlayerType fromKey(String key) => PlayerType.values.firstWhere(
    (t) => t.key == key,
    orElse: () => PlayerType.bot,
  );
}

enum BotDifficulty {
  easy,
  normal,
  hard;

  String get key => name;

  static BotDifficulty fromKey(String key) => BotDifficulty.values.firstWhere(
    (d) => d.key == key,
    orElse: () => BotDifficulty.normal,
  );
}

/// §22 — flavour only. Personalities re-weight move selection and pick
/// reaction lines; they never grant access to hidden information.
enum BotPersonality {
  aggressive,
  tactical,
  risky,
  calm;

  String get key => name;

  static BotPersonality fromKey(String key) => BotPersonality.values.firstWhere(
    (p) => p.key == key,
    orElse: () => BotPersonality.calm,
  );
}
