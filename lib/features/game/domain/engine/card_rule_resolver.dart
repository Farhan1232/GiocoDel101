import '../game_card.dart';
import '../game_rules.dart';
import '../game_state.dart';

/// Decides, in isolation, whether a card may legally be played.
///
/// This is the only place §4, §6 and §7 of GAME_SPEC are expressed. The
/// engine, the UI and every bot ask this class rather than re-deriving the
/// rules.
class CardRuleResolver {
  const CardRuleResolver(this.rules);

  final GameRules rules;

  /// Whether [card] may be played onto the table described by [state].
  ///
  /// Ownership and turn order are *not* checked here — that is the engine's
  /// job. This answers only "is this card a legal response to the table?"
  bool canPlay(GameCard card, GameState state) {
    // §6 — while a +2 chain is live, only another 2 answers it…
    if (state.isPenaltyPending) {
      if (card.isDue) return rules.stackDrawTwos;
      // …or a Cavallo, if the house rule lets it block (§6a).
      if (card.isCavallo) return rules.nineCanBlock;
      return false;
    }

    // §4.3 — the Cavallo is wild and ignores the active suit.
    if (card.isCavallo && rules.wildNineCanAlwaysPlay) return true;

    // §4.1 / §4.2 — match the active suit, or match the top card's rank.
    if (card.suit == state.activeSuit) return true;
    if (card.rank == state.topCard.rank) return true;

    return false;
  }

  List<GameCard> playableCards(List<GameCard> hand, GameState state) =>
      hand.where((c) => canPlay(c, state)).toList(growable: false);

  bool hasPlayable(List<GameCard> hand, GameState state) =>
      hand.any((c) => canPlay(c, state));

  /// §7 — a Cavallo needs its suit named before play can continue, unless it
  /// was the winning card (nothing left to match against), or it blocked a
  /// chain under a house rule that says blocking does not change the suit.
  bool requiresSuitChoice(
    GameCard card, {
    required bool endedRound,
    bool blockedChain = false,
  }) {
    if (!card.isCavallo || endedRound) return false;
    if (blockedChain && !rules.nineBlockChangesSuit) return false;
    return true;
  }
}
