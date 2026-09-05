import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/utils/motion.dart';
import '../../game/application/table_controller.dart';
import '../../game/application/table_cue.dart';
import '../../game/domain/ai/bot_decision.dart';
import '../../game/domain/ai/bot_strategy.dart';
import '../../game/domain/ai/bot_view_factory.dart';
import '../../game/domain/ai/normal_bot.dart';
import '../../game/domain/card_suit.dart';
import '../../game/domain/engine/game_event.dart';
import '../../game/domain/engine/game_session.dart';
import '../../game/domain/game_card.dart';
import '../../game/domain/game_player.dart';
import '../../game/domain/game_state.dart';
import '../../game/domain/round_result.dart';
import '../../game/domain/table_session_status.dart';
import '../domain/tutorial_lessons.dart';
import '../../../core/utils/log.dart';

/// Where the tutorial is between two taps.
enum TutorialPhase {
  /// The player has to make the move the prompt asks for.
  waiting,

  /// Cues or the opponent's scripted reply are playing.
  busy,

  /// The lesson's point has been made; "Avanti" loads the next one.
  lessonDone,

  /// Every lesson done.
  finished,
}

/// Drives the guided table.
///
/// The same [GameSession] → [GameEngine] path as a real match: each lesson
/// restores a controlled [GameState] and the player's move goes through
/// `applyAction` like any other, so what the tutorial shows is what the
/// rules do. The only things this driver adds are *which* moves it accepts
/// (the lesson's), and a scripted opponent reply. No statistics, no save,
/// no XP — a tutorial table is not a match.
class TutorialController extends TableController {
  TutorialController({
    required this.seats,
    List<TutorialLesson>? lessons,
    Random? random,
    bool Function()? withDelays,
  }) : lessons = lessons ?? TutorialLessons.all,
       _random = random ?? Random(7),
       _withDelays = withDelays ?? (() => true);

  final TutorialSeats seats;
  final List<TutorialLesson> lessons;
  final Random _random;
  final bool Function() _withDelays;

  late final GameSession session = GameSession(lessons.first.build(seats));
  late final BotStrategy _opponent = NormalBot(random: Random(3));

  final RxInt lessonIndex = 0.obs;
  final RxInt stepIndex = 0.obs;
  final Rx<TutorialPhase> phase = TutorialPhase.waiting.obs;

  /// Set when the player did something other than the lesson asks; the
  /// overlay shows it briefly.
  final Rx<String?> hint = Rx<String?>(null);

  /// The last suit the player named — the Cavallo lesson's closing line.
  final Rx<CardSuit?> chosenSuit = Rx<CardSuit?>(null);

  // ----------------------------------------------------- TableController

  @override
  final RxInt revision = 0.obs;
  @override
  final RxBool busy = false.obs;
  @override
  final Rx<GameCard?> selectedCard = Rx<GameCard?>(null);
  @override
  final Rx<GameCard?> pendingSuitChoice = Rx<GameCard?>(null);
  @override
  final RxInt chainLevel = 0.obs;
  @override
  final RxInt chainTotal = 0.obs;
  @override
  final Rx<String?> handoverPlayerId = Rx<String?>(null);
  @override
  final Rx<String?> banner = Rx<String?>(null);
  @override
  final RxMap<String, String> reactions = <String, String>{}.obs;

  /// Never set: the tutorial's round result is explained by the overlay,
  /// not by the results screen.
  @override
  final Rx<RoundResult?> lastRoundResult = Rx<RoundResult?>(null);
  @override
  final Rx<TableSessionStatus> tableStatus = Rx<TableSessionStatus>(
    TableSessionStatus.offlineLocal,
  );

  @override
  List<String> get humanIds => const [TutorialSeats.humanId];
  @override
  bool get isOnline => false;
  @override
  bool get isTutorial => true;
  @override
  GameState get state => session.state;
  @override
  GamePlayer get currentPlayer => session.currentPlayer;
  @override
  bool get isHumanTurn => isHumanSeat(currentPlayer.id);
  @override
  GamePlayer get viewingPlayer => state.playerById(TutorialSeats.humanId)!;
  @override
  List<GamePlayer> get opponents =>
      state.players.where((p) => p.id != TutorialSeats.humanId).toList();

  TutorialLesson get lesson => lessons[lessonIndex.value];
  TutorialExpectation? get expectation => stepIndex.value < lesson.steps.length
      ? lesson.steps[stepIndex.value]
      : null;

  @override
  bool get canInteract =>
      phase.value == TutorialPhase.waiting &&
      !busy.value &&
      isHumanTurn &&
      state.status == GameStatus.awaitingAction;

  /// Only the card the lesson asks for lights up (or every legal card for
  /// the free lesson); the engine still has the final say on legality.
  @override
  List<GameCard> get playableForViewer {
    if (!isHumanTurn) return const [];
    final legal = session.playableCardsFor(currentPlayer);
    return switch (expectation) {
      ExpectAnyLegalCard() => legal,
      ExpectCard(:final card) => legal.contains(card) ? [card] : const [],
      _ => const [],
    };
  }

