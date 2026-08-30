import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/utils/motion.dart';
import '../../../app/localization/app_strings.dart';
import '../domain/ai/bot_decision.dart';
import '../domain/ai/bot_factory.dart';
import '../domain/ai/bot_strategy.dart';
import '../domain/ai/bot_view_factory.dart';
import '../domain/engine/game_session.dart';
import '../domain/engine/game_event.dart';
import '../domain/card_suit.dart';
import '../domain/game_card.dart';
import '../domain/game_player.dart';
import '../domain/game_state.dart';
import '../domain/player_type.dart';
import '../domain/round_result.dart';
import '../domain/table_session_status.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/storage/game_storage_service.dart';
import '../../settings/application/settings_controller.dart';
import '../../profile/application/stats_controller.dart';
import 'table_cue.dart';
import 'table_controller.dart';

export 'table_controller.dart' show CuePlayer;

/// Drives one LOCAL match: owns the engine, paces the bots, orders the
/// table's animations, and keeps a resumable snapshot on disk.
///
/// All game rules live in the pure GameEngine behind [GameSession]; this class only decides *when*
/// things happen and what they sound and feel like.
class GameController extends TableController {
  GameController({
    required this.session,
    required this.storage,
    required this.settings,
    required this.stats,
    required this.humanIds,
    Random? random,
    DateTime Function()? clock,
  }) : _random = random ?? Random(),
       _clock = clock ?? DateTime.now;

  final GameSession session;
  final GameStorageService storage;
  final SettingsController settings;
  final StatsController stats;

  /// Seats a person plays. One entry vs the computer, several in Pass & Play.
  @override
  final List<String> humanIds;

  final Random _random;

  /// Wall clock for the reaction cooldown; injectable so tests can move it.
  final DateTime Function() _clock;

  /// Bumped whenever the engine state changes, so `Obx` rebuilds cheaply
  /// without deep-copying the match on every card.
  @override
  final RxInt revision = 0.obs;

  /// True while cues are playing: input is refused, bots wait their turn.
  @override
  final RxBool busy = false.obs;

  @override
  final Rx<GameCard?> selectedCard = Rx<GameCard?>(null);

  /// §13 — set while the Suit Ritual is open for a human.
  @override
  final Rx<GameCard?> pendingSuitChoice = Rx<GameCard?>(null);

  /// §11 — live Chain Storm level, 0 when calm.
  @override
  final RxInt chainLevel = 0.obs;
  @override
  final RxInt chainTotal = 0.obs;

  /// §67 — the seat waiting behind the handover card.
  @override
  final Rx<String?> handoverPlayerId = Rx<String?>(null);

  /// §61 — short-lived text over the table.
  @override
  final Rx<String?> banner = Rx<String?>(null);

  /// §23 — reaction bubbles, keyed by player id.
  @override
  final RxMap<String, String> reactions = <String, String>{}.obs;

  /// §36 — set once the round is scored, consumed by the results screen.
  @override
  final Rx<RoundResult?> lastRoundResult = Rx<RoundResult?>(null);

  /// A local match has no clock and no connection to report.
  @override
  final Rx<TableSessionStatus> tableStatus = Rx<TableSessionStatus>(
    TableSessionStatus.offlineLocal,
  );

  /// Set while the pause overlay is up: bots wait, input is refused.
  @override
  final RxBool paused = false.obs;

  @override
  bool get canPause => true;

  @override
  bool get isOnline => false;

  @override
  bool get canDraw => session.canDraw;
  @override
  bool get canEndTurn => session.canEndTurn;
  @override
  bool get mustTakePenalty => session.mustTakePenalty;

  /// Offline, leaving only means keeping the snapshot for "Riprendi".
  @override
  Future<void> abandon() => persistNow();

