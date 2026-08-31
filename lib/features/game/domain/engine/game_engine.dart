import 'dart:math';

import '../card_suit.dart';
import '../game_action.dart';
import '../game_card.dart';
import '../game_player.dart';
import '../game_rules.dart';
import '../game_state.dart';
import '../history_entry.dart';
import '../round_result.dart';
import 'card_rule_resolver.dart';
import 'deck_factory.dart';
import 'game_event.dart';
import 'game_failure.dart';
import 'score_policy.dart';

/// Source of shuffles. The default derives every shuffle from the state's
/// own seed and version, which makes `applyAction(state, action)` a pure
/// function: the same input always yields the same output, on any device
/// and on the server. Tests may inject their own.
typedef RandomSource = Random Function(GameState state);

/// The seed may carry up to 52 bits. A 31-bit seed is not enough online: a
/// modified client holding this very engine could enumerate 2^31 deals until
/// one reproduced its own hand and then know every card in the match. The
/// Dart VM has 64-bit integers but dart2js truncates every bitwise operator
/// to 32 bits, and the authoritative server runs this engine compiled to
/// JavaScript — so the high part of the seed is folded in with arithmetic
/// only, which is exact below 2^53 on both runtimes, and the XOR sees two
/// operands below 2^31. Seeds below 2^31 mix exactly as they always did.
Random _seededRandom(GameState state) {
  final low = state.seed % 0x80000000;
  final high = state.seed ~/ 0x80000000;
  final mixed = low ^ ((state.version * 0x9E3779B1) & 0x7FFFFFFF);
  return Random(mixed + high * 0x80000000);
}

/// The rules of Gioco del 101, expressed once, as pure functions over
/// [GameState].
///
/// The engine owns nothing. It is handed a state and an action and returns
/// either a new state plus the events that explain it, or a typed
/// [GameFailure]. It has no clock, no I/O, no Flutter import and no
/// knowledge of who is human: exactly the same code will run offline today
/// and inside the authoritative server tomorrow.
class GameEngine {
  // ignore: prefer_initializing_formals
  const GameEngine({RandomSource random = _seededRandom}) : _random = random;

  final RandomSource _random;

  // ================================================================ creation

  /// Deals a brand new match.
  ///
  /// Throws [GameSetupException] for an unplayable table: fewer than
  /// `rules.minPlayers` or more than `rules.maxPlayers` seats (hard-capped to
  /// 2–4 by the deck), a duplicate player id, or a hand size the deck cannot
  /// cover.
  GameState createGame({
    required String gameId,
    required List<GamePlayer> players,
    required GameMode mode,
    required int seed,
    GameRules rules = const GameRules(),
    int startingSeat = 0,
    bool isDailyChallenge = false,
    int? now,
  }) {
    final minPlayers = max(2, rules.minPlayers);
    final maxPlayers = min(4, rules.maxPlayers);
    if (players.length < minPlayers || players.length > maxPlayers) {
      throw GameSetupException(
        GameFailure.invalidPlayerCount,
        'Need $minPlayers–$maxPlayers players, got ${players.length}',
      );
    }
    final ids = <String>{};
    for (final p in players) {
      if (p.id.isEmpty || !ids.add(p.id)) {
        throw GameSetupException(
          GameFailure.duplicatePlayer,
          'Player id "${p.id}" is empty or duplicated',
        );
      }
    }
    if (rules.startingHandSize < 1 ||
        rules.startingHandSize * players.length + 1 > Deck.size) {
      throw const GameSetupException(
        GameFailure.invalidRules,
        'startingHandSize does not fit the 40-card deck',
      );
    }
    if (rules.drawTwoPenalty < 0 || rules.targetScore < 1) {
      throw const GameSetupException(
        GameFailure.invalidRules,
        'drawTwoPenalty must be >= 0 and targetScore >= 1',
      );
    }
    if (startingSeat < 0 || startingSeat >= players.length) {
      throw GameSetupException(
        GameFailure.invalidPlayerCount,
        'startingSeat $startingSeat is not a seat',
      );
    }

    final blank = GameState(
      gameId: gameId,
      mode: mode,
      rules: rules,
      players: [for (final p in players) p.copyWith(hand: const [])],
      drawPile: const [],
      discardPile: [Deck.standard.first], // placeholder, replaced by _deal
      activeSuit: CardSuit.denari,
      currentSeat: startingSeat,
      // §12a — the opening seat deals the opening round; from the next round
      // on the deal moves one seat clockwise, so everybody deals in turn.
      dealerSeat: startingSeat,
      direction: rules.initialDirection,
      seed: seed,
      isDailyChallenge: isDailyChallenge,
    );
    var state = _deal(blank, startingSeat: startingSeat);
    state = _stampClock(state, previous: null, now: now);
    _assertInvariants(state, expectedCards: Deck.size);
    return state;
  }