  @override
  bool get canDraw => expectation is ExpectDraw && session.canDraw;
  @override
  bool get canEndTurn => false;
  @override
  bool get mustTakePenalty => false;

  /// §16 — the same engine predicate the real table uses. No lesson brings
  /// the learner down to two cards today, so it is simply never offered;
  /// if one ever does, the button appears and works without a second
  /// implementation.
  @override
  bool get canDeclareLastCard => canInteract && session.canDeclareLastCard;

  @override
  bool get hasDeclaredLastCard =>
      state.hasDeclaredLastCard(TutorialSeats.humanId);

  @override
  Future<void> declareLastCard() async {
    if (!canDeclareLastCard) return;
    session.declareLastCard();
    await _drain();
  }

  final List<TableCue> _queue = [];
  late final VoidCallback _unsubscribe;
  bool _disposed = false;
  bool _started = false;
  Timer? _hintTimer;
  final Map<String, Timer> _reactionTimers = {};

  @override
  void onInit() {
    super.onInit();
    _unsubscribe = session.listen(_onEngineEvent);
    _syncChain();
  }

  @override
  void onClose() {
    _disposed = true;
    _unsubscribe();
    _hintTimer?.cancel();
    for (final t in _reactionTimers.values) {
      t.cancel();
    }
    super.onClose();
  }

  @override
  void start() {
    if (_started) return;
    _started = true;
    unawaited(_loadLesson(0));
  }

  // ------------------------------------------------------------- lessons

  Future<void> _loadLesson(int index) async {
    lessonIndex.value = index;
    stepIndex.value = 0;
    chosenSuit.value = null;
    pendingSuitChoice.value = null;
    selectedCard.value = null;
    _queue.clear();
    session.restore(lessons[index].build(seats));
    _syncChain();
    busy.value = true;
    phase.value = TutorialPhase.busy;
    revision.value++;
    _queue.add(
      DealCue(
        state.players.map((p) => p.id).toList(),
        viewingPlayer.hand.length,
      ),
    );
    await _drain();
    if (_disposed) return;
    busy.value = false;
    phase.value = TutorialPhase.waiting;
    revision.value++;
  }

  /// "Avanti": the next lesson, or the end.
  Future<void> next() async {
    if (phase.value != TutorialPhase.lessonDone) return;
    if (lessonIndex.value + 1 >= lessons.length) {
      phase.value = TutorialPhase.finished;
      revision.value++;
      return;
    }
    await _loadLesson(lessonIndex.value + 1);
  }

  /// Jump back to a lesson from the finished screen.
  Future<void> restart() => _loadLesson(0);

  Future<void> _afterStep() async {
    stepIndex.value++;
    if (expectation != null) {
      // Another move in this lesson (draw → play, Cavallo → suit).
      busy.value = false;
      phase.value = TutorialPhase.waiting;
      revision.value++;
      return;
    }
    if (lesson.opponentReplies &&
        !isHumanTurn &&
        !state.isRoundOver &&
        !state.isFinished) {
      await _opponentTurn();
    }
    if (_disposed) return;
    busy.value = false;
    phase.value = TutorialPhase.lessonDone;
    revision.value++;
  }

  /// The scripted opponent: the ordinary Normal bot on a hand chosen so its
  /// reply is the one the lesson wants to show.
  Future<void> _opponentTurn() async {
    var guard = 0;
    while (!_disposed &&
        !isHumanTurn &&
        !state.isRoundOver &&
        !state.isFinished &&
        guard++ < 6) {
      await _think();
      if (_disposed) return;
      if (state.status == GameStatus.awaitingSuitChoice) {
        session.chooseSuit(
          _opponent.chooseSuit(BotViewFactory.forCurrentPlayer(state)),
        );
        await _drain();
        continue;
      }
      final decision = _opponent.decide(BotViewFactory.forCurrentPlayer(state));
      switch (decision.action) {
        case BotAction.play:
          session.autoPlayCard(decision.card!, chosenSuit: decision.suit);
        case BotAction.draw:
          session.drawCard();
          if (state.drawnCard != null) {
            await _drain();
            await _think(short: true);
            final again = _opponent.decide(
              BotViewFactory.forCurrentPlayer(state),
            );
            if (again.action == BotAction.play && again.card != null) {
              session.autoPlayCard(again.card!, chosenSuit: again.suit);
            } else if (session.canEndTurn) {
              session.endTurn();
            }
          }
        case BotAction.endTurn:
          if (session.canEndTurn) {
            session.endTurn();
          } else if (session.canDraw) {
            session.drawCard();
          }
      }
      await _drain();
    }
  }

  Future<void> _think({bool short = false}) async {
    if (!_withDelays()) return;
    final span =
        AppDurations.botThinkMax.inMilliseconds -
        AppDurations.botThinkMin.inMilliseconds;
    final ms =
        AppDurations.botThinkMin.inMilliseconds +
        _random.nextInt(span <= 0 ? 1 : span);
    await Future<void>.delayed(
      Motion.scale(Duration(milliseconds: short ? ms ~/ 2 : ms)),
    );
  }

  // --------------------------------------------------------- player moves

