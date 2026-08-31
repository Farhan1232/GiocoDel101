import 'dart:math';

import '../card_suit.dart';
import '../engine/game_event.dart';
import '../engine/game_session.dart';
import '../game_card.dart';
import '../game_player.dart';
import '../game_state.dart';
import '../player_type.dart';
import 'bot_decision.dart';
import 'bot_factory.dart';
import 'bot_view_factory.dart';

/// Automated bot-vs-bot match runner with invariant checking.
///
/// Pure Dart: no Flutter, no I/O, no clock. The same code drives both the
/// `tool/bot_simulation.dart` CLI and `test/bot_simulation_test.dart`, so a
/// regression found by one is reproducible by the other from the same seed.
///
/// Every seat is a bot of a single difficulty (personalities rotate across
/// seats and matches). The driving loop is the one used by `bot_test.dart`:
/// deal, let the seat to act decide, apply, repeat until the match finishes.
/// Along the way the engine's structural invariants are checked after every
/// applied action; violations are *counted*, never thrown, so one bad match
/// does not hide the others.

/// A category of invariant breach. One [SimulationViolation] carries one.
enum ViolationKind {
  /// (a) The 40 cards are not all accounted for across stock, discard, hands.
  cardCount,

  /// (b) The same card id appears twice somewhere on the table.
  duplicateCard,

  /// (c) The discard pile is empty (there must always be a visible top card).
  emptyDiscard,

  /// (d) The seat to act is out of range or eliminated while play is live.
  badSeat,

  /// (e) A count that can never be negative went negative.
  negativeCount,

  /// (f) A bot proposed a move the engine refused.
  illegalProposal,

  /// (g) The match did not finish inside the step cap.
  hang,

  /// (h) After the match finished, a further action was accepted or the
  /// version moved.
  finishedUnstable,

  /// (i) After the match finished there is neither a winner nor exactly one
  /// surviving player.
  noWinner,
}

/// One breach, with enough context to replay it.
class SimulationViolation {
  const SimulationViolation({
    required this.kind,
    required this.matchIndex,
    required this.seed,
    required this.step,
    required this.detail,
  });

  final ViolationKind kind;

  /// Index of the match inside its difficulty × player-count combination.
  final int matchIndex;

  /// The deal seed; feed it back to [BotSimulator.playMatch] to reproduce.
  final int seed;

  /// Loop iteration at which the breach was observed.
  final int step;
  final String detail;

  @override
  String toString() =>
      '[${kind.name}] match #$matchIndex seed $seed step $step: $detail';
}

/// Everything observed while playing one combination of difficulty and
/// player count for [matches] matches.
class SimulationReport {
  SimulationReport({
    required this.difficulty,
    required this.playerCount,
    required this.matches,
    required this.stepCap,
  }) : winsBySeat = List<int>.filled(playerCount, 0);

  final BotDifficulty difficulty;
  final int playerCount;
  final int matches;
  final int stepCap;

  /// Bot actions applied (play, draw, pass, suit choice). Round restarts
  /// are counted separately in [rounds].
  int actions = 0;

  /// Rounds completed (one per `RoundEndedEvent`).
  int rounds = 0;

  /// Times the stock ran dry and the discard pile was recycled.
  int reshuffles = 0;

  /// Times a 2 was played and the chain grew (`ChainGrewEvent`).
  int chains = 0;

  /// Longest chain of 2s observed.
  int maxChain = 0;

  /// Cavallo played into a live chain (`ChainBlockedEvent`).
  int cavalloBlocks = 0;

  /// Asso skips (`TurnSkippedEvent`).
  int assoSkips = 0;

  /// Players reset to zero by landing on exactly the target (`Exact101Event`).
  int exact101 = 0;

  /// Penalty draws taken (events) and the cards they cost in total.
  int penaltyDraws = 0;
  int penaltyCards = 0;

  /// Match wins per seat index.
  final List<int> winsBySeat;

  /// Matches that hit [stepCap] without finishing.
  int hangs = 0;

  /// Every breach observed, in order.
  final List<SimulationViolation> violations = [];

  /// Wall-clock milliseconds spent, filled in by the caller.
  int elapsedMs = 0;

  String get label => '${difficulty.name} × $playerCount players';

  int countOf(ViolationKind kind) =>
      violations.where((v) => v.kind == kind).length;

  int get illegalProposals => countOf(ViolationKind.illegalProposal);
  int get finishedUnstable => countOf(ViolationKind.finishedUnstable);

