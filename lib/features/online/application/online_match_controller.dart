import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/log.dart';
import '../../game/domain/engine/game_failure.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/network_banner.dart';
import '../../game/application/table_controller.dart';
import '../../game/application/table_cue.dart';
import '../../game/domain/card_suit.dart';
import '../../game/domain/engine/game_engine.dart';
import '../../game/domain/game_action.dart';
import '../../game/domain/game_card.dart';
import '../../game/domain/game_player.dart';
import '../../game/domain/game_state.dart';
import '../../game/domain/round_result.dart';
import '../../game/domain/table_session_status.dart';
import '../domain/online_match_models.dart';
import 'online_match_repository.dart';

/// Drives one ONLINE match from this seat.
///
/// It never applies a rule. What it holds is the server's redacted state
/// merged with this player's own hand; what it sends are *requests* with an
/// idempotent action id and the version they were built against. The
/// server answers accepted / refused / stale, and every other change
/// reaches this class as a Realtime hint, a poll, or an app-resume — each
/// of which re-reads the authoritative `match_snapshot`. Nothing here
/// assumes an event was received.
class OnlineMatchController extends TableController
    with WidgetsBindingObserver {
  OnlineMatchController({
    required this.repository,
    required this.matchId,
    required MatchSnapshot initial,
    required String userId,
    String Function()? actionIdFactory,
    DateTime Function()? clock,
  }) : _userId = userId, // ignore: prefer_initializing_formals
       _newActionId = actionIdFactory ?? _randomUuid,
       _clock = clock ?? DateTime.now {
    _adoptSnapshot(initial, initialLoad: true);
  }

  static const engine = GameEngine();

  final OnlineMatchRepository repository;
  final String matchId;
  final String _userId;
  final String Function() _newActionId;
  final DateTime Function() _clock;

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
  @override
  final Rx<RoundResult?> lastRoundResult = Rx<RoundResult?>(null);
  @override
  final Rx<TableSessionStatus> tableStatus = Rx<TableSessionStatus>(
    const TableSessionStatus(isOnline: true),
  );

  /// Rematch bookkeeping for the result screen.
  final RxInt rematchVotes = 0.obs;
  final RxInt rematchNeeded = 0.obs;
  final RxBool rematchRequested = false.obs;
  final Rx<String?> nextMatchId = Rx<String?>(null);

  late GameState _state;
  late MatchSnapshot _snapshot;
  int _version = -1;
  late String _myPid;

  MatchSubscription? _subscription;
  Timer? _clockTimer;
  Timer? _heartbeat;
  Timer? _poll;
  Timer? _bannerTimer;
  Timer? _reconnect;
  final Map<String, Timer> _reactionTimers = {};
  final List<TableCue> _queue = [];
  bool _syncing = false;
  bool _dirty = false;
  Completer<void>? _syncDone;
  bool _disposed = false;
  bool _started = false;
  bool _draining = false;
  int _reconnectDelayMs = 1500;
  DateTime? _timeoutClaimedFor;
  Duration _serverSkew = Duration.zero;

  @override
  GameState get state => _state;
  MatchSnapshot get snapshot => _snapshot;
  int get version => _version;
  String get myPlayerId => _myPid;
  String get userId => _userId;

  @override
  GamePlayer get currentPlayer => _state.currentPlayer;

  @override
  List<String> get humanIds => [_myPid];

  @override
  bool get isOnline => true;

  @override
  bool get isHumanTurn =>
      !_state.isFinished && _state.currentPlayerId == _myPid;

  @override
  GamePlayer get viewingPlayer =>
      _state.playerById(_myPid) ?? _state.players.first;

  /// The other seats, in play order starting after this seat, so the felt
  /// is laid out relative to the viewer.
  @override
  List<GamePlayer> get opponents {
    final mine = _state.seatOf(_myPid);
    final n = _state.players.length;
    if (mine < 0) return _state.players.toList();
    return [for (var i = 1; i < n; i++) _state.players[(mine + i) % n]];
  }

  @override
  bool get canInteract =>
      !busy.value &&
      isHumanTurn &&
      _state.status == GameStatus.awaitingAction &&
      _snapshot.isInProgress;

  @override
  List<GameCard> get playableForViewer =>
      isHumanTurn ? engine.getPlayableCards(_state, _myPid) : const [];

  @override
  bool get canDraw => isHumanTurn && engine.canDraw(_state);

  @override
  bool get canEndTurn => isHumanTurn && engine.canPass(_state);

  @override
  bool get mustTakePenalty => isHumanTurn && engine.mustTakePenalty(_state);

  /// The eight preset phrases, in preset order, in the viewer's language.
  List<String> get reactionPhrases => _presetPhrases();

  // --------------------------------------------------------------- lifecycle

  @override
  void onInit() {
    super.onInit();
    Log.d('online-match: onInit $matchId v$_version');
    WidgetsBinding.instance.addObserver(this);
    _subscribe();
    Log.d('online-match: subscribed');
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _heartbeat = Timer.periodic(
      const Duration(seconds: 10),
      (_) => repository.heartbeat(matchId),
    );
    // A slow poll under the Realtime feed: a missed row-change event costs
    // at most this. Six seconds is deliberate — a 15 s turn timer leaves no
    // room for a lazier poll when a Realtime UPDATE goes missing (it does,
    // occasionally, on the free tier), and the headless-Chrome driver lost
    // its seat to three timeouts the one time this was stretched to 18 s.
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => resync());
    unawaited(repository.heartbeat(matchId));
    Log.d('online-match: timers armed');
  }

  @override
  void start() {
    if (_started) return;
    _started = true;
    revision.value++;
    if (isHumanTurn) _showBanner(Strings.s.yourTurn);
    _maybeOpenSuitRitual();
  }

  @override
  void onClose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _heartbeat?.cancel();
    _poll?.cancel();
    _bannerTimer?.cancel();
    _reconnect?.cancel();
    for (final t in _reactionTimers.values) {
      t.cancel();
    }
    unawaited(_subscription?.close());
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App resume: the socket may have died silently. Re-subscribe and
      // re-read the truth before touching anything.
      _resubscribe();
      unawaited(resync());
      unawaited(repository.heartbeat(matchId));
    }
  }

  // ---------------------------------------------------------------- realtime

  /// Which subscription is current. Closing a channel reports `closed`
  /// through the same callback as a real drop; without the generation the
  /// old channel's farewell would re-arm the reconnect and tear down the
  /// healthy new one, forever.
  int _subscriptionGeneration = 0;

  void _subscribe() {
    final generation = ++_subscriptionGeneration;
    _subscription = repository.subscribe(
      matchId,
      onStateChanged: (v) {
        if (generation != _subscriptionGeneration) return;
        if (v < 0 || v > _version) unawaited(resync());
      },
      onReaction: (m) {
        if (generation == _subscriptionGeneration) _onReaction(m);
      },
      onStatus: (s) {
        if (generation == _subscriptionGeneration) _onChannelStatus(s);
      },
    );
  }

  void _resubscribe() {
    final old = _subscription;
    _subscription = null;
    _subscriptionGeneration++; // the old channel's callbacks fall silent
    unawaited(old?.close());
    if (!_disposed) _subscribe();
  }

  void _onChannelStatus(MatchChannelStatus status) {
    Log.d('online-match: channel $status');
    if (_disposed) return;
    switch (status) {
      case MatchChannelStatus.connected:
        _reconnectDelayMs = 1500;
        _reconnect?.cancel();
        _reconnect = null;
        _setConnection(NetworkStatus.online);
        unawaited(resync());
      case MatchChannelStatus.connecting:
        _setConnection(NetworkStatus.connecting);
      case MatchChannelStatus.disconnected:
        _setConnection(NetworkStatus.connecting);
        _reconnect?.cancel();
        _reconnect = Timer(Duration(milliseconds: _reconnectDelayMs), () {
          _reconnectDelayMs = min(_reconnectDelayMs * 2, 15000);
          _resubscribe();
        });
    }
  }

  void _setConnection(NetworkStatus s) {
    final t = tableStatus.value;
    tableStatus.value = TableSessionStatus(
      isOnline: true,
      connection: s,
      turnSecondsRemaining: t.turnSecondsRemaining,
      turnSecondsTotal: t.turnSecondsTotal,
    );
  }

  // ------------------------------------------------------------------- sync

  /// Re-reads the authoritative snapshot. Coalesced: a call during a fetch
  /// schedules one more fetch after it, never a pile-up.
  Future<void> resync() async {
    if (_disposed) return;
    if (_syncing) {
      // Fold into the running loop, but still let the caller wait for the
      // read that will follow.
      _dirty = true;
      return _syncDone?.future;
    }
    _syncing = true;
    final done = _syncDone = Completer<void>();
    try {
      do {
        _dirty = false;
        try {
          final snap = await repository.snapshot(matchId);
          if (_disposed) return;
          _adoptSnapshot(snap);
          if (tableStatus.value.connection != NetworkStatus.online &&
              _subscription != null) {
            // Data flows again even if the socket is still catching up.
            _setConnection(NetworkStatus.online);
          }
        } on OnlineException catch (e) {
          if (e.error == OnlineError.network) {
            _setConnection(NetworkStatus.connecting);
          }
        }
      } while (_dirty && !_disposed);
    } finally {
      _syncing = false;
      _syncDone = null;
      done.complete();
    }
  }

  void _adoptSnapshot(MatchSnapshot snap, {bool initialLoad = false}) {
    _snapshot = snap;
    _serverSkew = snap.serverNow.difference(_clock().toUtc());
    final seat = snap.seatOf(_userId);
    _myPid = seat?.enginePlayerId ?? _state.players.first.id;
    final view = snap.viewFor(_userId);
    if (initialLoad) {
      _state = view;
      _version = snap.version;
      chainTotal.value = view.pendingDrawCount;
      chainLevel.value = view.chainLength;
      _refreshClock();
      return;
    }
    if (snap.version < _version) {
      return; // an older read overtaken by a newer one
    }
    _applyNewState(view, snap.version, events: null);
  }

  /// The one path every new state goes through, whether it came from an
  /// action reply, a Realtime hint, a poll or a resume.
  void _applyNewState(
    GameState next,
    int version, {
    required List<String>? events,
  }) {
    final previous = _state;
    final previousVersion = _version;
    _state = next;
    _version = version;

    if (version > previousVersion) {
      // Only animate a single step; a gap means we missed something and
      // the honest thing is to simply show where the table is now.
      if (version == previousVersion + 1) {
        _queueCuesFor(previous, next);
      } else {
        _queue.clear();
        chainTotal.value = next.pendingDrawCount;
        chainLevel.value = next.chainLength;
      }
      _maybeAnnounce(previous, next);
    }
    if (next.isRoundOver) {
      lastRoundResult.value = next.lastRoundResult;
    } else if (lastRoundResult.value != null) {
      // A new round was dealt (by us or by the server): the results sheet
      // closes itself when it sees this.
      lastRoundResult.value = null;
    }
    _refreshClock();
    revision.value++;
    unawaited(_drain());
    _maybeOpenSuitRitual();
    _maybeFinish();
  }

  void _maybeOpenSuitRitual() {
    if (_state.status == GameStatus.awaitingSuitChoice && isHumanTurn) {
      pendingSuitChoice.value ??= _state.topCard;
    } else {
      pendingSuitChoice.value = null;
    }
  }

  bool _navigatedToResult = false;

  void _maybeFinish() {
    if (_state.isFinished) {
      // Nothing left to time or to poll; the result screen asks for the
      // rematch votes itself.
      _clockTimer?.cancel();
      _poll?.cancel();
      _heartbeat?.cancel();
    }
    if (!_state.isFinished || _navigatedToResult) return;
    if (_state.lastRoundResult != null) {
      return; // the round-result sheet carries the player to the result
    }
    // Finished without a scored round (forfeit / abandonment).
    _navigatedToResult = true;
    if (Get.currentRoute == AppRoutes.game) {
      Get.offNamed<void>(AppRoutes.matchResult);
    }
  }

  // ------------------------------------------------------------------ cues

  void _queueCuesFor(GameState before, GameState after) {
    final action = after.lastAction;
    final actorId = action?.playerId ?? '';
    switch (action) {
      case PlayCardAction(:final card, :final chosenSuit):
        if (after.drawPileCount > before.drawPileCount) {
          _queue.add(RecycleCue(after.drawPileCount));
        }
        _queue.add(PlayCardCue(actorId, card));
        if (card.isDue && after.pendingDrawCount > before.pendingDrawCount) {
          _queue.add(ChainGrowCue(after.pendingDrawCount, after.chainLength));
        } else if (card.isCavallo && before.isPenaltyPending) {
          _queue.add(
            ChainBreakCue(actorId, before.pendingDrawCount, before.chainLength),
          );
        }
        if (card.isAsso && !after.isRoundOver) {
          final n = before.players.length;
          var seat = before.seatOf(actorId);
          var moved = 0;
          while (moved < 1 && n > 0) {
            seat = (seat + 1) % n;
            if (!before.players[seat].eliminated) moved++;
          }
          _queue.add(SkipCue(before.players[seat].id));
        }
        if (chosenSuit != null) {
          _queue.add(SuitChosenCue(actorId, chosenSuit));
        }
      case DrawCardAction():
        if (after.drawPileCount > before.drawPileCount) {
          _queue.add(RecycleCue(after.drawPileCount));
        }
        final drawn = _cardsDrawn(before, after, actorId);
        if (drawn.isNotEmpty) {
          _queue.add(
            DrawCue(actorId, drawn, isPenalty: before.isPenaltyPending),
          );
        }
        if (before.isPenaltyPending && !after.isPenaltyPending) {
          _queue.add(
            ChainBreakCue(actorId, before.pendingDrawCount, before.chainLength),
          );
        }
      case ChooseSuitAction(:final suit):
        _queue.add(SuitChosenCue(actorId, suit));
      case PassAction():
      case StartNextRoundAction():
        break;
      case ForfeitAction():
        chainTotal.value = after.pendingDrawCount;
        chainLevel.value = after.chainLength;
      case null:
        break;
    }
    if (after.currentPlayerId != before.currentPlayerId ||
        after.round != before.round) {
      _queue.add(
        TurnCue(
          after.currentPlayerId,
          isHuman: isHumanSeat(after.currentPlayerId),
        ),
      );
    }
  }

  /// The cards a seat gained: real ones for the viewer, face-down stand-ins
  /// for anyone else (their identity is not ours to know).
  List<GameCard> _cardsDrawn(GameState before, GameState after, String pid) {
    final b = before.playerById(pid);
    final a = after.playerById(pid);
    if (a == null || b == null) return const [];
    if (pid == _myPid) {
      final had = b.hand.toSet();
      return a.hand.where((c) => !had.contains(c)).toList();
    }
    final gained = a.cardCount - b.cardCount;
    if (gained <= 0) return const [];
    final visible = {...after.discardPile, ...viewingPlayer.hand};
    return Deck.standard
        .where((c) => !visible.contains(c))
        .take(gained)
        .toList();
  }

  void _maybeAnnounce(GameState before, GameState after) {
    final action = after.lastAction;
    if (action is ForfeitAction) {
      final who = after.playerById(action.playerId);
      if (who != null && action.playerId != _myPid) {
        _showBanner(Strings.s.onlineOpponentLeft(who.name));
      }
      return;
    }
    if (after.currentPlayerId == _myPid &&
        before.currentPlayerId != _myPid &&
        !after.isRoundOver) {
      _showBanner(Strings.s.yourTurn);
    }
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty && !_disposed) {
        final cue = _queue.removeAt(0);
        _reactToCue(cue);
        final player = cuePlayer;
        if (player == null) continue;
        try {
          await player(cue).timeout(const Duration(seconds: 3));
        } catch (_) {
          // The view stalled or was torn down; never block the table on it.
        }
      }
    } finally {
      _draining = false;
      revision.value++;
    }
  }

  void _reactToCue(TableCue cue) {
    switch (cue) {
      case PlayCardCue():
        AudioService.instance.play(Sfx.cardSlide);
        if (cue.card.isAce) AudioService.instance.play(Sfx.ace);
        if (cue.playerId != _myPid) HapticService.instance.light();
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
        HapticService.instance.error();
      case SuitChosenCue():
      case SkipCue():
      case TurnCue():
      case ReactionCue():
        break;
    }
  }

  // ----------------------------------------------------------------- clock

  DateTime get _serverNow => _clock().toUtc().add(_serverSkew);

  int _ticks = 0;

  void _tick() {
    if (_disposed) return;
    if (_ticks++ % 60 == 0) {
      Log.d(
        'online-match: tick $_ticks v$_version deadline=${_snapshot.turnDeadlineAt}',
      );
    }
    _refreshClock();
    _maybeClaimTimeout();
  }

  void _refreshClock() {
    final deadline = _snapshot.turnDeadlineAt;
    final total = _state.isRoundOver ? 30 : _snapshot.turnTimerSeconds;
    if (deadline == null || total <= 0 || !_snapshot.isInProgress) {
      tableStatus.value = TableSessionStatus(
        isOnline: true,
        connection: tableStatus.value.connection,
      );
      return;
    }
    final remaining = deadline.difference(_serverNow).inSeconds;
    tableStatus.value = TableSessionStatus(
      isOnline: true,
      connection: tableStatus.value.connection,
      turnSecondsRemaining: remaining.clamp(0, total),
      turnSecondsTotal: total,
    );
  }

  /// Once the server's deadline has passed, any seat may ask the server to
  /// move for the idle one. The server checks its own clock; this is a nudge.
  void _maybeClaimTimeout() {
    final deadline = _snapshot.turnDeadlineAt;
    if (deadline == null || !_snapshot.isInProgress) return;
    if (_serverNow.isBefore(deadline.add(const Duration(seconds: 1)))) return;
    if (_timeoutClaimedFor == deadline) return;
    _timeoutClaimedFor = deadline;
    unawaited(() async {
      try {
        final r = await repository.claimTimeout(matchId);
        if (r.accepted || r.isStale || r.failure == 'deadlineNotReached') {
          await resync();
        }
      } on OnlineException {
        // Somebody else claimed it, or we are offline: the poll will tell.
      }
    }());
  }

  // ---------------------------------------------------------------- moves

  Future<bool> _send(
    String type, {
    GameCard? card,
    CardSuit? chosenSuit,
    CardSuit? suit,
  }) async {
    Log.d('online-match: send $type v$_version');
    if (_disposed) return false;
    busy.value = true;
    revision.value++;
    try {
      final outcome = await repository.send(
        MatchActionRequest(
          matchId: matchId,
          actionId: _newActionId(),
          expectedVersion: _version,
          type: type,
          card: card,
          chosenSuit: chosenSuit,
          suit: suit,
        ),
      );
      if (_disposed) return false;
      if (outcome.accepted) {
        final publicState = outcome.publicState;
        if (publicState != null && outcome.version > _version) {
          final me = publicState.playerById(_myPid);
          final view = me == null || outcome.hand == null
              ? publicState
              : publicState.withPlayer(me.copyWith(hand: outcome.hand));
          _snapshot = _snapshotWith(
            version: outcome.version,
            status: outcome.status,
            deadline: outcome.turnDeadlineAt,
          );
          _applyNewState(view, outcome.version, events: outcome.events);
        } else if (outcome.duplicate) {
          await resync();
        }
        return true;
      }
      if (outcome.isStale) {
        _showBanner(Strings.s.onlineMoveStale);
        await resync();
        return false;
      }
      _queue.add(InvalidCue(card ?? _state.topCard));
      _showBanner(
        outcome.failure == GameFailure.notPlayersTurn.key
            ? Strings.s.onlineNotYourTurn
            : Strings.s.onlineMoveRefused,
      );
      unawaited(_drain());
      // The server knows better than our view: re-read it.
      await resync();
      return false;
    } on OnlineException catch (e) {
      if (e.error == OnlineError.network) {
        _setConnection(NetworkStatus.connecting);
        _showBanner(Strings.s.onlineDisconnected);
      } else {
        _showBanner(Strings.s.onlineMoveRefused);
      }
      await resync();
      return false;
    } finally {
      if (!_disposed) {
        busy.value = false;
        revision.value++;
      }
    }
  }

  MatchSnapshot _snapshotWith({
    required int version,
    String? status,
    DateTime? deadline,
  }) => MatchSnapshot(
    matchId: _snapshot.matchId,
    roomId: _snapshot.roomId,
    status: status == 'finished' ? 'finished' : _snapshot.status,
    version: version,
    publicState: _snapshot.publicState,
    hand: _snapshot.hand,
    seats: _snapshot.seats,
    serverNow: _snapshot.serverNow,
    winnerUserId: _snapshot.winnerUserId,
    currentUserId: _snapshot.currentUserId,
    turnTimerSeconds: _snapshot.turnTimerSeconds,
    turnStartedAt: _serverNow,
    turnDeadlineAt: deadline,
    drawnCard: _snapshot.drawnCard,
    abandonedBy: _snapshot.abandonedBy,
    rematchOf: _snapshot.rematchOf,
  );

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
  }

  @override
  Future<void> playCard(GameCard card) async {
    if (!canInteract) return;
    // Instant feedback from the same engine the server runs; the server
    // still has the last word.
    final failure = engine.validateAction(
      _state,
      PlayCardAction(playerId: _myPid, card: card),
    );
    if (failure != null) {
      rejectCard(card);
      _queue.add(InvalidCue(card));
      unawaited(_drain());
      return;
    }
    selectedCard.value = null;
    await _send('playCard', card: card);
  }

  @override
  Future<void> drawCard() async {
    Log.d(
      'online-match: drawCard tap canInteract=$canInteract canDraw=$canDraw '
      'busy=${busy.value} turn=$isHumanTurn status=${_state.status.key} '
      'v$_version',
    );
    if (!canInteract || !canDraw) return;
    await _send('drawCard');
  }

  @override
  Future<void> endTurn() async {
    if (!canInteract || !canEndTurn) return;
    await _send('pass');
  }

  @override
  Future<void> chooseSuit(CardSuit suit) async {
    if (pendingSuitChoice.value == null || busy.value) return;
    pendingSuitChoice.value = null;
    AudioService.instance.play(Sfx.suitSelect);
    HapticService.instance.medium();
    final ok = await _send('chooseSuit', suit: suit);
    if (!ok) _maybeOpenSuitRitual();
  }

  @override
  Future<void> beginNextRound() async {
    if (busy.value) return;
    chainLevel.value = 0;
    chainTotal.value = 0;
    selectedCard.value = null;
    if (_state.status != GameStatus.roundOver) return;
    // Any seat may deal; the first request wins and the rest see it arrive.
    await _send('startNextRound');
  }

  @override
  void confirmHandover() {}

  @override
  Future<void> persistNow() async {}

  /// Leaving an online table is a forfeit — the server records it and the
  /// others are told; there is no "resume" for the seat that walked away.
  @override
  Future<void> abandon() async {
    if (!_snapshot.isInProgress) return;
    try {
      await repository.forfeit(matchId);
    } on OnlineException {
      // Best effort: the abandonment policy finishes the job server-side.
    }
  }

  // ------------------------------------------------------------- reactions

  @override
  void sendReaction(String phrase) {
    final index = reactionPhrases.indexOf(phrase);
    if (index < 0) return;
    final key = ReactionMessage.presetKeys[index];
    _showReaction(_myPid, phrase);
    HapticService.instance.light();
    AudioService.instance.play(Sfx.click, volume: 0.6);
    unawaited(() async {
      try {
        await repository.sendReaction(matchId, key);
      } on OnlineException catch (e) {
        if (e.error == OnlineError.rateLimited) {
          _showBanner(Strings.s.reactionRateLimited);
        }
      }
    }());
  }

  void _onReaction(ReactionMessage message) {
    if (message.userId == _userId) return; // already shown locally
    final index = ReactionMessage.presetKeys.indexOf(message.key);
    if (index < 0) return; // not a preset: the server never sends one, but…
    final seat = _snapshot.seatOf(message.userId);
    if (seat == null) return;
    _showReaction(seat.enginePlayerId, reactionPhrases[index]);
  }

  void _showReaction(String playerId, String phrase) {
    reactions[playerId] = phrase;
    _reactionTimers.remove(playerId)?.cancel();
    _reactionTimers[playerId] = Timer(const Duration(milliseconds: 2200), () {
      _reactionTimers.remove(playerId);
      if (_disposed) return;
      if (reactions[playerId] == phrase) reactions.remove(playerId);
    });
  }

  static List<String> _presetPhrases() {
    final s = Strings.s;
    return [
      s.reactionCiao,
      s.reactionBravo,
      s.reactionBellaMossa,
      s.reactionMammaMia,
      s.reactionAhahaha,
      s.reactionCheFortuna,
      s.reactionRivincita,
      s.reactionGg,
    ];
  }

  // --------------------------------------------------------------- rematch

  /// Votes for a rematch. When every seat still in the room has voted the
  /// server deals a fresh match and [nextMatchId] is set.
  Future<void> requestRematch() async {
    if (rematchRequested.value && nextMatchId.value != null) return;
    try {
      final r = await repository.requestRematch(matchId);
      rematchRequested.value = true;
      rematchVotes.value = r.votes;
      rematchNeeded.value = r.needed;
      if (r.started && r.matchId != null) nextMatchId.value = r.matchId;
    } on OnlineException catch (e) {
      _showBanner(
        e.error == OnlineError.notParticipant
            ? Strings.s.onlineMatchAbandoned
            : Strings.s.onlineMoveRefused,
      );
    }
  }

  /// Called by the result screen while waiting: re-reads the seats' votes
  /// and learns about a rematch dealt by the last voter.
  Future<void> pollRematch() async {
    if (nextMatchId.value != null) return;
    try {
      final snap = await repository.snapshot(matchId);
      _snapshot = snap;
      final votes = snap.seats.where((s) => s.wantsRematch).length;
      rematchVotes.value = votes;
      rematchNeeded.value = snap.seats.where((s) => !s.hasForfeited).length;
      if (snap.roomId != null) {
        final next = await repository.currentMatchOfRoom(snap.roomId!);
        if (next != null && next != matchId) nextMatchId.value = next;
      }
    } on OnlineException {
      // Try again on the next poll.
    }
  }

  // ------------------------------------------------------------ decoration

  void _showBanner(String text) {
    banner.value = text;
    _bannerTimer?.cancel();
    _bannerTimer = Timer(Motion.scale(AppDurations.turnBanner), () {
      if (!_disposed) banner.value = null;
    });
  }
}

final Random _uuidRandom = Random.secure();

String _randomUuid() {
  final b = List<int>.generate(16, (_) => _uuidRandom.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}