  /// Whether [card] is the move this step asks for — and legal, which the
  /// engine decides, never this class.
  bool accepts(GameCard card) {
    final e = expectation;
    if (e is ExpectAnyLegalCard) return session.canPlay(card);
    if (e is ExpectCard) return e.card == card && session.canPlay(card);
    return false;
  }

  @override
  Future<void> selectCard(GameCard card) async {
    if (!canInteract) return;
    if (selectedCard.value == card) {
      await playCard(card);
      return;
    }
    selectedCard.value = card;
    HapticService.instance.light();
    AudioService.instance.play(Sfx.cardPickup, volume: 0.7);
  }

  @override
  void clearSelection() => selectedCard.value = null;

  @override
  void rejectCard(GameCard card) {
    HapticService.instance.error();
    AudioService.instance.play(Sfx.invalid);
    _showHint();
  }

  @override
  Future<void> playCard(GameCard card) async {
    if (!canInteract) return;
    if (!accepts(card)) {
      rejectCard(card);
      _queue.add(InvalidCue(card));
      await _drain();
      return;
    }
    selectedCard.value = null;
    busy.value = true;
    phase.value = TutorialPhase.busy;
    session.playCard(card);
    await _drain();
    await _afterStep();
  }

  @override
  Future<void> drawCard() async {
    if (!canInteract || !canDraw) return;
    busy.value = true;
    phase.value = TutorialPhase.busy;
    session.drawCard();
    await _drain();
    await _afterStep();
  }

  @override
  Future<void> endTurn() async {}

  @override
  Future<void> chooseSuit(CardSuit suit) async {
    if (pendingSuitChoice.value == null || expectation is! ExpectSuit) return;
    pendingSuitChoice.value = null;
    chosenSuit.value = suit;
    busy.value = true;
    phase.value = TutorialPhase.busy;
    AudioService.instance.play(Sfx.suitSelect);
    HapticService.instance.medium();
    session.chooseSuit(suit);
    await _drain();
    await _afterStep();
  }

  @override
  void sendReaction(String phrase) {
    reactions[viewingPlayer.id] = phrase;
    _reactionTimers.remove(viewingPlayer.id)?.cancel();
    _reactionTimers[viewingPlayer.id] = Timer(
      const Duration(milliseconds: 1800),
      () {
        if (!_disposed) reactions.remove(viewingPlayer.id);
      },
    );
  }

  @override
  void confirmHandover() {}

  /// Nothing to keep: a tutorial is never resumed.
  @override
  Future<void> persistNow() async {}

  @override
  Future<void> beginNextRound() async {}

  @override
  Future<void> abandon() async {}

  // ---------------------------------------------------------------- cues

  void _onEngineEvent(GameEvent event) {
    final cue = TableCues.fromEvent(event, isHumanSeat: isHumanSeat);
    if (cue != null) _queue.add(cue);
    if (event is SuitChoiceRequestedEvent && isHumanSeat(event.playerId)) {
      pendingSuitChoice.value = event.card;
    }
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty && !_disposed) {
      final cue = _queue.removeAt(0);
      _reactToCue(cue);
      await _present(cue);
    }
    revision.value++;
  }

  Future<void> _present(TableCue cue) async {
    final player = cuePlayer;
    if (player == null) {
      if (_withDelays()) {
        await Future<void>.delayed(Motion.scale(AppDurations.quick));
      }
      return;
    }
    try {
      await player(cue).timeout(const Duration(seconds: 3));
    } on TimeoutException {
      // Never block the lesson on a stalled view.
    } catch (error) {
      Log.d('tutorial cue failed: $error');
    }
  }

  void _reactToCue(TableCue cue) {
    switch (cue) {
      case PlayCardCue():
        AudioService.instance.play(Sfx.cardSlide);
        HapticService.instance.medium();
        if (cue.card.isAce) AudioService.instance.play(Sfx.ace);
      case DrawCue():
        AudioService.instance.play(
          cue.isPenalty ? Sfx.cardDrop : Sfx.cardPickup,
        );
      case ChainGrowCue():
        chainTotal.value = cue.total;
        chainLevel.value = cue.level;
        AudioService.instance.play(Sfx.chainForLevel(cue.level));
        HapticService.instance.strong();
      case ChainBreakCue():
        chainTotal.value = 0;
        chainLevel.value = 0;
        AudioService.instance.play(Sfx.cardDrop);
      case RecycleCue():
        AudioService.instance.play(Sfx.shuffle);
      case DealCue():
        AudioService.instance.play(Sfx.cardSlide, volume: 0.8);
      case InvalidCue():
        AudioService.instance.play(Sfx.invalid);
      case LastCardCue():
        AudioService.instance.play(Sfx.suitSelect);
      case SuitChosenCue():
      case SkipCue():
      case TurnCue():
      case ReactionCue():
        break;
    }
  }

  void _syncChain() {
    chainTotal.value = state.pendingDrawCount;
    chainLevel.value = state.chainLength;
  }

  void _showHint() {
    hint.value = Strings.s.tutorialHintFollow;
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!_disposed) hint.value = null;
    });
  }

  bool get isLastLesson => lessonIndex.value + 1 >= lessons.length;
}