  /// Violations that are not hangs (hangs are reported on their own line).
  int get violationCount => violations.length - countOf(ViolationKind.hang);

  bool get clean => violations.isEmpty && hangs == 0;

  /// Human-readable block for this combination.
  List<String> summaryLines() {
    String row(String key, Object value) => '  ${key.padRight(18)} $value';
    final wins = [
      for (var i = 0; i < winsBySeat.length; i++) 'seat$i=${winsBySeat[i]}',
    ].join('  ');
    return [
      '== $label ==',
      row('matches', '$matches (${elapsedMs}ms)'),
      row('total actions', actions),
      row('rounds', rounds),
      row('reshuffles', reshuffles),
      row('+2 chains', '$chains (max chain $maxChain)'),
      row('Cavallo blocks', cavalloBlocks),
      row('Asso skips', assoSkips),
      row('exact-101 resets', exact101),
      row('penalty draws', '$penaltyDraws ($penaltyCards cards)'),
      row('wins by seat', wins),
      row('violations', '$violationCount  hangs $hangs'),
      for (final v in violations) '    $v',
    ];
  }
}

/// Result of a single simulated match.
class MatchOutcome {
  const MatchOutcome({
    required this.seed,
    required this.steps,
    required this.finished,
    required this.winnerSeat,
    required this.violations,
  });

  final int seed;
  final int steps;
  final bool finished;

  /// Seat index of the winner, or -1 when none was declared.
  final int winnerSeat;
  final List<SimulationViolation> violations;
}

/// Runs whole matches and checks the engine on every step.
class BotSimulator {
  const BotSimulator._();

  /// Player counts exercised by [runAll].
  static const List<int> playerCounts = [2, 3, 4];

  /// Default upper bound on loop iterations before a match is called a hang.
  static const int defaultStepCap = 40000;

  /// Ordered list of every difficulty × player-count combination.
  static List<(BotDifficulty, int)> get combinations => [
    for (final d in BotDifficulty.values)
      for (final n in playerCounts) (d, n),
  ];

  /// Deterministic deal seed for [matchIndex] of combination [comboIndex].
  static int seedFor(int comboIndex, int matchIndex) =>
      comboIndex * 100000 + matchIndex;

  /// Runs every combination for [matches] matches each.
  static List<SimulationReport> runAll({
    required int matches,
    int stepCap = defaultStepCap,
  }) {
    final combos = combinations;
    return [
      for (var i = 0; i < combos.length; i++)
        runCombination(
          combos[i].$1,
          combos[i].$2,
          matches: matches,
          comboIndex: i,
          stepCap: stepCap,
        ),
    ];
  }

  /// Plays [matches] matches of [playerCount] bots at [difficulty] and
  /// aggregates what happened.
  static SimulationReport runCombination(
    BotDifficulty difficulty,
    int playerCount, {
    required int matches,
    int comboIndex = 0,
    int stepCap = defaultStepCap,
  }) {
    final report = SimulationReport(
      difficulty: difficulty,
      playerCount: playerCount,
      matches: matches,
      stepCap: stepCap,
    );
    final sw = Stopwatch()..start();
    for (var m = 0; m < matches; m++) {
      final outcome = playMatch(
        difficulty,
        playerCount,
        seed: seedFor(comboIndex, m),
        matchIndex: m,
        stepCap: stepCap,
        report: report,
      );
      report.violations.addAll(outcome.violations);
      if (!outcome.finished) report.hangs++;
      if (outcome.winnerSeat >= 0) report.winsBySeat[outcome.winnerSeat]++;
    }
    report.elapsedMs = sw.elapsedMilliseconds;
    return report;
  }