  final List<TableCue> _queue = [];
  final Map<String, BotStrategy> _bots = {};
  late final VoidCallback _unsubscribe;
  Timer? _saveTimer;
  Timer? _bannerTimer;
  final Map<String, Timer> _reactionTimers = {};
  bool _disposed = false;
  bool _running = false;
  String? _revealedSeat;
  Completer<void>? _unpaused;
  DateTime? _lastReactionAt;

  /// §23 — one reaction every two seconds, the same gap the server applies
  /// online, so the local table cannot be spammed either.
  static const Duration reactionCooldown = Duration(seconds: 2);

  @override
  GameState get state => session.state;
  GameState get round => session.state;
  @override
  GamePlayer get currentPlayer => session.currentPlayer;

  @override
  bool isHumanSeat(String id) => humanIds.contains(id);
  @override
  bool get isHumanTurn => isHumanSeat(currentPlayer.id);

  /// The seat whose hand is face up right now.
  @override
  GamePlayer get viewingPlayer {
    if (state.mode == GameMode.passAndPlay) {
      final id = _revealedSeat;
      if (id != null) {
        final p = state.playerById(id);
        if (p != null) return p;
      }
      return isHumanTurn ? currentPlayer : state.playerById(humanIds.first)!;
    }
    return state.playerById(humanIds.first) ?? state.players.first;
  }

  @override
  List<GamePlayer> get opponents =>
      state.players.where((p) => p.id != viewingPlayer.id).toList();

  @override
  bool get canInteract =>
      !busy.value &&
      !paused.value &&
      handoverPlayerId.value == null &&
      isHumanTurn &&
      round.status == GameStatus.awaitingAction;

  @override
  List<GameCard> get playableForViewer =>
      isHumanTurn ? session.playableCardsFor(currentPlayer) : const [];

  @override
  void onInit() {
    super.onInit();
    _unsubscribe = session.listen(_onEngineEvent);
    for (final p in state.players) {
      if (p.isBot) {
        _bots[p.id] = BotFactory.create(
          p.difficulty ?? BotDifficulty.normal,
          personality: p.personality,
          random: Random(p.id.hashCode ^ state.seed),
        );
      }
    }
    _revealedSeat = state.mode == GameMode.passAndPlay
        ? (isHumanTurn ? currentPlayer.id : humanIds.first)
        : humanIds.first;
    chainTotal.value = round.pendingDrawCount;
    chainLevel.value = round.chainLength;
    // §49 — a snapshot taken while the Suit Ritual was open must reopen it:
    // the Cavallo that asked for a suit is the top of the discard pile.
    if (round.status == GameStatus.awaitingSuitChoice &&
        isHumanSeat(currentPlayer.id)) {
      pendingSuitChoice.value = round.topCard;
    }
  }

  /// Called by the view once it is laid out and able to play cues.
  @override
  void start() {
    if (_running) return;
    _running = true;
    unawaited(_startFlow());
  }

  Future<void> _startFlow() async {
    // A brand-new match (no action applied yet) is dealt in front of the
    // player; a resumed one simply appears where it was left.
    if (state.version == 0 && round.status == GameStatus.awaitingAction) {
      busy.value = true;
      _queueDeal();
      await _drain();
      if (_disposed) return;
    }
    await _resumeFlow();
  }

  void _queueDeal() {
    _queue.add(
      DealCue(
        state.players.where((p) => !p.eliminated).map((p) => p.id).toList(),
        state.rules.startingHandSize,
      ),
    );
  }

  // ------------------------------------------------------------- pausing

  /// Freezes the table. A bot in the middle of "thinking" finishes its
  /// pause and then waits here before acting; cues already queued finish.
  @override
  void pause() {
    if (paused.value || state.isFinished) return;
    paused.value = true;
    _unpaused = Completer<void>();
    revision.value++;
    _persist();
  }

  @override
  void resume() {
    if (!paused.value) return;
    paused.value = false;
    final c = _unpaused;
    _unpaused = null;
    c?.complete();
    revision.value++;
  }

