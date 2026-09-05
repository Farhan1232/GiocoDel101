import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';

import 'engine_harness.dart';

/// One conformance case: a fully determined state, one action, and the
/// hand-written facts the resulting state must satisfy.
///
/// The `expectedState` in the JSON fixture is *generated* by the engine
/// (see `test/tools/generate_conformance_fixtures.dart`); [assertions] are
/// written by hand here and are checked against both the generated and the
/// freshly computed state, so a regression in the engine cannot silently
/// regenerate its own approval.
class ConformanceScenario {
  const ConformanceScenario({
    required this.name,
    required this.description,
    required this.state,
    required this.action,
    this.expectedFailure,
    this.assertions = const {},
    this.expectedEvents,
    this.rulesNote,
  });

  final String name;
  final String description;
  final GameState state;
  final GameAction action;

  /// Set when the action must be *rejected*; the state must then be
  /// unchanged.
  final GameFailure? expectedFailure;

  /// Key → expected value. Keys: `currentPlayerId`, `status`,
  /// `pendingDrawCount`, `chainLength`, `activeSuit`, `topCard`, `version`,
  /// `winnerId`, `roundWinnerId`, `round`, `drawPileSize`,
  /// `discardPileSize`, `handSize.<id>`, `score.<id>`, `eliminated.<id>`,
  /// `hasDrawnThisTurn`, `drawnCard`, `penaltyResolvedThisTurn`,
  /// `lastCardDeclaredBy`, `dealerSeat`, `dealerId`, `currentSeat`,
  /// `dealingOrder`, `dealingSeatOrder`.
  final Map<String, Object?> assertions;

  /// Event type names, in order, when the action is accepted.
  final List<String>? expectedEvents;

  /// Which GAME_SPEC section / provisional rule the case pins down.
  final String? rulesNote;
}

GameCard _c(CardSuit s, CardRank r) => GameCard(s, r);

final CardSuit _co = CardSuit.coppe;
final CardSuit _de = CardSuit.denari;
final CardSuit _sp = CardSuit.spade;
final CardSuit _ba = CardSuit.bastoni;