  /// Plays one match to the end. Event counters land in [report] when one is
  /// given; violations are returned in the outcome.
  static MatchOutcome playMatch(
    BotDifficulty difficulty,
    int playerCount, {
    required int seed,
    int matchIndex = 0,
    int stepCap = defaultStepCap,
    SimulationReport? report,
  }) {
    final players = [
      for (var i = 0; i < playerCount; i++)
        GamePlayer(
          id: 'p$i',
          name: 'P$i',
          type: PlayerType.bot,
          avatarId: 'marco',
          difficulty: difficulty,
          // Rotate personalities across seats *and* matches so every seat
          // meets every temperament over a run.
          personality: BotPersonality
              .values[(i + matchIndex) % BotPersonality.values.length],
        ),
    ];
    final engine = GameSession.newMatch(
      gameId: 'sim',
      players: players,
      mode: GameMode.vsComputer,
      seed: seed,
    );
    final bots = {
      for (var i = 0; i < players.length; i++)
        players[i].id: BotFactory.create(
          difficulty,
          personality: players[i].personality,
          random: Random(seed * 31 + i),
        ),
    };

    final violations = <SimulationViolation>[];
    var steps = 0;
    void violate(ViolationKind kind, String detail) {
      violations.add(
        SimulationViolation(
          kind: kind,
          matchIndex: matchIndex,
          seed: seed,
          step: steps,
          detail: detail,
        ),
      );
    }

    // Event counters. Presentation hints only, but they tell us which rules
    // the run actually exercised.
    final unsubscribe = engine.listen((event) {
      if (report == null) return;
      switch (event) {
        case RoundEndedEvent():
          report.rounds++;
        case DeckRecycledEvent():
          report.reshuffles++;
        case ChainGrewEvent(:final chainLength):
          report.chains++;
          if (chainLength > report.maxChain) report.maxChain = chainLength;
        case ChainBlockedEvent():
          report.cavalloBlocks++;
        case TurnSkippedEvent():
          report.assoSkips++;
        case Exact101Event():
          report.exact101++;
        case CardsDrawnEvent(:final cards, isPenalty: true):
          report.penaltyDraws++;
          report.penaltyCards += cards.length;
        default:
          break;
      }
    });

    // The freshly dealt table must already be sound.
    _checkState(engine.state, violations, matchIndex, seed, steps);

    // ---- the driving loop (mirrors bot_test.dart) ------------------------
    while (!engine.state.isFinished && steps++ < stepCap) {
      if (engine.state.status == GameStatus.roundOver) {
        final r = engine.startNextRound();
        if (!r.accepted) {
          violate(ViolationKind.illegalProposal, 'startNextRound refused');
        }
        _checkState(engine.state, violations, matchIndex, seed, steps);
        continue;
      }
      final bot = bots[engine.currentPlayer.id]!;
      final view = BotViewFactory.forCurrentPlayer(engine.state);
      if (engine.state.status == GameStatus.awaitingSuitChoice) {
        final suit = bot.chooseSuit(view);
        final r = engine.chooseSuit(suit);
        report?.actions++;
        if (!r.accepted) {
          violate(
            ViolationKind.illegalProposal,
            '${difficulty.name} named ${suit.key} illegally '
            '(${r.failure?.name})',
          );
        }
        _checkState(engine.state, violations, matchIndex, seed, steps);
        continue;
      }
      final decision = bot.decide(view);
      switch (decision.action) {
        case BotAction.play:
          final card = decision.card;
          if (card == null) {
            violate(ViolationKind.illegalProposal, 'play without a card');
            break;
          }
          // §16 — the simulator drives bots through the same declaring path
          // the table does, so a run proves the rule as well as the bots.
          final r = engine.autoPlayCard(card, chosenSuit: decision.suit);
          report?.actions++;
          if (!r.accepted) {
            violate(
              ViolationKind.illegalProposal,
              '${difficulty.name} played $card illegally '
              '(${r.failure?.name})',
            );
          }
        case BotAction.draw:
          final r = engine.drawCard();
          report?.actions++;
          if (!r.accepted) {
            violate(
              ViolationKind.illegalProposal,
              '${difficulty.name} drew illegally (${r.failure?.name})',
            );
          }
          // A drawn card that cannot be played ends the turn at once, exactly
          // as the table does for a bot.
          if (engine.state.drawnCard == null && engine.canEndTurn) {
            engine.endTurn();
            report?.actions++;
          }
        case BotAction.endTurn:
          final r = engine.endTurn();
          report?.actions++;
          if (!r.accepted) {
            violate(
              ViolationKind.illegalProposal,
              '${difficulty.name} passed illegally (${r.failure?.name})',
            );
          }
      }
      _checkState(engine.state, violations, matchIndex, seed, steps);

      // A bot that keeps proposing illegal moves would spin until the cap;
      // bail early so the run stays fast and the report stays readable.
      if (violations.length > 50) break;
    }
    unsubscribe();

    final finished = engine.state.isFinished;
    if (!finished) {
      violate(ViolationKind.hang, 'not finished after $steps steps');
    } else {
      _checkFinished(engine, violate);
    }

    final winnerId = engine.state.winnerId;
    return MatchOutcome(
      seed: seed,
      steps: steps,
      finished: finished,
      winnerSeat: winnerId == null ? -1 : engine.state.seatOf(winnerId),
      violations: violations,
    );
  }