  Future<void> _whilePaused() async {
    while (paused.value && !_disposed) {
      await (_unpaused?.future ?? Future<void>.value());
    }
  }

  @override
  void onClose() {
    _disposed = true;
    _unsubscribe();
    _saveTimer?.cancel();
    _bannerTimer?.cancel();
    for (final t in _reactionTimers.values) {
      t.cancel();
    }
    _reactionTimers.clear();
    super.onClose();
  }

  // ------------------------------------------------------------- engine feed

  void _onEngineEvent(GameEvent event) {
    final cue = TableCues.fromEvent(event, isHumanSeat: isHumanSeat);
    if (cue != null) _queue.add(cue);
    switch (event) {
      case SuitChoiceRequestedEvent():
        pendingSuitChoice.value = event.card;
      case RoundEndedEvent():
        lastRoundResult.value = event.result;
      case CardPlayedEvent():
        // §V — offline mission counters follow the person's own plays.
        if (isHumanSeat(event.playerId)) {
          unawaited(stats.noteCardPlayed(event.card));
        }
      case ChainBlockedEvent():
        if (isHumanSeat(event.playerId)) {
          unawaited(stats.noteChainBlocked());
        }
      default:
        break;
    }
  }

  // ------------------------------------------------------------ human moves

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

  /// §28 — the player tried a card that cannot be played.
  @override
  void rejectCard(GameCard card) {
    HapticService.instance.error();
    AudioService.instance.play(Sfx.invalid);
  }

  @override
  Future<void> playCard(GameCard card) async {
    if (!canInteract) return;
    if (!session.canPlay(card)) {
      HapticService.instance.error();
      AudioService.instance.play(Sfx.invalid);
      _queue.add(InvalidCue(card));
      await _drain();
      return;
    }
    selectedCard.value = null;
    busy.value = true;
    session.playCard(card);
    await _drain();
    await _resumeFlow();
  }

  @override
  Future<void> drawCard() async {
    if (!canInteract || !session.canDraw) return;
    busy.value = true;
    session.drawCard();
    await _drain();
    await _resumeFlow();
  }

  @override
  Future<void> endTurn() async {
    if (!canInteract || !session.canEndTurn) return;
    busy.value = true;
    session.endTurn();
    await _drain();
    await _resumeFlow();
  }

  @override
  Future<void> chooseSuit(CardSuit suit) async {
    if (pendingSuitChoice.value == null) return;
    pendingSuitChoice.value = null;
    busy.value = true;
    AudioService.instance.play(Sfx.suitSelect);
    HapticService.instance.medium();
    session.chooseSuit(suit);
    await _drain();
    await _resumeFlow();
  }

  /// §23 — the player's own reaction.
  @override
  void sendReaction(String phrase) {
    final now = _clock();
    final last = _lastReactionAt;
    if (last != null && now.difference(last) < reactionCooldown) {
      _showBanner(Strings.s.reactionRateLimited);
      return;
    }
    _lastReactionAt = now;
    _showReaction(viewingPlayer.id, phrase);
    HapticService.instance.light();
    AudioService.instance.play(Sfx.click, volume: 0.6);
  }

  /// §67 — the next person has picked the phone up.
  @override
  void confirmHandover() {
    _revealedSeat = handoverPlayerId.value;
    handoverPlayerId.value = null;
    revision.value++;
    unawaited(_resumeFlow());
  }

  // --------------------------------------------------------------- the loop