  // ================================================================= queries

  CardRuleResolver resolverFor(GameState state) =>
      CardRuleResolver(state.rules);

  /// Cards [playerId] could legally play right now. Empty when it is not
  /// their turn, a suit is pending, or the round is over.
  List<GameCard> getPlayableCards(GameState state, String playerId) {
    if (state.status != GameStatus.awaitingAction) return const [];
    if (state.currentPlayerId != playerId) return const [];
    final player = state.playerById(playerId);
    if (player == null || player.eliminated) return const [];
    final resolver = resolverFor(state);
    final hand = state.restrictsPlayToDrawnCard
        ? (state.drawnCard == null ? const <GameCard>[] : [state.drawnCard!])
        : player.hand;
    return resolver.playableCards(hand, state);
  }

  /// Whether the current player may play [card] (legality only — ownership
  /// is checked by [validateAction]).
  bool canPlay(GameState state, GameCard card) =>
      state.status == GameStatus.awaitingAction &&
      resolverFor(state).canPlay(card, state) &&
      (!state.restrictsPlayToDrawnCard || state.drawnCard == card);

  bool canDraw(GameState state) =>
      validateAction(state, DrawCardAction(playerId: state.currentPlayerId)) ==
      null;

  bool canPass(GameState state) =>
      validateAction(state, PassAction(playerId: state.currentPlayerId)) ==
      null;

  /// §16 — whether [playerId] may declare "ULTIMA CARTA" right now.
  ///
  /// True only when the declaration would mean something: the rule is on,
  /// the match and round are live, it is this seat's turn, nothing else is
  /// pending, the seat holds exactly two cards, at least one of them can
  /// legally be played (so a play really can take the hand down to one),
  /// and the seat has not already declared this turn.
  ///
  /// This is the single predicate the button, the bots and [validateAction]
  /// all read, so the button can never be enabled for a declaration the
  /// engine would refuse, nor disabled for one it would accept.
  bool canDeclareLastCard(GameState state, String playerId) {
    if (!state.rules.requireLastCardDeclaration) return false;
    if (state.isFinished || state.isRoundOver) return false;
    if (state.status != GameStatus.awaitingAction) return false;
    if (state.currentPlayerId != playerId) return false;
    final player = state.playerById(playerId);
    if (player == null || player.eliminated) return false;
    if (player.hand.length != lastCardThreshold) return false;
    if (state.hasDeclaredLastCard(playerId)) return false;
    return getPlayableCards(state, playerId).isNotEmpty;
  }

  /// §16 — whether playing [card] would be refused for want of a
  /// declaration. Pure legality of the *announcement*, not of the card.
  bool requiresLastCardDeclaration(GameState state, String playerId) {
    if (!state.rules.requireLastCardDeclaration) return false;
    final player = state.playerById(playerId);
    if (player == null) return false;
    // Only the 2 -> 1 step. Playing the final card (1 -> 0) wins the round
    // and needs no second announcement.
    return player.hand.length == lastCardThreshold &&
        !state.hasDeclaredLastCard(playerId);
  }

  /// §16 — the hand size from which a play makes a one-card player.
  static const int lastCardThreshold = 2;

  /// True when the current player has no legal answer to a live chain and
  /// simply has to take the cards (§6).
  bool mustTakePenalty(GameState state) =>
      state.status == GameStatus.awaitingAction &&
      state.isPenaltyPending &&
      getPlayableCards(state, state.currentPlayerId).isEmpty;

  // ============================================================== validation

