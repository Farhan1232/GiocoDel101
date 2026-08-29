import '../game_card.dart';
import '../game_rules_config.dart';
import '../round_state.dart';

/// Decides, in isolation, whether a card may legally be played.
///
/// This is the only place §7, §10 and §12 are expressed. The engine, the UI
/// and every bot ask this class rather than re-deriving the rules.
class CardRuleResolver {
  const CardRuleResolver(this.rules);

  final GameRulesConfig rules;

  /// Whether [card] may be played onto the current table state.
  bool canPlay(GameCard card, RoundState round) {
    // §10 — while a Chain Storm is live, only another 2 answers it.
    if (round.isPenaltyPending) {
      return rules.stackDrawTwos && card.isTwo;
    }

    // §12 — the Cavallo is wild and ignores the active suit.
    if (card.isCavallo && rules.wildNineCanAlwaysPlay) return true;

    // §7 — match the active suit, or match the top card's rank.
    if (card.suit == round.activeSuit) return true;
    if (card.rank == round.topCard.rank) return true;

    return false;
  }

  List<GameCard> playableCards(List<GameCard> hand, RoundState round) =>
      hand.where((c) => canPlay(c, round)).toList(growable: false);

  bool hasPlayable(List<GameCard> hand, RoundState round) =>
      hand.any((c) => canPlay(c, round));

  /// §12 — a Cavallo needs its suit named before play can continue, unless it
  /// was the winning card (nothing left to match against).
  bool requiresSuitChoice(GameCard card, {required bool endedRound}) =>
      card.isCavallo && !endedRound;
}