  /// Advances the table until it is waiting on a person again.
  Future<void> _resumeFlow() async {
    if (_disposed) return;

    while (!_disposed) {
      if (state.isFinished || round.status == GameStatus.roundOver) {
        busy.value = false;
        revision.value++;
        _persist();
        return;
      }

      if (round.status == GameStatus.awaitingSuitChoice) {
        final seat = currentPlayer;
        if (isHumanSeat(seat.id)) {
          // Waiting on the Suit Ritual.
          busy.value = false;
          revision.value++;
          return;
        }
        await _pauseForBot();
        await _whilePaused();
        if (_disposed) return;
        final bot = _bots[seat.id];
        final suit = bot == null
            ? CardSuit.values[_random.nextInt(4)]
            : bot.chooseSuit(BotViewFactory.forCurrentPlayer(session.state));
        AudioService.instance.play(Sfx.suitSelect, volume: 0.8);
        session.chooseSuit(suit);
        await _drain();
        continue;
      }

      final seat = currentPlayer;
      if (isHumanSeat(seat.id)) {
        // §67 — hide the previous player's cards before handing over.
        if (state.mode == GameMode.passAndPlay && _revealedSeat != seat.id) {
          handoverPlayerId.value = seat.id;
          busy.value = false;
          revision.value++;
          _persist();
          return;
        }
        busy.value = false;
        revision.value++;
        _persist();
        _showBanner(Strings.s.yourTurn);
        return;
      }

      busy.value = true;
      revision.value++;
      await _pauseForBot();
      await _whilePaused();
      if (_disposed) return;

      final before = round.turnNumber;
      await _takeBotTurn(seat);
      await _drain();

      // A bot that somehow failed to move must not spin the loop (§52).
      if (round.turnNumber == before &&
          round.status == GameStatus.awaitingAction) {
        if (session.canDraw) {
          session.drawCard();
        } else if (session.canEndTurn) {
          session.endTurn();
        } else {
          debugPrint('Bot turn stalled for ${seat.id}; ending round loop.');
          busy.value = false;
          return;
        }
        await _drain();
      }
    }
  }