List<ConformanceScenario> conformanceScenarios() => [
  // ------------------------------------------------------------ basic play
  ConformanceScenario(
    name: 'play_same_suit',
    description: 'A card of the active suit is legal and passes the turn.',
    rulesNote: 'GAME_SPEC §4.1',
    state: buildState(
      hands: [
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [_c(_co, CardRank.re), _c(_sp, CardRank.tre), _c(_ba, CardRank.sette)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.re)),
    assertions: {
      'currentPlayerId': 'p1',
      'topCard': 'coppe_re',
      'activeSuit': 'coppe',
      'handSize.p0': 2,
      'version': 1,
      'status': 'awaitingAction',
    },
    expectedEvents: const ['CardPlayedEvent', 'TurnChangedEvent'],
  ),
  ConformanceScenario(
    name: 'play_same_rank',
    description:
        'A card matching the top rank in another suit is legal and '
        'changes the active suit.',
    rulesNote: 'GAME_SPEC §4.2',
    state: buildState(
      hands: [
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [
          _c(_ba, CardRank.cinque),
          _c(_sp, CardRank.tre),
          _c(_ba, CardRank.sette),
        ],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_ba, CardRank.cinque)),
    assertions: {
      'currentPlayerId': 'p1',
      'activeSuit': 'bastoni',
      'topCard': 'bastoni_cinque',
    },
  ),
  ConformanceScenario(
    name: 'reject_illegal_card',
    description: 'Neither suit nor rank matches: rejected, state unchanged.',
    rulesNote: 'GAME_SPEC §4',
    state: buildState(
      hands: [
        [_c(_ba, CardRank.sette)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_ba, CardRank.sette)),
    expectedFailure: GameFailure.illegalCard,
  ),
  ConformanceScenario(
    name: 'reject_wrong_turn',
    description: 'A seated player acting out of turn is refused.',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_co, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(playerId: 'p1', card: _c(_co, CardRank.tre)),
    expectedFailure: GameFailure.notPlayersTurn,
  ),
  ConformanceScenario(
    name: 'reject_card_not_owned',
    description: 'Playing a card that is not in hand is refused.',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_co, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.tre)),
    expectedFailure: GameFailure.cardNotOwned,
  ),
  ConformanceScenario(
    name: 'reject_unknown_player',
    description: 'An actor who is not seated is refused.',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_co, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: const DrawCardAction(playerId: 'ghost'),
    expectedFailure: GameFailure.invalidPlayer,
  ),
  ConformanceScenario(
    name: 'reject_stale_version',
    description: 'An action built against an older state version is refused.',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_co, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
      version: 7,
    ),
    action: PlayCardAction(
      playerId: 'p0',
      card: _c(_co, CardRank.re),
      baseVersion: 6,
    ),
    expectedFailure: GameFailure.staleState,
  ),
  ConformanceScenario(
    name: 'reject_pass_without_draw',
    description: 'A turn cannot end without playing or drawing.',
    rulesNote: 'GAME_SPEC §8 mustDrawBeforePassing',
    state: buildState(
      hands: [
        [_c(_ba, CardRank.sette)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: const PassAction(playerId: 'p0'),
    expectedFailure: GameFailure.drawRequired,
  ),
  ConformanceScenario(
    name: 'pass_after_draw',
    description: 'After drawing an unplayable card the player may pass.',
    rulesNote: 'GAME_SPEC §8',
    state: buildState(
      hands: [
        [_c(_ba, CardRank.sette), _c(_ba, CardRank.sei)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
      hasDrawnThisTurn: true,
    ),
    action: const PassAction(playerId: 'p0'),
    assertions: {'currentPlayerId': 'p1', 'hasDrawnThisTurn': false},
  ),

  // ------------------------------------------------------------------ asso
  ConformanceScenario(
    name: 'asso_two_players',
    description: 'With two players the Asso returns the turn to its player.',
    rulesNote: 'GAME_SPEC §5',
    state: buildState(
      hands: [
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [_c(_co, CardRank.asso), _c(_co, CardRank.re), _c(_ba, CardRank.sette)],
        [_c(_sp, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.asso)),
    assertions: {'currentPlayerId': 'p0', 'topCard': 'coppe_asso'},
    expectedEvents: const [
      'CardPlayedEvent',
      'TurnSkippedEvent',
      'TurnChangedEvent',
    ],
  ),
  ConformanceScenario(
    name: 'asso_three_players',
    description: 'With three players the Asso skips the next seat.',
    rulesNote: 'GAME_SPEC §5',
    state: buildState(
      hands: [
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [_c(_co, CardRank.asso), _c(_co, CardRank.re), _c(_ba, CardRank.sette)],
        [_c(_sp, CardRank.tre)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.asso)),
    assertions: {'currentPlayerId': 'p2'},
  ),
  ConformanceScenario(
    name: 'asso_four_players_wraps',
    description:
        'With four players, seat 3 playing an Asso skips seat 0 and '
        'lands on seat 1.',
    rulesNote: 'GAME_SPEC §5',
    state: buildState(
      hands: [
        [_c(_sp, CardRank.tre)],
        [_c(_de, CardRank.tre)],
        [_c(_ba, CardRank.tre)],
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [_c(_co, CardRank.asso), _c(_co, CardRank.re), _c(_ba, CardRank.sette)],
      ],
      top: _c(_co, CardRank.cinque),
      currentIndex: 3,
    ),
    action: PlayCardAction(playerId: 'p3', card: _c(_co, CardRank.asso)),
    assertions: {'currentPlayerId': 'p1'},
  ),

  // ------------------------------------------------------------------- due
  ConformanceScenario(
    name: 'due_plus_two',
    description: 'A 2 opens a +2 chain.',
    rulesNote: 'GAME_SPEC §6',
    state: buildState(
      hands: [
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [_c(_co, CardRank.due), _c(_co, CardRank.re), _c(_ba, CardRank.sette)],
        [_c(_sp, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.due)),
    assertions: {
      'currentPlayerId': 'p1',
      'pendingDrawCount': 2,
      'chainLength': 1,
    },
    expectedEvents: const [
      'CardPlayedEvent',
      'ChainGrewEvent',
      'TurnChangedEvent',
    ],
  ),
  ConformanceScenario(
    name: 'due_stack_to_four',
    description: 'Answering a 2 with a 2 raises the chain to +4.',
    rulesNote: 'GAME_SPEC §6 stackDrawTwos',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [_c(_sp, CardRank.due), _c(_sp, CardRank.tre), _c(_ba, CardRank.sette)],
      ],
      top: _c(_co, CardRank.due),
      currentIndex: 1,
      pendingPenalty: 2,
      chainLength: 1,
    ),
    action: PlayCardAction(playerId: 'p1', card: _c(_sp, CardRank.due)),
    assertions: {
      'currentPlayerId': 'p0',
      'pendingDrawCount': 4,
      'chainLength': 2,
      'activeSuit': 'spade',
    },
  ),
  ConformanceScenario(
    name: 'due_stack_to_six',
    description: 'A third 2 raises the chain to +6.',
    rulesNote: 'GAME_SPEC §6',
    state: buildState(
      hands: [
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [_c(_ba, CardRank.due), _c(_co, CardRank.re), _c(_ba, CardRank.sette)],
        [_c(_sp, CardRank.tre)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_sp, CardRank.due),
      discardBelowTop: [_c(_co, CardRank.due)],
      pendingPenalty: 4,
      chainLength: 2,
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_ba, CardRank.due)),
    assertions: {
      'currentPlayerId': 'p1',
      'pendingDrawCount': 6,
      'chainLength': 3,
    },
  ),
  ConformanceScenario(
    name: 'due_reject_non_two_under_chain',
    description:
        'While a chain is pending, a matching-suit card that is not '
        'a 2 (or a blocking Cavallo) is illegal.',
    rulesNote: 'GAME_SPEC §6 exception',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_co, CardRank.sette)],
      ],
      top: _c(_co, CardRank.due),
      currentIndex: 1,
      pendingPenalty: 2,
      chainLength: 1,
    ),
    action: PlayCardAction(playerId: 'p1', card: _c(_co, CardRank.sette)),
    expectedFailure: GameFailure.illegalCard,
  ),
  ConformanceScenario(
    name: 'due_draw_resolves_four',
    description:
        'Drawing under a +4 takes four cards and clears the chain; the '
        'seat that paid it keeps the turn for its continuation.',
    rulesNote: 'GAME_SPEC §6, §6b',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_sp, CardRank.tre)],
      ],
      top: _c(_sp, CardRank.due),
      discardBelowTop: [_c(_co, CardRank.due)],
      drawPile: [
        _c(_ba, CardRank.quattro),
        _c(_ba, CardRank.sei),
        _c(_de, CardRank.quattro),
        _c(_de, CardRank.sei),
      ],
      currentIndex: 1,
      pendingPenalty: 4,
      chainLength: 2,
    ),
    action: const DrawCardAction(playerId: 'p1'),
    assertions: {
      'currentPlayerId': 'p1',
      'pendingDrawCount': 0,
      'chainLength': 0,
      'handSize.p1': 5,
    },
    // No TurnChangedEvent: the penalty resolved, the turn did not end.
    expectedEvents: const ['CardsDrawnEvent', 'ChainResolvedEvent'],
  ),
  ConformanceScenario(
    name: 'due_reject_pass_under_chain',
    description: 'A pending chain cannot be passed; it must be drawn.',
    rulesNote: 'GAME_SPEC §6',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_sp, CardRank.tre)],
      ],
      top: _c(_co, CardRank.due),
      currentIndex: 1,
      pendingPenalty: 2,
      chainLength: 1,
    ),
    action: const PassAction(playerId: 'p1'),
    expectedFailure: GameFailure.drawRequired,
  ),

  // ------------------------------------------------------------------ nove
  ConformanceScenario(
    name: 'nove_requires_suit_selection',
    description: 'A Cavallo without a chosen suit waits for ChooseSuitAction.',
    rulesNote: 'GAME_SPEC §7',
    state: buildState(
      hands: [
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [
          _c(_sp, CardRank.cavallo),
          _c(_sp, CardRank.re),
          _c(_ba, CardRank.sette),
        ],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_sp, CardRank.cavallo)),
    assertions: {
      'currentPlayerId': 'p0',
      'status': 'awaitingSuitChoice',
      'activeSuit': 'coppe',
      'topCard': 'spade_cavallo',
    },
    expectedEvents: const ['CardPlayedEvent', 'SuitChoiceRequestedEvent'],
  ),
  ConformanceScenario(
    name: 'nove_choose_suit',
    description: 'Naming the suit sets the active suit and passes the turn.',
    rulesNote: 'GAME_SPEC §7',
    state: buildState(
      hands: [
        [_c(_sp, CardRank.re)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_sp, CardRank.cavallo),
      discardBelowTop: [_c(_co, CardRank.cinque)],
      activeSuit: _co,
      status: GameStatus.awaitingSuitChoice,
    ),
    action: const ChooseSuitAction(playerId: 'p0', suit: CardSuit.bastoni),
    assertions: {
      'currentPlayerId': 'p1',
      'status': 'awaitingAction',
      'activeSuit': 'bastoni',
    },
    expectedEvents: const ['SuitChosenEvent', 'TurnChangedEvent'],
  ),
  ConformanceScenario(
    name: 'nove_inline_suit',
    description: 'A Cavallo may carry its suit in the same action.',
    rulesNote: 'GAME_SPEC §7',
    state: buildState(
      hands: [
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [
          _c(_sp, CardRank.cavallo),
          _c(_sp, CardRank.re),
          _c(_ba, CardRank.sette),
        ],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(
      playerId: 'p0',
      card: _c(_sp, CardRank.cavallo),
      chosenSuit: CardSuit.denari,
    ),
    assertions: {
      'currentPlayerId': 'p1',
      'status': 'awaitingAction',
      'activeSuit': 'denari',
    },
  ),
  ConformanceScenario(
    name: 'nove_reject_draw_while_choosing',
    description: 'Nothing but a suit choice is legal while one is pending.',
    rulesNote: 'GAME_SPEC §7',
    state: buildState(
      hands: [
        [_c(_sp, CardRank.re)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_sp, CardRank.cavallo),
      activeSuit: _co,
      status: GameStatus.awaitingSuitChoice,
    ),
    action: const DrawCardAction(playerId: 'p0'),
    expectedFailure: GameFailure.suitSelectionRequired,
  ),
  ConformanceScenario(
    name: 'nove_reject_choose_when_not_pending',
    description: 'A suit choice with no Cavallo waiting is refused.',
    state: buildState(
      hands: [
        [_c(_sp, CardRank.re)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: const ChooseSuitAction(playerId: 'p0', suit: CardSuit.bastoni),
    expectedFailure: GameFailure.suitSelectionNotPending,
  ),
  ConformanceScenario(
    name: 'nove_blocks_chain_cancel',
    description:
        'PROVISIONAL (§6a): under nineBlockMode=cancel the Cavallo '
        'wipes the pending +4 and then asks for a suit.',
    rulesNote: 'GAME_SPEC §6a NEEDS_FINAL_RULE_CONFIRMATION',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [
          _c(_ba, CardRank.cavallo),
          _c(_sp, CardRank.tre),
          _c(_ba, CardRank.sette),
        ],
      ],
      top: _c(_sp, CardRank.due),
      discardBelowTop: [_c(_co, CardRank.due)],
      currentIndex: 1,
      pendingPenalty: 4,
      chainLength: 2,
      rules: const GameRules(nineBlockMode: NineBlockMode.cancel),
    ),
    action: PlayCardAction(playerId: 'p1', card: _c(_ba, CardRank.cavallo)),
    assertions: {
      'currentPlayerId': 'p1',
      'status': 'awaitingSuitChoice',
      'pendingDrawCount': 0,
      'chainLength': 0,
    },
    expectedEvents: const [
      'CardPlayedEvent',
      'ChainBlockedEvent',
      'SuitChoiceRequestedEvent',
    ],
  ),
  ConformanceScenario(
    name: 'nove_blocks_chain_pass_on',
    description:
        'PROVISIONAL (§6a): under nineBlockMode=passOn the Cavallo '
        'forwards the +4 unchanged; the suit is named inline here.',
    rulesNote: 'GAME_SPEC §6a NEEDS_FINAL_RULE_CONFIRMATION',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [
          _c(_ba, CardRank.cavallo),
          _c(_sp, CardRank.tre),
          _c(_ba, CardRank.sette),
        ],
      ],
      top: _c(_sp, CardRank.due),
      discardBelowTop: [_c(_co, CardRank.due)],
      currentIndex: 1,
      pendingPenalty: 4,
      chainLength: 2,
      rules: const GameRules(nineBlockMode: NineBlockMode.passOn),
    ),
    action: PlayCardAction(
      playerId: 'p1',
      card: _c(_ba, CardRank.cavallo),
      chosenSuit: CardSuit.denari,
    ),
    assertions: {
      'currentPlayerId': 'p0',
      'status': 'awaitingAction',
      'pendingDrawCount': 4,
      'chainLength': 2,
      'activeSuit': 'denari',
    },
  ),
  ConformanceScenario(
    name: 'nove_cannot_block_when_disabled',
    description:
        'Under nineBlockMode=disabled the Cavallo is illegal into a '
        'chain (Session 1 behaviour).',
    rulesNote: 'GAME_SPEC §6a',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_ba, CardRank.cavallo), _c(_sp, CardRank.tre)],
      ],
      top: _c(_co, CardRank.due),
      currentIndex: 1,
      pendingPenalty: 2,
      chainLength: 1,
      rules: const GameRules(nineBlockMode: NineBlockMode.disabled),
    ),
    action: PlayCardAction(playerId: 'p1', card: _c(_ba, CardRank.cavallo)),
    expectedFailure: GameFailure.illegalCard,
  ),

  // ------------------------------------------------------------- drawing
  ConformanceScenario(
    name: 'draw_unplayable_passes_turn',
    description: 'Drawing a card that cannot be played ends the turn.',
    rulesNote: 'GAME_SPEC §8',
    state: buildState(
      hands: [
        [_c(_ba, CardRank.sette)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
      drawPile: [_c(_sp, CardRank.re)],
    ),
    action: const DrawCardAction(playerId: 'p0'),
    assertions: {
      'currentPlayerId': 'p1',
      'handSize.p0': 2,
      'hasDrawnThisTurn': false,
    },
    expectedEvents: const ['CardsDrawnEvent', 'TurnChangedEvent'],
  ),
  ConformanceScenario(
    name: 'draw_playable_keeps_turn',
    description: 'Drawing a playable card hands control back to the player.',
    rulesNote: 'GAME_SPEC §8 playDrawnCardImmediately',
    state: buildState(
      hands: [
        [_c(_ba, CardRank.sette)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
      drawPile: [_c(_co, CardRank.re)],
    ),
    action: const DrawCardAction(playerId: 'p0'),
    assertions: {
      'currentPlayerId': 'p0',
      'hasDrawnThisTurn': true,
      'drawnCard': 'coppe_re',
      'handSize.p0': 2,
    },
  ),
  ConformanceScenario(
    name: 'draw_reshuffles_when_exhausted',
    description:
        'An empty draw pile recycles the discard pile beneath the '
        'top card; the top card stays; nothing is lost or duplicated.',
    rulesNote: 'GAME_SPEC §9',
    state: buildState(
      hands: [
        [_c(_sp, CardRank.sette)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
      discardBelowTop: [
        _c(_ba, CardRank.tre),
        _c(_ba, CardRank.quattro),
        _c(_ba, CardRank.sei),
      ],
      fillDeck: false,
    ),
    action: const DrawCardAction(playerId: 'p0'),
    assertions: {
      'topCard': 'coppe_cinque',
      'discardPileSize': 1,
      'drawPileSize': 2,
      'handSize.p0': 2,
    },
  ),
  ConformanceScenario(
    name: 'reject_second_draw_same_turn',
    description: 'Only one voluntary draw per turn.',
    rulesNote: 'GAME_SPEC §8',
    state: buildState(
      hands: [
        [_c(_ba, CardRank.sette), _c(_co, CardRank.re)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
      hasDrawnThisTurn: true,
      drawnCard: _c(_co, CardRank.re),
    ),
    action: const DrawCardAction(playerId: 'p0'),
    expectedFailure: GameFailure.drawNotAllowed,
  ),

  // ------------------------------------------------------- round & match
  ConformanceScenario(
    name: 'round_ends_and_scores',
    description:
        'Emptying the hand ends the round; others score the printed '
        'values of what they hold.',
    rulesNote: 'GAME_SPEC §10',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_de, CardRank.re), _c(_de, CardRank.sette)],
        [_c(_ba, CardRank.asso)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.re)),
    assertions: {
      'status': 'roundOver',
      'roundWinnerId': 'p0',
      'score.p0': 0,
      'score.p1': 17,
      'score.p2': 1,
      'winnerId': null,
    },
    expectedEvents: const ['CardPlayedEvent', 'RoundEndedEvent'],
  ),
  ConformanceScenario(
    name: 'round_end_exact_101_resets',
    description: 'Landing on exactly 101 resets that player to zero.',
    rulesNote: 'GAME_SPEC §11',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_de, CardRank.re), _c(_de, CardRank.asso)],
        [_c(_ba, CardRank.asso)],
      ],
      top: _c(_co, CardRank.cinque),
      scores: [0, 90, 10],
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.re)),
    assertions: {
      'status': 'roundOver',
      'score.p1': 0,
      'score.p2': 11,
      'eliminated.p1': false,
    },
  ),
  ConformanceScenario(
    name: 'round_end_over_101_eliminates_and_finishes',
    description:
        'Passing 101 eliminates; with one player left the match is '
        'finished.',
    rulesNote: 'GAME_SPEC §11–§12',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_de, CardRank.re), _c(_de, CardRank.due)],
      ],
      top: _c(_co, CardRank.cinque),
      scores: [40, 90],
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.re)),
    assertions: {
      'status': 'finished',
      'winnerId': 'p0',
      'score.p1': 102,
      'eliminated.p1': true,
    },
    expectedEvents: const [
      'CardPlayedEvent',
      'PlayerEliminatedEvent',
      'RoundEndedEvent',
      'MatchEndedEvent',
    ],
  ),
  ConformanceScenario(
    name: 'reject_action_after_finish',
    description: 'Nothing is legal once the match has a winner.',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_de, CardRank.re)],
      ],
      top: _c(_co, CardRank.cinque),
      status: GameStatus.finished,
      eliminated: [false, true],
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.re)),
    expectedFailure: GameFailure.gameFinished,
  ),
  ConformanceScenario(
    name: 'reject_play_during_round_over',
    description: 'Between rounds only StartNextRoundAction is legal.',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_de, CardRank.re)],
      ],
      top: _c(_co, CardRank.cinque),
      status: GameStatus.roundOver,
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.re)),
    expectedFailure: GameFailure.roundOver,
  ),
  ConformanceScenario(
    name: 'reject_next_round_mid_round',
    description: 'StartNextRoundAction while a round is in play is refused.',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_de, CardRank.re)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: const StartNextRoundAction(playerId: 'p0'),
    expectedFailure: GameFailure.roundNotOver,
  ),
  ConformanceScenario(
    name: 'start_next_round_previous_winner_leads',
    description:
        'The next round is dealt deterministically from the seed '
        'and the previous winner leads.',
    rulesNote: 'GAME_SPEC §3, §12 (provisional roundStarterPolicy)',
    state: buildState(
      hands: [
        [],
        [_c(_de, CardRank.re)],
        [_c(_ba, CardRank.sette)],
      ],
      top: _c(_co, CardRank.cinque),
      status: GameStatus.roundOver,
      scores: [0, 10, 7],
      currentIndex: 1,
      version: 12,
      seed: 4242,
    ).copyWith(roundWinnerId: 'p1'),
    action: const StartNextRoundAction(playerId: 'p2'),
    assertions: {
      'status': 'awaitingAction',
      'currentPlayerId': 'p1',
      'round': 2,
      'handSize.p0': 5,
      'handSize.p1': 5,
      'handSize.p2': 5,
      'discardPileSize': 1,
      'drawPileSize': 24,
      'pendingDrawCount': 0,
      'version': 13,
    },
    expectedEvents: const ['RoundStartedEvent', 'TurnChangedEvent'],
  ),
  ConformanceScenario(
    name: 'start_next_round_wide_seed',
    description:
        'A 52-bit seed (what the server draws) deals the same round on the '
        'Dart VM and in the compiled JavaScript engine.',
    rulesNote: 'SECURITY — seed width',
    state: buildState(
      hands: [
        [],
        [_c(_de, CardRank.re)],
        [_c(_ba, CardRank.sette)],
      ],
      top: _c(_co, CardRank.cinque),
      status: GameStatus.roundOver,
      scores: [0, 10, 7],
      currentIndex: 1,
      version: 12,
      seed: 4503599627370495, // 2^52 - 1
    ).copyWith(roundWinnerId: 'p1'),
    action: const StartNextRoundAction(playerId: 'p2'),
    assertions: {
      'status': 'awaitingAction',
      'currentPlayerId': 'p1',
      'round': 2,
      'handSize.p0': 5,
      'handSize.p1': 5,
      'handSize.p2': 5,
      'discardPileSize': 1,
      'drawPileSize': 24,
      'version': 13,
    },
    expectedEvents: const ['RoundStartedEvent', 'TurnChangedEvent'],
  ),
  ConformanceScenario(
    name: 'draw_reshuffles_wide_seed',
    description:
        'A reshuffle driven by a 52-bit seed orders the recycled pile '
        'identically on the Dart VM and in the compiled JavaScript engine.',
    rulesNote: 'SECURITY — seed width',
    state: buildState(
      hands: [
        [_c(_sp, CardRank.sette)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
      discardBelowTop: [
        _c(_ba, CardRank.tre),
        _c(_ba, CardRank.quattro),
        _c(_ba, CardRank.sei),
        _c(_sp, CardRank.re),
        _c(_de, CardRank.fante),
      ],
      fillDeck: false,
      seed: 3141592653589793,
      version: 7,
    ),
    action: const DrawCardAction(playerId: 'p0'),
    assertions: {
      'topCard': 'coppe_cinque',
      'discardPileSize': 1,
      'drawPileSize': 4,
      'handSize.p0': 2,
    },
  ),

  // --------------------------------------------------------------- forfeit
  ConformanceScenario(
    name: 'forfeit_off_turn_three_players',
    description:
        'A seat gives up while somebody else is to act: it is eliminated, '
        'its cards return to the bottom of the stock, the turn does not move.',
    rulesNote: 'GAME_SPEC §15 (online forfeit / abandonment)',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re), _c(_sp, CardRank.tre)],
        [_c(_de, CardRank.tre), _c(_ba, CardRank.sei)],
        [_c(_ba, CardRank.sette)],
      ],
      top: _c(_co, CardRank.cinque),
      currentIndex: 0,
      version: 4,
    ),
    action: const ForfeitAction(playerId: 'p1', baseVersion: 4),
    assertions: {
      'currentPlayerId': 'p0',
      'status': 'awaitingAction',
      'eliminated.p1': true,
      'handSize.p1': 0,
      'drawPileSize': 36,
      'version': 5,
    },
    expectedEvents: const ['PlayerForfeitedEvent', 'PlayerEliminatedEvent'],
  ),
  ConformanceScenario(
    name: 'forfeit_on_turn_clears_chain_and_advances',
    description:
        'The seat that owes a +4 gives up: the chain dies with it and play '
        'moves to the next live seat.',
    rulesNote: 'GAME_SPEC §15',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re), _c(_sp, CardRank.tre)],
        [_c(_de, CardRank.tre), _c(_ba, CardRank.sei)],
        [_c(_ba, CardRank.sette)],
      ],
      top: _c(_co, CardRank.due),
      currentIndex: 1,
      pendingPenalty: 4,
      chainLength: 2,
      version: 9,
    ),
    action: const ForfeitAction(playerId: 'p1', baseVersion: 9),
    assertions: {
      'currentPlayerId': 'p2',
      'pendingDrawCount': 0,
      'chainLength': 0,
      'eliminated.p1': true,
      'status': 'awaitingAction',
      'version': 10,
    },
    expectedEvents: const [
      'PlayerForfeitedEvent',
      'PlayerEliminatedEvent',
      'TurnChangedEvent',
    ],
  ),
  ConformanceScenario(
    name: 'forfeit_two_players_ends_match',
    description: 'With two seats, one giving up hands the match to the other.',
    rulesNote: 'GAME_SPEC §15',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re), _c(_sp, CardRank.tre)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
      scores: [40, 12],
      version: 2,
    ),
    action: const ForfeitAction(playerId: 'p0', baseVersion: 2),
    assertions: {
      'status': 'finished',
      'winnerId': 'p1',
      'eliminated.p0': true,
      'version': 3,
    },
    expectedEvents: const [
      'PlayerForfeitedEvent',
      'PlayerEliminatedEvent',
      'MatchEndedEvent',
    ],
  ),
  ConformanceScenario(
    name: 'reject_forfeit_when_already_out',
    description: 'An eliminated seat cannot forfeit again.',
    rulesNote: 'GAME_SPEC §15',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_de, CardRank.tre)],
        [],
      ],
      top: _c(_co, CardRank.cinque),
      eliminated: [false, false, true],
      scores: [10, 20, 105],
    ),
    action: const ForfeitAction(playerId: 'p2'),
    expectedFailure: GameFailure.invalidPlayer,
  ),
  // ---------------------------------------------------------------- §6b
  // A paid chain settles the penalty, not the turn. These pin the client's
  // 2026-08-31 rule change down for the compiled server engine as well.
  ConformanceScenario(
    name: 'penalty_draw_keeps_the_turn',
    description:
        'Paying a +2 leaves the same seat to act, with no TurnChangedEvent.',
    rulesNote: 'GAME_SPEC §6b',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_sp, CardRank.tre)],
      ],
      top: _c(_co, CardRank.due),
      drawPile: [_c(_ba, CardRank.quattro), _c(_co, CardRank.sei)],
      currentIndex: 1,
      pendingPenalty: 2,
      chainLength: 1,
    ),
    action: const DrawCardAction(playerId: 'p1'),
    assertions: {
      'currentPlayerId': 'p1',
      'status': 'awaitingAction',
      'pendingDrawCount': 0,
      'chainLength': 0,
      'penaltyResolvedThisTurn': true,
      'hasDrawnThisTurn': true,
      'handSize.p1': 3,
    },
    expectedEvents: const ['CardsDrawnEvent', 'ChainResolvedEvent'],
  ),
  ConformanceScenario(
    name: 'penalty_continuation_plays_a_legal_card',
    description:
        'The seat that paid the chain plays one ordinary legal card, and '
        'only then does the turn advance.',
    rulesNote: 'GAME_SPEC §6b',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        // §16 — a third card, so this case stays about its own rule:
        // from two, the play would also require an ULTIMA CARTA.
        [_c(_sp, CardRank.tre), _c(_co, CardRank.sei), _c(_ba, CardRank.sette)],
      ],
      top: _c(_co, CardRank.due),
      currentIndex: 1,
      hasDrawnThisTurn: true,
    ).copyWith(penaltyResolvedThisTurn: true),
    action: PlayCardAction(playerId: 'p1', card: _c(_co, CardRank.sei)),
    assertions: {
      'currentPlayerId': 'p0',
      'topCard': 'coppe_sei',
      'penaltyResolvedThisTurn': false,
      'handSize.p1': 2,
    },
    expectedEvents: const ['CardPlayedEvent', 'TurnChangedEvent'],
  ),
  ConformanceScenario(
    name: 'penalty_continuation_rejects_an_illegal_card',
    description:
        'The continuation is an ordinary legal play — an off-suit card is '
        'still refused.',
    rulesNote: 'GAME_SPEC §6b',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_sp, CardRank.tre), _c(_co, CardRank.sei)],
      ],
      top: _c(_co, CardRank.due),
      currentIndex: 1,
      hasDrawnThisTurn: true,
    ).copyWith(penaltyResolvedThisTurn: true),
    action: PlayCardAction(playerId: 'p1', card: _c(_sp, CardRank.tre)),
    expectedFailure: GameFailure.illegalCard,
  ),
  ConformanceScenario(
    name: 'penalty_continuation_cannot_draw_again',
    description: 'Having taken the chain, the seat may not also draw.',
    rulesNote: 'GAME_SPEC §6b, §8',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_sp, CardRank.tre)],
      ],
      top: _c(_co, CardRank.due),
      currentIndex: 1,
      hasDrawnThisTurn: true,
    ).copyWith(penaltyResolvedThisTurn: true),
    action: const DrawCardAction(playerId: 'p1'),
    expectedFailure: GameFailure.drawNotAllowed,
  ),
  ConformanceScenario(
    name: 'penalty_continuation_may_pass_with_nothing_legal',
    description:
        'With no legal continuation the seat passes out of the turn, so a '
        'paid chain can never stall the table.',
    rulesNote: 'GAME_SPEC §6b, §8',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_sp, CardRank.tre)],
      ],
      top: _c(_co, CardRank.due),
      currentIndex: 1,
      hasDrawnThisTurn: true,
    ).copyWith(penaltyResolvedThisTurn: true),
    action: const PassAction(playerId: 'p1'),
    assertions: {
      'currentPlayerId': 'p0',
      'penaltyResolvedThisTurn': false,
      'hasDrawnThisTurn': false,
    },
    expectedEvents: const ['TurnChangedEvent'],
  ),

  // --------------------------------------------------------------- §12a
  // The deal moves one seat clockwise each round, independently of the
  // closer who leads.
  ConformanceScenario(
    name: 'next_round_closer_leads_dealer_rotates',
    description:
        'Four seats: p2 closed the round so p2 leads, while the deal passes '
        'from p0 to p1. Neither is the clockwise successor of the other.',
    rulesNote: 'GAME_SPEC §12, §12a',
    state: buildState(
      hands: [
        [_c(_de, CardRank.re)],
        [_c(_ba, CardRank.sette)],
        [],
        [_c(_sp, CardRank.quattro)],
      ],
      top: _c(_co, CardRank.cinque),
      status: GameStatus.roundOver,
      scores: [8, 11, 0, 5],
      currentIndex: 2,
      dealerIndex: 0,
      version: 30,
      seed: 909090,
    ).copyWith(roundWinnerId: 'p2'),
    action: const StartNextRoundAction(playerId: 'system'),
    assertions: {
      'status': 'awaitingAction',
      'currentPlayerId': 'p2',
      'dealerId': 'p1',
      'dealerSeat': 1,
      'round': 2,
      'penaltyResolvedThisTurn': false,
      'handSize.p0': 5,
      'handSize.p3': 5,
      'version': 31,
    },
    expectedEvents: const ['RoundStartedEvent', 'TurnChangedEvent'],
  ),
  ConformanceScenario(
    name: 'next_round_dealer_wraps_round_the_table',
    description:
        'The deal wraps from the last seat back to seat 0, and the closer '
        'still leads.',
    rulesNote: 'GAME_SPEC §12a',
    state: buildState(
      hands: [
        [_c(_de, CardRank.re)],
        [],
        [_c(_ba, CardRank.sette)],
      ],
      top: _c(_co, CardRank.cinque),
      status: GameStatus.roundOver,
      scores: [12, 0, 9],
      currentIndex: 1,
      dealerIndex: 2,
      version: 44,
      seed: 31337,
    ).copyWith(roundWinnerId: 'p1'),
    action: const StartNextRoundAction(playerId: 'system'),
    assertions: {
      'currentPlayerId': 'p1',
      'dealerId': 'p0',
      'dealerSeat': 0,
      'round': 2,
    },
    expectedEvents: const ['RoundStartedEvent', 'TurnChangedEvent'],
  ),
  ConformanceScenario(
    name: 'next_round_dealer_skips_an_eliminated_seat',
    description:
        'A knocked-out seat never deals: the deal passes over it to the next '
        'live seat.',
    rulesNote: 'GAME_SPEC §12a',
    state: buildState(
      hands: [
        [_c(_de, CardRank.re)],
        [],
        [],
        [_c(_ba, CardRank.sette)],
      ],
      top: _c(_co, CardRank.cinque),
      status: GameStatus.roundOver,
      scores: [14, 0, 130, 6],
      eliminated: [false, false, true, false],
      currentIndex: 1,
      dealerIndex: 1,
      version: 51,
      seed: 5150,
    ).copyWith(roundWinnerId: 'p1'),
    action: const StartNextRoundAction(playerId: 'system'),
    assertions: {
      'currentPlayerId': 'p1',
      'dealerId': 'p3',
      'dealerSeat': 3,
      'round': 2,
    },
    expectedEvents: const ['RoundStartedEvent', 'TurnChangedEvent'],
  ),

  // ---------------------------------------------------------- ultima carta
  ConformanceScenario(
    name: 'ultima_carta_required_before_two_to_one',
    description:
        'A legal play that would leave the actor one card is refused while '
        'no ULTIMA CARTA has been declared. Nothing changes.',
    rulesNote: 'GAME_SPEC §16',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re), _c(_co, CardRank.sette)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.re)),
    expectedFailure: GameFailure.lastCardDeclarationRequired,
  ),
  ConformanceScenario(
    name: 'ultima_carta_declaration_is_recorded',
    description:
        'The declaration records the seat, plays no card, draws nothing and '
        'leaves the turn where it was.',
    rulesNote: 'GAME_SPEC §16',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re), _c(_co, CardRank.sette)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: const DeclareLastCardAction(playerId: 'p0'),
    assertions: {
      'currentPlayerId': 'p0',
      'status': 'awaitingAction',
      'lastCardDeclaredBy': 'p0',
      'handSize.p0': 2,
      'topCard': 'coppe_cinque',
      'version': 1,
    },
    expectedEvents: const ['LastCardDeclaredEvent'],
  ),
  ConformanceScenario(
    name: 'ultima_carta_then_the_play_is_accepted',
    description:
        'With the declaration standing, the same play goes through and the '
        'hand becomes exactly one card.',
    rulesNote: 'GAME_SPEC §16',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re), _c(_co, CardRank.sette)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ).copyWith(lastCardDeclaredBy: 'p0'),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.re)),
    assertions: {
      'currentPlayerId': 'p1',
      'handSize.p0': 1,
      // The turn moved on, so the declaration did not travel with it.
      'lastCardDeclaredBy': null,
      'topCard': 'coppe_re',
    },
    expectedEvents: const ['CardPlayedEvent', 'TurnChangedEvent'],
  ),
  ConformanceScenario(
    name: 'ultima_carta_rejected_with_a_full_hand',
    description:
        'Declaring means nothing with more than two cards, and is refused.',
    rulesNote: 'GAME_SPEC §16',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re), _c(_co, CardRank.sette), _c(_sp, CardRank.tre)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: const DeclareLastCardAction(playerId: 'p0'),
    expectedFailure: GameFailure.lastCardDeclarationNotAllowed,
  ),
  ConformanceScenario(
    name: 'ultima_carta_rejected_off_turn',
    description: 'A seat that is not to act cannot declare.',
    rulesNote: 'GAME_SPEC §16',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re), _c(_co, CardRank.sette)],
        [_c(_de, CardRank.tre), _c(_de, CardRank.sette)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: const DeclareLastCardAction(playerId: 'p1'),
    expectedFailure: GameFailure.notPlayersTurn,
  ),
  ConformanceScenario(
    name: 'ultima_carta_rejected_with_no_legal_play',
    description:
        'Two cards but nothing playable: the declaration would be empty '
        'talk, so it is refused.',
    rulesNote: 'GAME_SPEC §16',
    state: buildState(
      hands: [
        [_c(_sp, CardRank.tre), _c(_ba, CardRank.sette)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: const DeclareLastCardAction(playerId: 'p0'),
    expectedFailure: GameFailure.lastCardDeclarationNotAllowed,
  ),
  ConformanceScenario(
    name: 'ultima_carta_cleared_by_drawing',
    description:
        'Drawing instead of playing puts a third card in the hand and the '
        'declaration goes with it.',
    rulesNote: 'GAME_SPEC §16',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re), _c(_co, CardRank.sette)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
      // Playable, so the turn stays with p0 (§8) and the declaration is seen
      // to be cleared by the draw itself rather than by the turn changing.
      drawPile: [_c(_co, CardRank.quattro)],
    ).copyWith(lastCardDeclaredBy: 'p0'),
    action: const DrawCardAction(playerId: 'p0'),
    assertions: {
      'currentPlayerId': 'p0',
      'lastCardDeclaredBy': null,
      'handSize.p0': 3,
      'hasDrawnThisTurn': true,
      'drawnCard': 'coppe_quattro',
    },
  ),
  ConformanceScenario(
    name: 'ultima_carta_not_needed_for_the_winning_card',
    description:
        'Playing the final card (1 -> 0) wins the round and asks for no '
        'second announcement.',
    rulesNote: 'GAME_SPEC §16',
    state: buildState(
      hands: [
        [_c(_co, CardRank.re)],
        [_c(_de, CardRank.tre)],
      ],
      top: _c(_co, CardRank.cinque),
    ),
    action: PlayCardAction(playerId: 'p0', card: _c(_co, CardRank.re)),
    assertions: {
      'status': 'roundOver',
      'roundWinnerId': 'p0',
      'handSize.p0': 0,
    },
  ),

  // ------------------------------------------------- clockwise deal order
  ConformanceScenario(
    name: 'next_round_deal_goes_clockwise_from_the_dealers_left',
    description:
        'Four seats: the new deal starts one seat clockwise of the dealer '
        'and wraps, while the seat that closed the round still leads.',
    rulesNote: 'GAME_SPEC §3, §12, §12a',
    state: buildState(
      hands: [
        [],
        [_c(_de, CardRank.re)],
        [_c(_sp, CardRank.re)],
        [_c(_ba, CardRank.re)],
      ],
      top: _c(_co, CardRank.cinque),
      status: GameStatus.roundOver,
      dealerIndex: 0,
      currentIndex: 0,
      version: 30,
      seed: 90210,
    ).copyWith(roundWinnerId: 'p0'),
    action: const StartNextRoundAction(playerId: 'system'),
    assertions: {
      // §12a — the deal moved on one seat…
      'dealerSeat': 1,
      'dealerId': 'p1',
      // …so the cards go out 2, 3, 0, 1 — the dealer served last.
      'dealingSeatOrder': [2, 3, 0, 1],
      'dealingOrder': ['p2', 'p3', 'p0', 'p1'],
      // §12 — and the closer still leads, which is not the deal's business.
      'currentPlayerId': 'p0',
      'round': 2,
      'handSize.p0': 5,
      'handSize.p3': 5,
    },
    expectedEvents: const ['RoundStartedEvent', 'TurnChangedEvent'],
  ),
  ConformanceScenario(
    name: 'next_round_deal_skips_an_eliminated_seat_in_order',
    description:
        'A knocked-out seat is passed over, and the clockwise order of the '
        'seats that remain is unchanged.',
    rulesNote: 'GAME_SPEC §3, §12a',
    state: buildState(
      hands: [
        [_c(_de, CardRank.re)],
        [],
        [],
        [_c(_ba, CardRank.re)],
      ],
      top: _c(_co, CardRank.cinque),
      status: GameStatus.roundOver,
      scores: [10, 0, 140, 8],
      eliminated: [false, false, true, false],
      dealerIndex: 3,
      currentIndex: 1,
      version: 44,
      seed: 4711,
    ).copyWith(roundWinnerId: 'p1'),
    action: const StartNextRoundAction(playerId: 'system'),
    assertions: {
      // Dealer 3 -> 0; the lap from 0 is 1, (2 is out), 3, 0.
      'dealerSeat': 0,
      'dealingSeatOrder': [1, 3, 0],
      'dealingOrder': ['p1', 'p3', 'p0'],
      'currentPlayerId': 'p1',
      'handSize.p1': 5,
      'handSize.p2': 0,
      'handSize.p3': 5,
    },
  ),
];