  /// Returns null when [action] may be applied to [state], otherwise the
  /// reason it may not. Never throws.
  GameFailure? validateAction(GameState state, GameAction action) {
    if (state.isFinished) return GameFailure.gameFinished;
    if (state.discardPile.isEmpty ||
        state.currentSeat < 0 ||
        state.currentSeat >= state.players.length) {
      return GameFailure.invalidState;
    }
    if (action.baseVersion != null && action.baseVersion != state.version) {
      return GameFailure.staleState;
    }

    final actor = state.playerById(action.playerId);
    if (action is StartNextRoundAction) {
      // Any seated player (or the host, id `system`) may deal the next round.
      if (actor == null && action.playerId != systemActorId) {
        return GameFailure.invalidPlayer;
      }
      if (state.status != GameStatus.roundOver) return GameFailure.roundNotOver;
      return null;
    }

    if (actor == null || actor.eliminated) return GameFailure.invalidPlayer;
    if (action is ForfeitAction) {
      // A seat may give up at any moment of a live match: on or off turn,
      // between rounds, while a suit is pending. Only "already out" and
      // "already finished" (checked above) refuse it.
      return null;
    }
    if (state.status == GameStatus.roundOver) return GameFailure.roundOver;
    if (actor.id != state.currentPlayerId) return GameFailure.notPlayersTurn;

    final awaitingSuit = state.status == GameStatus.awaitingSuitChoice;
    final rules = state.rules;
    final resolver = resolverFor(state);

    switch (action) {
      case PlayCardAction(:final card):
        if (awaitingSuit) return GameFailure.suitSelectionRequired;
        if (!actor.hand.contains(card)) return GameFailure.cardNotOwned;
        if (!resolver.canPlay(card, state)) return GameFailure.illegalCard;
        if (state.restrictsPlayToDrawnCard && state.drawnCard != card) {
          return GameFailure.illegalCard;
        }
        // §16 — last, so an illegal card is still reported as illegal rather
        // than blamed on a missing announcement. The play is refused whole:
        // no card leaves the hand and the turn does not move.
        if (requiresLastCardDeclaration(state, actor.id)) {
          return GameFailure.lastCardDeclarationRequired;
        }
        return null;

      case DrawCardAction():
        if (awaitingSuit) return GameFailure.suitSelectionRequired;
        if (state.isPenaltyPending) return null;
        // §6b — a paid chain leaves `hasDrawnThisTurn` set, so the seat that
        // stayed on cannot keep drawing; its continuation is a play or a pass.
        if (state.hasDrawnThisTurn) return GameFailure.drawNotAllowed;
        if (!rules.allowVoluntaryDraw &&
            resolver.hasPlayable(actor.hand, state)) {
          return GameFailure.drawNotAllowed;
        }
        return null;

      case ChooseSuitAction():
        if (!awaitingSuit) return GameFailure.suitSelectionNotPending;
        return null;

      case PassAction():
        if (awaitingSuit) return GameFailure.suitSelectionRequired;
        if (state.isPenaltyPending) return GameFailure.drawRequired;
        if (rules.mustDrawBeforePassing && !state.hasDrawnThisTurn) {
          return GameFailure.drawRequired;
        }
        return null;

      case DeclareLastCardAction():
        if (awaitingSuit) return GameFailure.suitSelectionRequired;
        // One predicate for the button and the rule, so they cannot drift.
        if (!canDeclareLastCard(state, actor.id)) {
          return GameFailure.lastCardDeclarationNotAllowed;
        }
        return null;

      case StartNextRoundAction():
      case ForfeitAction():
        return null; // handled above
    }
  }

  /// Actor id a host or server may use for [StartNextRoundAction].
  static const String systemActorId = 'system';

  // ============================================================= application

  /// Validates and applies [action]. On success the returned state has
  /// `version == state.version + 1` and `lastAction == action`.
  ///
  /// [now] (epoch ms) is optional. When given, a turn change stamps
  /// `turnStartedAt` and, if the rules set a time limit, `turnDeadlineAt`.
  /// The engine never reads a clock itself.
  ActionResult applyAction(GameState state, GameAction action, {int? now}) {
    final failure = validateAction(state, action);
    if (failure != null) return ActionRejected(failure);

    final events = <GameEvent>[];
    var next = switch (action) {
      PlayCardAction() => _play(state, action, events),
      DrawCardAction() => _draw(state, action, events),
      ChooseSuitAction() => _chooseSuit(state, action, events),
      PassAction() => _advanceTurn(state, 1, events),
      DeclareLastCardAction() => _declareLastCard(state, action, events),
      StartNextRoundAction() => _startNextRound(state, events),
      ForfeitAction() => _forfeit(state, action, events),
    };
    next = next.copyWith(version: state.version + 1, lastAction: action);
    next = _stampClock(next, previous: state, now: now);
    _assertInvariants(next, expectedCards: state.totalCards);
    return ActionAccepted(next, List.unmodifiable(events));
  }

  // ------------------------------------------------------------------ play