  // -------------------------------------------------------------- checks

  /// Invariants (a)–(e), checked after every applied action.
  static void _checkState(
    GameState s,
    List<SimulationViolation> out,
    int matchIndex,
    int seed,
    int step,
  ) {
    void violate(ViolationKind kind, String detail) {
      out.add(
        SimulationViolation(
          kind: kind,
          matchIndex: matchIndex,
          seed: seed,
          step: step,
          detail: detail,
        ),
      );
    }

    // (a) card conservation
    if (s.totalCards != Deck.size) {
      violate(
        ViolationKind.cardCount,
        'total ${s.totalCards} != ${Deck.size} '
        '(stock ${s.drawPile.length}, discard ${s.discardPile.length}, '
        'hands ${s.players.map((p) => p.hand.length).join('/')})',
      );
    }

    // (b) no duplicate ids anywhere
    final seen = <String>{};
    final dups = <String>[];
    void scan(Iterable<GameCard> cards) {
      for (final c in cards) {
        if (!seen.add(c.id)) dups.add(c.id);
      }
    }

    scan(s.drawPile);
    scan(s.discardPile);
    for (final p in s.players) {
      scan(p.hand);
    }
    if (dups.isNotEmpty) {
      violate(ViolationKind.duplicateCard, 'duplicates ${dups.join(', ')}');
    }

    // (c) a visible top card at all times
    if (s.discardPile.isEmpty) {
      violate(ViolationKind.emptyDiscard, 'discard pile empty');
    }

    // (d) the seat to act is live while play is live
    final live =
        s.status == GameStatus.awaitingAction ||
        s.status == GameStatus.awaitingSuitChoice;
    if (live) {
      if (s.currentSeat < 0 || s.currentSeat >= s.players.length) {
        violate(ViolationKind.badSeat, 'currentSeat ${s.currentSeat}');
      } else if (s.players[s.currentSeat].eliminated) {
        violate(
          ViolationKind.badSeat,
          'seat ${s.currentSeat} is eliminated but to act',
        );
      }
    }

    // (e) nothing negative
    if (s.pendingDrawCount < 0) {
      violate(ViolationKind.negativeCount, 'pending ${s.pendingDrawCount}');
    }
    if (s.chainLength < 0) {
      violate(ViolationKind.negativeCount, 'chain ${s.chainLength}');
    }
    // Hand sizes are list lengths and cannot go negative; the card-count
    // check above already catches a hand that lost or gained cards.
    for (final p in s.players) {
      if (p.score < 0) {
        violate(ViolationKind.negativeCount, '${p.id} score ${p.score}');
      }
    }
  }

  /// Invariants (h) and (i), checked once the match is finished.
  static void _checkFinished(
    GameSession engine,
    void Function(ViolationKind, String) violate,
  ) {
    final finished = engine.state;

    // (i) a winner, or a single survivor
    final survivors = finished.activePlayers.length;
    if (finished.winnerId == null && survivors != 1) {
      violate(
        ViolationKind.noWinner,
        'no winnerId and $survivors players still in',
      );
    }
    if (finished.winnerId != null && finished.seatOf(finished.winnerId!) < 0) {
      violate(ViolationKind.noWinner, 'winner ${finished.winnerId} not seated');
    }

    // (h) nothing further may be applied and the version must not move
    final version = finished.version;
    final anyCard = finished.currentPlayer.hand.isNotEmpty
        ? finished.currentPlayer.hand.first
        : Deck.standard.first;
    final probes = <String, MoveResult Function()>{
      'playCard': () => engine.playCard(anyCard),
      'drawCard': engine.drawCard,
      'endTurn': engine.endTurn,
      'chooseSuit': () => engine.chooseSuit(CardSuit.denari),
      'startNextRound': engine.startNextRound,
    };
    for (final entry in probes.entries) {
      final r = entry.value();
      if (r.accepted) {
        violate(
          ViolationKind.finishedUnstable,
          '${entry.key} accepted after finish',
        );
      }
      if (engine.state.version != version) {
        violate(
          ViolationKind.finishedUnstable,
          '${entry.key} moved version $version -> ${engine.state.version}',
        );
      }
      if (!engine.state.isFinished) {
        violate(
          ViolationKind.finishedUnstable,
          '${entry.key} left status ${engine.state.status.name}',
        );
      }
    }
  }
}
