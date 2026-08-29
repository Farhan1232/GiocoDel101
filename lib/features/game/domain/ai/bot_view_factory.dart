import '../card_suit.dart';
import '../game_player.dart';
import '../engine/game_engine.dart';
import 'bot_view.dart';

/// Assembles the public view of the table for the seat currently to act.
///
/// This is the single choke point between the engine and the AI. If a bot
/// ever needs to know something new, it gets added here — in the open —
/// rather than smuggled in through a back door (§21).
class BotViewFactory {
  const BotViewFactory._();

  static BotView forCurrentPlayer(GameEngine engine) {
    final state = engine.state;
    final round = engine.round;
    final me = engine.currentPlayer;

    final opponents = <OpponentInfo>[];
    var seat = round.currentIndex;
    var away = 0;
    for (var i = 0; i < state.players.length - 1; i++) {
      seat = (seat + 1) % state.players.length;
      final p = state.players[seat];
      if (p.eliminated) continue;
      away++;
      opponents.add(_infoFor(p, round.voidSuits[p.id], away));
    }

    return BotView(
      hand: List.unmodifiable(me.hand),
      playable: List.unmodifiable(engine.playableCardsFor(me)),
      topCard: round.topCard,
      activeSuit: round.activeSuit,
      pendingPenalty: round.pendingPenalty,
      chainLength: round.chainLength,
      playedCards: List.unmodifiable(round.playedCards),
      opponents: List.unmodifiable(opponents),
      drawPileCount: round.drawPile.length,
      myScore: me.score,
      rules: state.rules,
      hasDrawnThisTurn: round.hasDrawnThisTurn,
      drawnCard: round.drawnCard,
      canDraw: engine.canDraw,
      canEndTurn: engine.canEndTurn,
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