  GameState _play(GameState s, PlayCardAction a, List<GameEvent> events) {
    final player = s.currentPlayer;
    final card = a.card;
    final rules = s.rules;

    final hand = List.of(player.hand)..remove(card);
    final voids = _withoutVoid(s.voidSuits, player.id, card.suit);

    var next = s
        .withPlayer(player.copyWith(hand: hand))
        .copyWith(
          discardPile: [...s.discardPile, card],
          playedCards: [...s.playedCards, card],
          voidSuits: voids,
          clearDrawnCard: true,
          // A Cavallo keeps the previous active suit until its owner names one.
          activeSuit: card.isCavallo ? s.activeSuit : card.suit,
          stats: s.stats
              .copyWith(cardsPlayed: s.stats.cardsPlayed + 1)
              .withSuitPlayed(card.suit),
        )
        .withHistory(
          HistoryEntry(
            type: HistoryEntryType.play,
            playerId: player.id,
            card: card,
          ),
        );
    events.add(CardPlayedEvent(player.id, card));

    final emptied = hand.isEmpty;
    final wasPenaltyPending = s.isPenaltyPending;
    var blockedChain = false;

    if (card.isAsso) {
      next = next.copyWith(
        stats: next.stats.copyWith(acesPlayed: next.stats.acesPlayed + 1),
      );
    } else if (card.isDue) {
      final pending = next.pendingDrawCount + rules.drawTwoPenalty;
      final chain = next.chainLength + 1;
      next = next.copyWith(
        pendingDrawCount: pending,
        chainLength: chain,
        stats: next.stats.copyWith(
          twosPlayed: next.stats.twosPlayed + 1,
          longestChain: max(next.stats.longestChain, chain),
        ),
      );
      events.add(ChainGrewEvent(pending, chain));
    } else if (card.isCavallo && wasPenaltyPending) {
      // §6a — the 9 blocks the chain. Provisional; see GameRules.nineBlockMode.
      blockedChain = true;
      final cancelled = rules.nineBlockMode == NineBlockMode.cancel;
      events.add(
        ChainBlockedEvent(
          player.id,
          next.pendingDrawCount,
          next.chainLength,
          cancelled: cancelled,
        ),
      );
      next = next.withHistory(
        HistoryEntry(
          type: HistoryEntryType.chainBlocked,
          playerId: player.id,
          card: card,
          count: next.pendingDrawCount,
        ),
      );
      if (cancelled) {
        next = next.copyWith(pendingDrawCount: 0, chainLength: 0);
      }
    }

    if (emptied) {
      return _finishRound(next, player.id, winningCard: card, events: events);
    }

    if (card.isCavallo) {
      final needsSuit = resolverFor(
        next,
      ).requiresSuitChoice(card, endedRound: false, blockedChain: blockedChain);
      if (!needsSuit) return _advanceTurn(next, 1, events);
      if (a.chosenSuit != null) {
        return _applySuitChoice(next, player.id, a.chosenSuit!, events);
      }
      events.add(SuitChoiceRequestedEvent(player.id, card));
      return next.copyWith(status: GameStatus.awaitingSuitChoice);
    }

    if (card.isAsso) {
      // §5 — the next player loses their turn. With two players the turn
      // comes straight back to whoever played the Asso.
      final skippedSeat = _seatAfter(next, next.currentSeat, 1);
      final skipped = next.players[skippedSeat];
      next = next.withHistory(
        HistoryEntry(type: HistoryEntryType.skip, playerId: skipped.id),
      );
      events.add(TurnSkippedEvent(skipped.id));
      return _advanceTurn(next, 2, events);
    }

    return _advanceTurn(next, 1, events);
  }

  // -------------------------------------------------------- ultima carta

  /// §16 — records the announcement. Nothing else moves: no card is played,
  /// no card is drawn, the turn does not advance and the hand is untouched.
  /// The seat is simply now allowed to make the play that leaves it one card.
  GameState _declareLastCard(
    GameState s,
    DeclareLastCardAction a,
    List<GameEvent> events,
  ) {
    events.add(LastCardDeclaredEvent(a.playerId));
    return s
        .copyWith(lastCardDeclaredBy: a.playerId)
        .withHistory(
          HistoryEntry(
            type: HistoryEntryType.lastCardDeclared,
            playerId: a.playerId,
          ),
        );
  }

  // ------------------------------------------------------------------ suit

  GameState _chooseSuit(
    GameState s,
    ChooseSuitAction a,
    List<GameEvent> events,
  ) => _applySuitChoice(s, a.playerId, a.suit, events);

  GameState _applySuitChoice(
    GameState s,
    String playerId,
    CardSuit suit,
    List<GameEvent> events,
  ) {
    final next = s
        .copyWith(
          activeSuit: suit,
          status: GameStatus.awaitingAction,
          stats: s.stats.withCavalloSuit(playerId, suit),
        )
        .withHistory(
          HistoryEntry(
            type: HistoryEntryType.suitChosen,
            playerId: playerId,
            suit: suit,
          ),
        );
    events.add(SuitChosenEvent(playerId, suit));
    return _advanceTurn(next, 1, events);
  }

