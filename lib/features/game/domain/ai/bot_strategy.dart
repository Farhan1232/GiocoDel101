import 'dart:math';

import '../card_suit.dart';
import '../player_type.dart';
import 'bot_decision.dart';
import 'bot_view.dart';

/// Tunable knobs behind every weighted bot. Personalities scale these; they
/// never unlock information (§22).
class BotWeights {
  const BotWeights({
    this.shedHigh = 1.0,
    this.suitControl = 1.0,
    this.action = 1.0,
    this.holdCavallo = 1.0,
    this.randomness = 0.0,
    this.voidExploit = 1.0,
  });

  final double shedHigh;
  final double suitControl;
  final double action;
  final double holdCavallo;
  final double randomness;
  final double voidExploit;

  BotWeights scaledBy(BotWeights other) => BotWeights(
        shedHigh: shedHigh * other.shedHigh,
        suitControl: suitControl * other.suitControl,
        action: action * other.action,
        holdCavallo: holdCavallo * other.holdCavallo,
        randomness: randomness + other.randomness,
        voidExploit: voidExploit * other.voidExploit,
      );

  /// §22 — Marco plays hard, Sofia hoards, Luca gambles, Giulia balances.
  static BotWeights forPersonality(BotPersonality? p) {
    switch (p) {
      case BotPersonality.aggressive:
        return const BotWeights(
            action: 1.6, holdCavallo: 0.6, shedHigh: 1.15, randomness: 0.05);
      case BotPersonality.tactical:
        return const BotWeights(
            action: 0.9, holdCavallo: 1.5, suitControl: 1.25, shedHigh: 1.2);
      case BotPersonality.risky:
        return const BotWeights(
            action: 1.25, holdCavallo: 0.8, randomness: 0.35);
      case BotPersonality.calm:
      case null:
        return const BotWeights(suitControl: 1.3, shedHigh: 1.05);
    }
  }
}

/// A bot brain. Implementations receive only [BotView] — the public table.
abstract class BotStrategy {
  const BotStrategy(this.personality, this.random);

  final BotPersonality? personality;
  final Random random;

  BotDifficulty get difficulty;

  /// Chooses this turn's move.
  BotDecision decide(BotView view);

  /// §12 — names the suit after playing a Cavallo.
  CardSuit chooseSuit(BotView view);

  /// Shared fallback: with nothing playable, draw; with nothing left to draw,
  /// end the turn. Never returns an illegal action.
  BotDecision? fallback(BotView view) {
    if (view.playable.isEmpty) {
      if (view.canDraw && !view.hasDrawnThisTurn) return const BotDecision.draw();
      if (view.canDraw && view.pendingPenalty > 0) return const BotDecision.draw();
      if (view.canEndTurn) return const BotDecision.endTurn();
      return const BotDecision.draw();
    }
    return null;
  }
}
