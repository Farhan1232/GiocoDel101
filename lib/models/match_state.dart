import 'game_action.dart';
import 'game_player.dart';
import 'game_rules_config.dart';
import 'match_stats.dart';
import 'round_state.dart';

/// §6 — how the seats are filled.
enum GameMode {
  vsComputer,
  passAndPlay;

  String get key => name;

  static GameMode fromKey(String key) => GameMode.values
      .firstWhere((m) => m.key == key, orElse: () => GameMode.vsComputer);
}

/// The serialisation root for an entire match. Everything needed to restore a
/// game mid-turn lives here (§49).
class MatchState {
  MatchState({
    required this.players,
    required this.rules,
    required this.round,
    required this.mode,
    this.roundNumber = 1,
    this.matchOver = false,
    this.matchWinnerId,
    this.seed = 0,
    this.isDailyChallenge = false,
    MatchStats? stats,
    List<GameAction>? history,
  })  : stats = stats ?? MatchStats(),
        history = history ?? <GameAction>[];

  /// Seat order, fixed for the whole match. Index 0 is the local human in
  /// `vsComputer` mode.
  final List<GamePlayer> players;

  final GameRulesConfig rules;
  final GameMode mode;

  RoundState round;
  int roundNumber;
  bool matchOver;
  String? matchWinnerId;

  /// §68 — the seed a daily challenge was generated from. 0 for normal games.
  final int seed;
  final bool isDailyChallenge;

  final MatchStats stats;

  /// §36 — bounded tail of recent actions, replayed by "Rivedi ultima mano".
  final List<GameAction> history;

  static const int historyLimit = 40;

  GamePlayer get currentPlayer => players[round.currentIndex];

  Iterable<GamePlayer> get activePlayers => players.where((p) => !p.eliminated);

  GamePlayer? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  void record(GameAction action) {
    history.add(action);
    if (history.length > historyLimit) {
      history.removeRange(0, history.length - historyLimit);
    }
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'players': players.map((p) => p.toJson()).toList(),
        'rules': rules.toJson(),
        'round': round.toJson(),
        'mode': mode.key,
        'roundNumber': roundNumber,
        'matchOver': matchOver,
        'matchWinnerId': matchWinnerId,
        'seed': seed,
        'isDailyChallenge': isDailyChallenge,
        'stats': stats.toJson(),
        'history': history.map((a) => a.toJson()).toList(),
      };

  /// Throws [FormatException] on structurally invalid data so the caller can
  /// discard a corrupt save rather than booting into a broken table (§52).
  factory MatchState.fromJson(Map<String, dynamic> json) {
    final players = ((json['players'] as List?) ?? const [])
        .map((e) => GamePlayer.fromJson(e as Map<String, dynamic>))
        .toList();
    if (players.length < 2) {
      throw const FormatException('A match needs at least two seats');
    }
    final round = RoundState.fromJson(json['round'] as Map<String, dynamic>);
    if (round.currentIndex < 0 || round.currentIndex >= players.length) {
      throw const FormatException('Turn cursor points outside the table');
    }
    return MatchState(
      players: players,
      rules: GameRulesConfig.fromJson(
          (json['rules'] as Map?)?.cast<String, dynamic>() ?? const {}),
      round: round,
      mode: GameMode.fromKey(json['mode'] as String? ?? 'vsComputer'),
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 1,
      matchOver: json['matchOver'] as bool? ?? false,
      matchWinnerId: json['matchWinnerId'] as String?,
      seed: (json['seed'] as num?)?.toInt() ?? 0,
      isDailyChallenge: json['isDailyChallenge'] as bool? ?? false,
      stats: MatchStats.fromJson(
          (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {}),
      history: ((json['history'] as List?) ?? const [])
          .map((e) => GameAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