  // ------------------------------------------------------------------ draw

  GameState _draw(GameState s, DrawCardAction a, List<GameEvent> events) {
    final player = s.currentPlayer;
    final rules = s.rules;

    if (s.isPenaltyPending) {
      // §6b — paying the chain settles the penalty, not the turn. Whatever
      // the chain was worth (+2, +4, +6, …), the seat that took it stays on
      // and may still make one ordinary legal play; only then does the turn
      // advance. No TurnChangedEvent is emitted here, which is exactly what
      // tells a listener a penalty was *resolved* rather than a turn ended.
      final owed = s.pendingDrawCount;
      final chain = s.chainLength;
      final (afterDraw, drawn) = _drawInto(s, player.id, owed, events);
      final next = afterDraw
          .copyWith(
            pendingDrawCount: 0,
            chainLength: 0,
            // Bars a second draw and satisfies `mustDrawBeforePassing`, so a
            // seat left with nothing playable can still pass out of the turn.
            hasDrawnThisTurn: true,
            penaltyResolvedThisTurn: true,
            // §16 — the chain just put cards back in this hand, so whatever
            // was announced about being down to one no longer holds.
            clearLastCardDeclaration: true,
            clearDrawnCard: true,
            status: GameStatus.awaitingAction,
          )
          .withHistory(
            HistoryEntry(
              type: HistoryEntryType.penaltyDraw,
              playerId: player.id,
              count: drawn.length,
            ),
          );
      events.add(CardsDrawnEvent(player.id, drawn, isPenalty: true));
      events.add(ChainResolvedEvent(player.id, owed, chain));
      return next;
    }

    var next = s;
    // Drawing is normally an admission of having nothing to match with.
    if (!resolverFor(s).hasPlayable(player.hand, s)) {
      next = next.copyWith(
        voidSuits: _withVoid(next.voidSuits, player.id, s.activeSuit),
      );
    }
    final (afterDraw, drawn) = _drawInto(next, player.id, 1, events);
    next = afterDraw
        // §16 — drawing is not playing: a seat that had two cards and drew a
        // third is no longer about to reach its last card.
        .copyWith(hasDrawnThisTurn: true, clearLastCardDeclaration: true)
        .withHistory(
          HistoryEntry(
            type: HistoryEntryType.draw,
            playerId: player.id,
            count: drawn.length,
          ),
        );
    events.add(CardsDrawnEvent(player.id, drawn));

    if (drawn.isEmpty) {
      // Nothing left anywhere to draw. Never stall: just move on.
      return _advanceTurn(next, 1, events);
    }

    final card = drawn.first;
    if (rules.playDrawnCardImmediately &&
        resolverFor(next).canPlay(card, next)) {
      // §8 — hand control back so the player may use what they just drew.
      return next.copyWith(drawnCard: card);
    }
    return _advanceTurn(next, 1, events);
  }

  /// Moves up to [count] cards from the stock into [playerId]'s hand,
  /// recycling the discard pile when the stock runs dry (§9).
  (GameState, List<GameCard>) _drawInto(
    GameState s,
    String playerId,
    int count,
    List<GameEvent> events,
  ) {
    var drawPile = List.of(s.drawPile);
    var discard = s.discardPile;
    final drawn = <GameCard>[];
    var recycled = false;
    for (var i = 0; i < count; i++) {
      if (drawPile.isEmpty) {
        if (discard.length <= 1 || recycled) break;
        // §9 — keep the visible top card, shuffle everything beneath it.
        final top = discard.last;
        final below = discard.sublist(0, discard.length - 1);
        drawPile = DeckFactory.shuffle(below, _random(s));
        discard = [top];
        recycled = true;
        events.add(DeckRecycledEvent(drawPile.length));
        s = s.withHistory(
          HistoryEntry(
            type: HistoryEntryType.recycle,
            playerId: '',
            count: drawPile.length,
          ),
        );
      }
      if (drawPile.isEmpty) break;
      drawn.add(drawPile.removeLast());
    }
    if (drawn.isEmpty) return (s, drawn);

    final player = s.playerById(playerId)!;
    final next = s
        .withPlayer(player.copyWith(hand: [...player.hand, ...drawn]))
        .copyWith(
          drawPile: drawPile,
          discardPile: discard,
          drawsByPlayer: {
            ...s.drawsByPlayer,
            playerId: (s.drawsByPlayer[playerId] ?? 0) + drawn.length,
          },
        );
    return (next, drawn);
  }

