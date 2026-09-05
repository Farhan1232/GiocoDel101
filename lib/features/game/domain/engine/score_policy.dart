import '../game_card.dart';
import '../game_rules.dart';

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

/// Applies GAME_SPEC §10 and §11. Every threshold and every card value comes
/// from [GameRules]; nothing here hardcodes 101 or a card value.
///
/// Confirmed by the client: penalty = printed value of each card left in
/// hand; exactly the target resets to 0; over the target eliminates. No
/// other scoring (bonuses, multipliers, online points) has been invented.
class ScorePolicy {
  const ScorePolicy(this.rules);

  final GameRules rules;

  /// Penalty points for the cards left in a hand at round end (§10).
  int handPenalty(List<GameCard> hand) =>
      hand.fold(0, (sum, card) => sum + rules.valueOf(card.rank));

  ScoreOutcome apply({required int previousScore, required int penalty}) {
    final raw = previousScore + penalty;

    // §11 — landing on exactly the target wipes the slate clean.
    if (rules.exact101ResetsToZero && raw == rules.targetScore) {
      return ScoreOutcome(
        previousScore: previousScore,
        penalty: penalty,
        newScore: 0,
        hitExact101: true,
        eliminated: false,
      );
    }

    // §11 — overshooting knocks you out, when the house rule says so.
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
