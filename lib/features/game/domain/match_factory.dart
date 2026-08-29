import 'dart:math';

import 'bot_roster.dart';
import '../../rewards/domain/daily_challenge.dart';
import 'game_player.dart';
import 'game_rules_config.dart';
import 'match_state.dart';
import 'player_type.dart';
import 'engine/game_engine.dart';

/// Result of seating a table: the engine plus the ids a person controls.
class MatchSetup {
  const MatchSetup(this.engine, this.humanIds);

  final GameEngine engine;
  final List<String> humanIds;
}

/// Builds the seating for each mode (§6, §26, §40).
class MatchFactory {
  const MatchFactory._();

  static const String humanSeatId = 'p0';

  static MatchSetup vsComputer({
    required String playerName,
    required String avatarId,
    required int playerCount,
    required BotDifficulty difficulty,
    GameRulesConfig rules = const GameRulesConfig(),
    Random? random,
  }) {
    final rng = random ?? Random();
    final bots = BotRoster.pick(playerCount - 1, rng);
    final players = <GamePlayer>[
      GamePlayer(
        id: humanSeatId,
        name: playerName,
        type: PlayerType.humanLocal,
        avatarId: avatarId,
      ),
      for (var i = 0; i < bots.length; i++)
        GamePlayer(
          id: 'b${i + 1}',
          name: bots[i].name,
          type: PlayerType.bot,
          avatarId: bots[i].avatarId,
          difficulty: difficulty,
          personality: bots[i].personality,
        ),
    ];
    return MatchSetup(
      GameEngine.newMatch(
        players: players,
        mode: GameMode.vsComputer,
        rules: rules,
        random: rng,
      ),
      const [humanSeatId],
    );
  }

  /// §6/§67 — several people, one device.
  static MatchSetup passAndPlay({
    required List<String> names,
    required List<String> avatarIds,
    GameRulesConfig rules = const GameRulesConfig(),
    Random? random,
  }) {
    final rng = random ?? Random();
    final players = <GamePlayer>[
      for (var i = 0; i < names.length; i++)
        GamePlayer(
          id: 'p$i',
          name: names[i],
          type: PlayerType.humanLocal,
          avatarId: avatarIds[i % avatarIds.length],
        ),
    ];
    return MatchSetup(
      GameEngine.newMatch(
        players: players,
        mode: GameMode.passAndPlay,
        rules: rules,
        random: rng,
      ),
      players.map((p) => p.id).toList(),
    );
  }

  /// §40/§68 — seeded entirely by the date, so the deal is reproducible.
  static MatchSetup dailyChallenge({
    required DailyChallenge challenge,
    required String playerName,
    required String avatarId,
  }) {
    final rng = Random(challenge.seed);
    final bots = BotRoster.pick(challenge.playerCount - 1, rng);
    final players = <GamePlayer>[
      GamePlayer(
        id: humanSeatId,
        name: playerName,
        type: PlayerType.humanLocal,
        avatarId: avatarId,
        score: challenge.startingScore,
      ),
      for (var i = 0; i < bots.length; i++)
        GamePlayer(
          id: 'b${i + 1}',
          name: bots[i].name,
          type: PlayerType.bot,
          avatarId: bots[i].avatarId,
          difficulty: challenge.difficulty,
          personality: bots[i].personality,
          score: challenge.opponentStartingScore,
        ),
    ];
    return MatchSetup(
      GameEngine.newMatch(
        players: players,
        mode: GameMode.vsComputer,
        rules: challenge.rules,
        random: rng,
        seed: challenge.seed,
        isDailyChallenge: true,
      ),
      const [humanSeatId],
    );
  }

  /// Rebuilds the human seat list for a restored match (§49).
  static List<String> humanIdsOf(MatchState state) => state.players
      .where((p) => p.type == PlayerType.humanLocal)
      .map((p) => p.id)
      .toList();
}