  // ------------------------------------------------------------ turn order

  /// Index of the seat [steps] places after [from] in the direction of play,
  /// skipping players who are out of the match. Bounded so a corrupt state
  /// can never spin forever.
  int _seatAfter(GameState s, int from, int steps) {
    final n = s.players.length;
    var index = from;
    var moved = 0;
    var guard = 0;
    final limit = n * (steps + 2);
    while (moved < steps && guard++ < limit) {
      index = (index + s.direction.step + n) % n;
      if (!s.players[index].eliminated) moved++;
    }
    return index;
  }

  GameState _advanceTurn(GameState s, int steps, List<GameEvent> events) {
    if (s.isRoundOver) return s;
    final next = s.copyWith(
      currentSeat: _seatAfter(s, s.currentSeat, steps),
      hasDrawnThisTurn: false,
      penaltyResolvedThisTurn: false,
      // §16 — a declaration is good for one turn only and never travels with
      // the turn to the next seat.
      clearLastCardDeclaration: true,
      clearDrawnCard: true,
      turnNumber: s.turnNumber + 1,
      status: GameStatus.awaitingAction,
    );
    events.add(TurnChangedEvent(next.currentPlayerId));
    return next;
  }

  // ---------------------------------------------------------- round / match

  GameState _finishRound(
    GameState s,
    String winnerId, {
    required GameCard winningCard,
    required List<GameEvent> events,
  }) {
    var next = s;

    // §10a — an unanswered chain normally dies with the round.
    if (next.isPenaltyPending) {
      if (next.rules.pendingPenaltyAppliesAfterWin) {
        final victim = next.players[_seatAfter(next, next.currentSeat, 1)];
        final (after, drawn) = _drawInto(
          next,
          victim.id,
          next.pendingDrawCount,
          events,
        );
        next = after;
        events.add(CardsDrawnEvent(victim.id, drawn, isPenalty: true));
      }
      next = next.copyWith(pendingDrawCount: 0, chainLength: 0);
    }

    final policy = ScorePolicy(next.rules);
    final rows = <PlayerRoundResult>[];
    final newlyEliminated = <String>[];
    final players = <GamePlayer>[];
    var stats = next.stats.withRoundWon(winnerId);

    for (final player in next.players) {
      if (player.eliminated) {
        players.add(player);
        continue;
      }
      final penalty = player.id == winnerId
          ? 0
          : policy.handPenalty(player.hand);
      final outcome = policy.apply(
        previousScore: player.score,
        penalty: penalty,
      );
      players.add(
        player.copyWith(
          score: outcome.newScore,
          eliminated: outcome.eliminated,
        ),
      );
      if (outcome.hitExact101) {
        stats = stats.copyWith(resets101: stats.resets101 + 1);
        events.add(Exact101Event(player.id));
      }
      if (outcome.eliminated) newlyEliminated.add(player.id);
      rows.add(
        PlayerRoundResult(
          playerId: player.id,
          name: player.name,
          cardsLeft: player.hand.length,
          penalty: penalty,
          previousScore: outcome.previousScore,
          newScore: outcome.newScore,
          hitExact101: outcome.hitExact101,
          eliminated: outcome.eliminated,
        ),
      );
    }

    stats = stats.copyWith(
      bestComeback: max(stats.bestComeback, _largestDeficit(players)),
    );
    for (final id in newlyEliminated) {
      events.add(PlayerEliminatedEvent(id));
    }

    next = next.copyWith(
      players: players,
      stats: stats,
      status: GameStatus.roundOver,
      roundWinnerId: winnerId,
    );

    final matchWinner = _resolveMatchWinner(next);
    if (matchWinner != null) {
      next = next.copyWith(status: GameStatus.finished, winnerId: matchWinner);
    }

    final winner = next.playerById(winnerId)!;
    final result = RoundResult(
      roundNumber: next.round,
      winnerId: winnerId,
      winnerName: winner.name,
      rows: rows,
      matchOver: next.isFinished,
      matchWinnerId: next.winnerId,
    );
    next = next
        .copyWith(lastRoundResult: result)
        .withHistory(
          HistoryEntry(
            type: HistoryEntryType.roundEnd,
            playerId: winnerId,
            card: winningCard,
          ),
        );
    events.add(RoundEndedEvent(result));
    if (next.isFinished) events.add(MatchEndedEvent(next.winnerId!));
    return next;
  }

