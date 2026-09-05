import 'dart:math';

import 'bot_roster.dart';
import '../../rewards/domain/daily_challenge.dart';
import 'engine/game_session.dart';
import 'game_player.dart';
import 'game_rules.dart';
import 'game_state.dart';
import 'player_type.dart';

/// Result of seating a table: the session plus the ids a person controls.
class MatchSetup {
  const MatchSetup(this.session, this.humanIds);

  final GameSession session;
  final List<String> humanIds;
}

/// Builds the seating for each mode. All dealing goes through
/// [GameSession.newMatch] → `GameEngine.createGame`; nothing here touches a
/// card.
class MatchFactory {
  const MatchFactory._();

  static const String humanSeatId = 'p0';

  static String _newGameId(Random rng) =>
      'local-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-'
      '${rng.nextInt(1 << 30).toRadixString(36)}';

  static MatchSetup vsComputer({
    required String playerName,
    required String avatarId,
    required int playerCount,
    required BotDifficulty difficulty,
    GameRules rules = const GameRules(),
    Random? random,
    int? seed,
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
      GameSession.newMatch(
        gameId: _newGameId(rng),
        players: players,
        mode: GameMode.vsComputer,
        rules: rules,
        seed: seed ?? rng.nextInt(1 << 31),
      ),
      const [humanSeatId],
    );
  }

  /// Several people, one device.
  static MatchSetup passAndPlay({
    required List<String> names,
    required List<String> avatarIds,
    GameRules rules = const GameRules(),
    Random? random,
    int? seed,
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
      GameSession.newMatch(
        gameId: _newGameId(rng),
        players: players,
        mode: GameMode.passAndPlay,
        rules: rules,
        seed: seed ?? rng.nextInt(1 << 31),
      ),
      players.map((p) => p.id).toList(),
    );
  }

  /// Seeded entirely by the date, so the deal is reproducible.
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
      GameSession.newMatch(
        gameId: 'daily-${challenge.seed}',
        players: players,
        mode: GameMode.vsComputer,
        rules: challenge.rules,
        seed: challenge.seed,
        isDailyChallenge: true,
      ),
      const [humanSeatId],
    );
  }

  /// Rebuilds the human seat list for a restored match.
  static List<String> humanIdsOf(GameState state) => state.players
      .where((p) => p.type == PlayerType.humanLocal)
      .map((p) => p.id)
      .toList();
}
