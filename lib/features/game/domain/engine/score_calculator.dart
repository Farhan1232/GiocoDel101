import '../game_card.dart';
import '../game_rules_config.dart';

/// Outcome of folding one round's penalty into a player's running total.
class ScoreOutcome {
  const ScoreOutcome({
    required this.previousScore,
    required this.penalty,
    required this.newScore,
    required this.hitExact101,
    required this.eliminated,
  });

  final int previousScore;
  final int penalty;
  final int newScore;
  final bool hitExact101;
  final bool eliminated;
}

/// Applies §14, §15 and §16. Every threshold comes from [GameRulesConfig];
/// nothing here hardcodes 101.
class ScoreCalculator {
  const ScoreCalculator(this.rules);

  final GameRulesConfig rules;

  /// Penalty points for the cards left in a hand at round end (§14).
  int handPenalty(List<GameCard> hand) =>
      hand.fold(0, (sum, card) => sum + rules.valueOf(card.rank));

  ScoreOutcome apply({required int previousScore, required int penalty}) {
    final raw = previousScore + penalty;

    // §15 — landing on exactly the target wipes the slate clean.
    if (rules.exact101ResetsToZero && raw == rules.targetScore) {
      return ScoreOutcome(
        previousScore: previousScore,
        penalty: penalty,
        newScore: 0,
        hitExact101: true,
        eliminated: false,
      );
    }

    // §16 — overshooting knocks you out, when the house rule says so.
    if (raw > rules.targetScore && rules.eliminateAbove101) {
      return ScoreOutcome(
        previousScore: previousScore,
        penalty: penalty,
        newScore: raw,
        hitExact101: false,
        eliminated: true,
      );
    }

    return ScoreOutcome(
      previousScore: previousScore,
      penalty: penalty,
      newScore: raw,
      hitExact101: false,
      eliminated: false,
    );
  }
}