  /// The winner's largest deficit. In a penalty game "behind" means a higher
  /// score than the best-placed rival.
  int _largestDeficit(List<GamePlayer> players) {
    var largest = 0;
    for (final player in players) {
      if (player.eliminated) continue;
      var bestRival = 1 << 30;
      for (final other in players) {
        if (other.id == player.id || other.eliminated) continue;
        if (other.score < bestRival) bestRival = other.score;
      }
      if (bestRival == 1 << 30) continue;
      largest = max(largest, player.score - bestRival);
    }
    return largest;
  }

  String? _resolveMatchWinner(GameState s) {
    final rules = s.rules;
    if (rules.eliminateAbove101) {
      final alive = s.players.where((p) => !p.eliminated).toList();
      if (alive.length == 1) return alive.first.id;
      if (alive.isEmpty) {
        // §12a NEEDS_FINAL_RULE_CONFIRMATION — everybody overshot in the same
        // round. Provisional: lowest total takes it.
        return _lowestScore(s.players).id;
      }
      return null;
    }
    // Elimination disabled: the match ends the moment anyone passes the
    // target, and the lowest score wins.
    if (s.players.any((p) => p.score > rules.targetScore)) {
      return _lowestScore(s.players).id;
    }
    return null;
  }

  GamePlayer _lowestScore(List<GamePlayer> pool) {
    var best = pool.first;
    for (final p in pool) {
      if (p.score < best.score) best = p;
    }
    return best;
  }

  GameState _startNextRound(GameState s, List<GameEvent> events) {
    // §12 — who *leads* the new round. Under the confirmed rule that is the
    // seat which closed the previous one, never the next seat round the
    // table. §12a — who *deals* it is a separate question, answered below.
    final winnerSeat = s.roundWinnerId == null
        ? -1
        : s.seatOf(s.roundWinnerId!);
    int starter;
    switch (s.rules.roundStarterPolicy) {
      case RoundStarterPolicy.previousRoundWinner:
        starter = winnerSeat;
      case RoundStarterPolicy.seatAfterPreviousWinner:
        starter = winnerSeat < 0 ? -1 : _seatAfter(s, winnerSeat, 1);
    }
    if (starter < 0 || s.players[starter].eliminated) {
      starter = s.players.indexWhere((p) => !p.eliminated);
      if (starter < 0) starter = 0;
    }

    // §12a — the deal passes one live seat clockwise every round, wrapping at
    // the end of the table, whatever the closer did. Independent of
    // [starter]: the two coincide only by chance.
    final dealer = _seatAfter(s, s.dealerSeat, 1);

    final cleared = s.copyWith(
      players: [for (final p in s.players) p.copyWith(hand: const [])],
      round: s.round + 1,
      dealerSeat: dealer,
      clearRoundWinner: true,
      clearLastRoundResult: true,
    );
    final next = _deal(cleared, startingSeat: starter);
    events.add(RoundStartedEvent(next.round, next.currentPlayerId));
    events.add(TurnChangedEvent(next.currentPlayerId));
    return next;
  }

  // --------------------------------------------------------------- forfeit

  /// A seat leaves the match for good (abandonment, repeated timeouts, or an
  /// explicit surrender online). The seat is eliminated; its cards go to the
  /// bottom of the stock so the 40-card conservation invariant holds; any
  /// chain aimed at it or suit it owed dies with it; if it was to act, play
  /// moves to the next live seat; and if only one seat is left standing the
  /// match is over and that seat wins.
  GameState _forfeit(GameState s, ForfeitAction a, List<GameEvent> events) {
    final player = s.playerById(a.playerId)!;
    final seat = s.seatOf(player.id);
    final wasCurrent = seat == s.currentSeat;

    var next = s
        .withPlayer(player.copyWith(hand: const [], eliminated: true))
        .copyWith(
          drawPile: [...player.hand, ...s.drawPile],
          // §16 — a seat that has left cannot be holding a last card.
          clearLastCardDeclaration: s.hasDeclaredLastCard(player.id),
        )
        .withHistory(
          HistoryEntry(
            type: HistoryEntryType.forfeit,
            playerId: player.id,
            count: player.hand.length,
          ),
        );
    events.add(PlayerForfeitedEvent(player.id));
    events.add(PlayerEliminatedEvent(player.id));

    final alive = next.players.where((p) => !p.eliminated).toList();
    if (alive.length <= 1) {
      final winner = alive.isEmpty ? _lowestScore(next.players) : alive.first;
      next = next.copyWith(
        status: GameStatus.finished,
        winnerId: winner.id,
        pendingDrawCount: 0,
        chainLength: 0,
      );
      events.add(MatchEndedEvent(winner.id));
      return next;
    }

    if (next.isRoundOver) return next; // the next deal skips the empty seat
    if (!wasCurrent) return next;

    // Its turn goes with it: a pending chain is nobody's to answer and an
    // unnamed suit stays whatever was active before the Cavallo.
    next = next.copyWith(
      pendingDrawCount: 0,
      chainLength: 0,
      status: GameStatus.awaitingAction,
    );
    return _advanceTurn(next, 1, events);
  }

