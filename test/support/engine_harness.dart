import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';

GameCard c(CardSuit s, CardRank r) => GameCard(s, r);

/// Builds a fully determined table state so rule tests never depend on a
/// shuffle. Cards not placed in a hand, the discard pile or the draw pile
/// are appended to the *bottom* of the draw pile so the 40-card invariant
/// holds; the top of the draw pile is exactly [drawPile] in order.
GameState buildState({
  required List<List<GameCard>> hands,
  required GameCard top,
  CardSuit? activeSuit,
  List<GameCard> drawPile = const [],
  List<GameCard> discardBelowTop = const [],
  GameRules rules = const GameRules(),
  List<int>? scores,
  List<bool>? eliminated,
  int currentIndex = 0,
  int pendingPenalty = 0,
  int chainLength = 0,
  GameMode mode = GameMode.vsComputer,
  GameStatus status = GameStatus.awaitingAction,
  bool hasDrawnThisTurn = false,
  GameCard? drawnCard,
  int round = 1,
  int seed = 7,
  int version = 0,
  bool fillDeck = true,
}) {
  final players = <GamePlayer>[
    for (var i = 0; i < hands.length; i++)
      GamePlayer(
        id: 'p$i',
        name: 'P$i',
        type: i == 0 ? PlayerType.humanLocal : PlayerType.bot,
        avatarId: 'marco',
        difficulty: i == 0 ? null : BotDifficulty.normal,
        score: scores == null ? 0 : scores[i],
        eliminated: eliminated == null ? false : eliminated[i],
        hand: List.of(hands[i]),
      ),
  ];
  final placed = <GameCard>{
    for (final h in hands) ...h,
    ...drawPile,
    ...discardBelowTop,
    top,
  };
  final remainder = fillDeck
      ? Deck.standard.where((card) => !placed.contains(card)).toList()
      : const <GameCard>[];
  // The draw pile deals from its end, so the caller's cards go last.
  final stock = [...remainder, ...drawPile];
  return GameState(
    gameId: 'test',
    mode: mode,
    rules: rules,
    players: players,
    drawPile: stock,
    discardPile: [...discardBelowTop, top],
    activeSuit: activeSuit ?? top.suit,
    currentSeat: currentIndex,
    pendingDrawCount: pendingPenalty,
    chainLength: chainLength,
    status: status,
    hasDrawnThisTurn: hasDrawnThisTurn,
    drawnCard: drawnCard,
    round: round,
    seed: seed,
    version: version,
  );
}

/// Same as [buildState], wrapped in a stateful session.
GameSession buildEngine({
  required List<List<GameCard>> hands,
  required GameCard top,
  CardSuit? activeSuit,
  List<GameCard> drawPile = const [],
  List<GameCard> discardBelowTop = const [],
  GameRules rules = const GameRules(),
  List<int>? scores,
  List<bool>? eliminated,
  int currentIndex = 0,
  int pendingPenalty = 0,
  int chainLength = 0,
  GameMode mode = GameMode.vsComputer,
  int seed = 7,
  bool fillDeck = true,
}) => GameSession(
  buildState(
    hands: hands,
    top: top,
    activeSuit: activeSuit,
    drawPile: drawPile,
    discardBelowTop: discardBelowTop,
    rules: rules,
    scores: scores,
    eliminated: eliminated,
    currentIndex: currentIndex,
    pendingPenalty: pendingPenalty,
    chainLength: chainLength,
    mode: mode,
    seed: seed,
    fillDeck: fillDeck,
  ),
);
