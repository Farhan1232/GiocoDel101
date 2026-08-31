import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
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
  int dealerIndex = 0,
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
    dealerSeat: dealerIndex,
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
  int dealerIndex = 0,
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
    dealerIndex: dealerIndex,
    pendingPenalty: pendingPenalty,
    chainLength: chainLength,
    mode: mode,
    seed: seed,
    fillDeck: fillDeck,
  ),
);

/// §16 — sends the "ULTIMA CARTA" announcement when [action] is a play the
/// engine would otherwise refuse for want of one, and returns the state to
/// apply the play to.
///
/// A table always does this: a person taps the button, a bot goes through
/// [GameSession.autoPlayCard]. Rule tests that are about *something else*
/// (turn order, the Asso, the chain, scoring) use this so they exercise the
/// shipped rules rather than a weakened copy, without restating §16 in every
/// case. Tests about §16 itself build both actions explicitly and assert on
/// what happens when the announcement is missing.
GameState declaredIfNeeded(
  GameState state,
  GameAction action, {
  GameEngine engine = const GameEngine(),
}) {
  if (action is! PlayCardAction) return state;
  if (!engine.canDeclareLastCard(state, action.playerId)) return state;
  final r = engine.applyAction(
    state,
    DeclareLastCardAction(playerId: action.playerId),
  );
  return r is ActionAccepted ? r.state : state;
}