  // --------------------------------------------------------------- dealing

  /// Shuffles a fresh deck and deals it into [base], which must have empty
  /// hands. Randomness comes from [_random] applied to [base], so two calls
  /// with the same state deal identically.
  GameState _deal(GameState base, {required int startingSeat}) {
    final rules = base.rules;
    final deck = DeckFactory.shuffled(_random(base));
    final hands = {for (final p in base.players) p.id: <GameCard>[]};
    final seated = base.players.where((p) => !p.eliminated).toList();
    for (var i = 0; i < rules.startingHandSize; i++) {
      for (final p in seated) {
        if (deck.isEmpty) break;
        hands[p.id]!.add(deck.removeLast());
      }
    }

    // §3 — turn one card up to open the round.
    var starterIndex = deck.length - 1;
    if (rules.starterCardPolicy == StarterCardPolicy.avoidActionCards) {
      final plain = deck.lastIndexWhere((c) => !c.isAction);
      if (plain >= 0) starterIndex = plain;
    }
    final starter = deck.removeAt(starterIndex);

    var seat = startingSeat;
    if (seat < 0 ||
        seat >= base.players.length ||
        base.players[seat].eliminated) {
      seat = base.players.indexWhere((p) => !p.eliminated);
      if (seat < 0) seat = 0;
    }

    return base.copyWith(
      players: [for (final p in base.players) p.copyWith(hand: hands[p.id])],
      drawPile: deck,
      discardPile: [starter],
      activeSuit: starter.suit,
      currentSeat: seat,
      pendingDrawCount: 0,
      chainLength: 0,
      status: GameStatus.awaitingAction,
      turnNumber: 0,
      hasDrawnThisTurn: false,
      penaltyResolvedThisTurn: false,
      clearLastCardDeclaration: true,
      clearDrawnCard: true,
      playedCards: const [],
      drawsByPlayer: const {},
      voidSuits: const {},
    );
  }

  // ----------------------------------------------------------------- misc

  GameState _stampClock(
    GameState next, {
    required GameState? previous,
    required int? now,
  }) {
    final turnChanged =
        previous == null ||
        next.turnNumber != previous.turnNumber ||
        next.round != previous.round ||
        next.currentSeat != previous.currentSeat ||
        // §6b/§14.4 — paying a chain keeps the seat but opens a new action
        // window. Without this the continuation the client asked for would
        // inherit whatever was left of the clock, often nothing at all.
        (next.penaltyResolvedThisTurn && !previous.penaltyResolvedThisTurn);
    if (!turnChanged) return next;
    if (now == null) return next.copyWith(clearTurnClock: true);
    final limit = next.rules.turnTimeLimitSeconds;
    return next.copyWith(
      turnStartedAt: now,
      turnDeadlineAt: limit == null ? null : now + limit * 1000,
      clearTurnClock: false,
    );
  }

  static Map<String, List<String>> _withVoid(
    Map<String, List<String>> voids,
    String playerId,
    CardSuit suit,
  ) {
    final list = List<String>.of(voids[playerId] ?? const []);
    if (!list.contains(suit.key)) list.add(suit.key);
    return {...voids, playerId: list};
  }

  static Map<String, List<String>> _withoutVoid(
    Map<String, List<String>> voids,
    String playerId,
    CardSuit suit,
  ) {
    final current = voids[playerId];
    if (current == null || !current.contains(suit.key)) return voids;
    return {...voids, playerId: current.where((k) => k != suit.key).toList()};
  }

  /// Conservation: the engine never creates or loses a card, never
  /// duplicates one, and never leaves the discard pile empty. A freshly
  /// created game holds all [Deck.size] cards; every action preserves the
  /// count it was given.
  void _assertInvariants(GameState s, {required int expectedCards}) {
    assert(
      s.totalCards == expectedCards,
      'card count drifted: ${s.totalCards} != $expectedCards',
    );
    assert(s.discardPile.isNotEmpty, 'discard pile emptied');
    assert(() {
      final seen = <GameCard>{};
      for (final c in [
        ...s.drawPile,
        ...s.discardPile,
        for (final p in s.players) ...p.hand,
      ]) {
        if (!seen.add(c)) return false;
      }
      return true;
    }(), 'duplicate card in play');
  }
}
