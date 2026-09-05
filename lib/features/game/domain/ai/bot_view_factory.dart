import '../card_suit.dart';
import '../game_player.dart';
import '../engine/game_engine.dart';
import '../game_state.dart';
import 'bot_view.dart';

/// Assembles the public view of the table for the seat currently to act.
///
/// This is the single choke point between the engine and the AI. If a bot
/// ever needs to know something new, it gets added here — in the open —
/// rather than smuggled in through a back door.
class BotViewFactory {
  const BotViewFactory._();

  static BotView forCurrentPlayer(
    GameState state, {
    GameEngine engine = const GameEngine(),
  }) {
    final me = state.currentPlayer;

    final opponents = <OpponentInfo>[];
    var seat = state.currentSeat;
    var away = 0;
    final n = state.players.length;
    for (var i = 0; i < n - 1; i++) {
      seat = (seat + state.direction.step + n) % n;
      final p = state.players[seat];
      if (p.eliminated) continue;
      away++;
      opponents.add(_infoFor(p, state.voidSuits[p.id], away));
    }

    return BotView(
      hand: List.unmodifiable(me.hand),
      playable: List.unmodifiable(engine.getPlayableCards(state, me.id)),
      topCard: state.topCard,
      activeSuit: state.activeSuit,
      pendingPenalty: state.pendingDrawCount,
      chainLength: state.chainLength,
      playedCards: List.unmodifiable(state.playedCards),
      opponents: List.unmodifiable(opponents),
      drawPileCount: state.drawPile.length,
      myScore: me.score,
      rules: state.rules,
      hasDrawnThisTurn: state.hasDrawnThisTurn,
      drawnCard: state.drawnCard,
      canDraw: engine.canDraw(state),
      canEndTurn: engine.canPass(state),
    );
  }

  static OpponentInfo _infoFor(
    GamePlayer p,
    List<String>? voids,
    int seatsAway,
  ) => OpponentInfo(
    id: p.id,
    name: p.name,
    // Only the count. Never the cards.
    cardCount: p.hand.length,
    score: p.score,
    eliminated: p.eliminated,
    voidSuits: (voids ?? const <String>[])
        .map(CardSuit.fromKey)
        .toList(growable: false),
    seatsAway: seatsAway,
  );
}