  Future<void> _takeBotTurn(GamePlayer seat) async {
    final bot = _bots[seat.id];
    if (bot == null) {
      // Should not happen; keep the table moving rather than stalling.
      if (session.canDraw) {
        session.drawCard();
      } else if (session.canEndTurn) {
        session.endTurn();
      }
      return;
    }

    final view = BotViewFactory.forCurrentPlayer(session.state);
    final decision = bot.decide(view);
    switch (decision.action) {
      case BotAction.play:
        final result = session.playCard(
          decision.card!,
          chosenSuit: decision.suit,
        );
        if (!result.accepted) {
          // A bot proposing an illegal move is a bug, not a stall: fall back.
          if (session.canDraw) {
            session.drawCard();
          } else if (session.canEndTurn) {
            session.endTurn();
          }
          return;
        }
        _maybeBotReaction(seat, decision);
      case BotAction.draw:
        session.drawCard();
        if (round.drawnCard != null) {
          // §8 — a bot that draws something playable uses it straight away.
          await _drain();
          await _pauseForBot(short: true);
          final next = bot.decide(
            BotViewFactory.forCurrentPlayer(session.state),
          );
          if (next.action == BotAction.play && next.card != null) {
            session.playCard(next.card!, chosenSuit: next.suit);
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
  }

  /// §53 — bots pause long enough to feel deliberate, no longer.
  Future<void> _pauseForBot({bool short = false}) async {
    final span =
        AppDurations.botThinkMax.inMilliseconds -
        AppDurations.botThinkMin.inMilliseconds;
    final base =
        AppDurations.botThinkMin.inMilliseconds +
        _random.nextInt(span <= 0 ? 1 : span);
    final ms = short ? (base * 0.5).round() : base;
    await Future<void>.delayed(Motion.scale(Duration(milliseconds: ms)));
  }

  // -------------------------------------------------------------- cue queue

  Future<void> _drain() async {
    while (_queue.isNotEmpty && !_disposed) {
      final cue = _queue.removeAt(0);
      _reactToCue(cue);
      await _present(cue);
    }
    revision.value++;
    _persist();
  }

  Future<void> _present(TableCue cue) async {
    final player = cuePlayer;
    if (player == null) {
      await Future<void>.delayed(Motion.scale(AppDurations.quick));
      return;
    }
    try {
      await player(cue).timeout(const Duration(seconds: 3));
    } on TimeoutException {
      // The view stalled or was torn down; never block the match on it.
    } catch (error) {
      debugPrint('cue failed: $error');
    }
  }

  /// Sound, haptics and the ambient state that ride along with each cue.
  void _reactToCue(TableCue cue) {
    switch (cue) {
      case PlayCardCue():
        AudioService.instance.play(Sfx.cardSlide);
        HapticService.instance.medium();
        if (cue.card.isAce) {
          AudioService.instance.play(Sfx.ace);
          HapticService.instance.strong();
        }
      case DrawCue():
        AudioService.instance.play(
          cue.isPenalty ? Sfx.cardDrop : Sfx.cardPickup,
        );
        HapticService.instance.medium();
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
        HapticService.instance.error();
      case SuitChosenCue():
      case SkipCue():
      case TurnCue():
      case ReactionCue():
        break;
    }
  }

  // ------------------------------------------------------------- decoration

  void _showBanner(String text) {
    banner.value = text;
    _bannerTimer?.cancel();
    _bannerTimer = Timer(Motion.scale(AppDurations.turnBanner), () {
      if (!_disposed) banner.value = null;
    });
  }

  void _showReaction(String playerId, String phrase) {
    reactions[playerId] = phrase;
    _reactionTimers.remove(playerId)?.cancel();
    _reactionTimers[playerId] = Timer(const Duration(milliseconds: 1800), () {
      _reactionTimers.remove(playerId);
      if (_disposed) return;
      if (reactions[playerId] == phrase) reactions.remove(playerId);
    });
  }

  /// §22/§23 — opponents pipe up occasionally, in character.
  void _maybeBotReaction(GamePlayer seat, BotDecision decision) {
    final lines = Strings.s.reactions8;
    final card = decision.card;
    double chance = 0.08;
    String? phrase;

    if (card != null && card.isTwo) {
      chance = 0.42;
      phrase = lines[1]; // Vai!
    } else if (card != null && card.isAce) {
      chance = 0.34;
      phrase = lines[0]; // Bella mossa!
    } else if (seat.hand.length == 1) {
      chance = 0.55;
      phrase = lines[4]; // Tocca a te!
    } else if (seat.hand.length >= 8) {
      chance = 0.25;
      phrase = lines[3]; // Nooo!
    }

    if (seat.personality == BotPersonality.aggressive) chance += 0.12;
    if (seat.personality == BotPersonality.calm) chance -= 0.05;

    if (_random.nextDouble() < chance) {
      _showReaction(seat.id, phrase ?? lines[_random.nextInt(lines.length)]);
    }
  }

  // ------------------------------------------------------------ persistence

  /// §49 — coalesced so a burst of penalty draws writes once.
  void _persist() {
    if (state.isFinished) {
      _saveTimer?.cancel();
      unawaited(storage.clear());
      return;
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), () {
      if (!_disposed) unawaited(storage.save(state));
    });
  }

  /// §49/§50 — force an immediate write, used when leaving the screen or
  /// when the app goes to the background.
  @override
  Future<void> persistNow() async {
    _saveTimer?.cancel();
    if (state.isFinished) {
      await storage.clear();
    } else {
      await storage.save(state);
    }
  }

  // ----------------------------------------------------------- round change

  /// Deals the next round after the results screen is dismissed.
  @override
  Future<void> beginNextRound() async {
    lastRoundResult.value = null;
    chainLevel.value = 0;
    chainTotal.value = 0;
    selectedCard.value = null;
    session.startNextRound();
    _revealedSeat = state.mode == GameMode.passAndPlay
        ? (isHumanTurn ? currentPlayer.id : humanIds.first)
        : humanIds.first;
    _queue.clear();
    AudioService.instance.play(Sfx.shuffle);
    revision.value++;
    _queueDeal();
    await _drain();
    await _resumeFlow();
  }
}
