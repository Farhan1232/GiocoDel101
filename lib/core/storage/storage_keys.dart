/// Every SharedPreferences key the game uses, in one place so nothing
/// collides and nothing gets orphaned.
class StorageKeys {
  const StorageKeys._();

  static const String settings = 'gd101.settings.v1';
  static const String statistics = 'gd101.statistics.v1';
  static const String savedMatch = 'gd101.match.v1';
  static const String lastRoundResult = 'gd101.lastRound.v1';
  static const String dailyChallenge = 'gd101.daily.v1';
  static const String setupPreferences = 'gd101.setup.v1';
}
