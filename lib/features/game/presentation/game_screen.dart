import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/router/app_router.dart';
import '../application/table_controller.dart';
import '../../online/application/online_match_controller.dart';
import '../../online/application/online_match_launcher.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../settings/application/settings_controller.dart';
import '../application/table_cue.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/motion.dart';
import '../../../app/localization/app_strings.dart';
import '../domain/game_card.dart';
import '../domain/game_player.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/icon_pill.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/network_banner.dart';
import '../domain/table_session_status.dart';
import 'widgets/turn_timer_ring.dart';
import 'widgets/card_flight.dart';
import 'widgets/chain_storm.dart';
import 'widgets/coach_mark.dart';
import 'widgets/hand_fan.dart';
import 'widgets/handover_overlay.dart';
import 'widgets/reaction_bar.dart';
import 'widgets/seat_view.dart';
import 'widgets/suit_ritual.dart';
import 'widgets/table_piles.dart';
import 'widgets/table_surface.dart';
import 'exit_dialog.dart';

/// §27 Screen 4 — the table. Everything else in the game exists to get here.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final TableController c = Get.find<TableController>();
  final SettingsController settings = Get.find<SettingsController>();

  final GlobalKey _rootKey = GlobalKey();
  final GlobalKey _drawKey = GlobalKey();
  final GlobalKey _discardKey = GlobalKey();
  final GlobalKey _handKey = GlobalKey();
  final Map<String, GlobalKey> _seatKeys = {};

  final List<CardFlight> _flights = [];
  final Set<String> _hidden = <String>{};
  int _flightId = 0;

  String? _skippedSeat;
  bool _reactionsOpen = false;
  bool _navigatedToResult = false;
  Worker? _resultWorker;

  /// §65 — first-run tips, one at a time.
  final List<(String, AppIcon, String)> _coachQueue = [];
  (String, AppIcon, String)? _coach;

  @override
  void initState() {
    super.initState();
    c.cuePlayer = _playCue;
    for (final p in c.state.players) {
      _seatKeys[p.id] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _queueCoachMarks();
      c.start();
    });
    _resultWorker = ever<dynamic>(c.lastRoundResult, (result) {
      if (!mounted) return;
      if (result == null) {
        // A new round has been dealt: arm the guard again.
        _navigatedToResult = false;
        return;
      }
      if (_navigatedToResult) return;
      _navigatedToResult = true;
      Future<void>.delayed(Motion.scale(const Duration(milliseconds: 520)), () {
        if (mounted) Get.toNamed<void>(AppRoutes.roundResult);
      });
    });
  }

  @override
  void dispose() {
    _resultWorker?.dispose();
    c.cuePlayer = null;
    for (final f in _flights) {
      f.controller.dispose();
    }
    super.dispose();
  }

  void _queueCoachMarks() {
    final s = Strings.s;
    for (final tip in [
      ('coach_match', AppIcon.cards, s.coachMatch),
      ('coach_draw', AppIcon.draw, s.coachDraw),
      ('coach_specials', AppIcon.suits, s.coachSpecials),
      ('coach_ring', AppIcon.ring, s.coachFateRing),
    ]) {
      if (!settings.hasSeenCoachMark(tip.$1)) _coachQueue.add(tip);
    }
    _nextCoachMark();
  }

  void _nextCoachMark() {
    if (_coachQueue.isEmpty) {
      if (mounted) setState(() => _coach = null);
      return;
    }
    setState(() => _coach = _coachQueue.removeAt(0));
  }

  // -------------------------------------------------------------- geometry

  Offset? _centreOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final root = _rootKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || root == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero), ancestor: root);
  }

  Offset _seatCentre(String playerId) {
    if (playerId == c.viewingPlayer.id) {
      return _centreOf(_handKey) ??
          Offset(
            MediaQuery.sizeOf(context).width / 2,
            MediaQuery.sizeOf(context).height * 0.85,
          );
    }
    final key = _seatKeys[playerId];
    return (key == null ? null : _centreOf(key)) ??
        Offset(MediaQuery.sizeOf(context).width / 2, 90);
  }

  double get _handCardWidth {
    final width = MediaQuery.sizeOf(context).width;
    final base = settings.settings.largeCardMode ? 0.235 : 0.20;
    return (width * base).clamp(52.0, 104.0);
  }

  double get _tableCardWidth {
    final width = MediaQuery.sizeOf(context).width;
    return (width * 0.205).clamp(54.0, 96.0);
  }

  double get _opponentCardWidth => (_tableCardWidth * 0.42).clamp(20.0, 40.0);

  // ----------------------------------------------------------- cue playback

  Future<void> _playCue(TableCue cue) async {
    if (!mounted) return;
    switch (cue) {
      case PlayCardCue():
        await _animatePlay(cue.playerId, cue.card);
      case DrawCue():
        await _animateDraw(cue.playerId, cue.cards, cue.isPenalty);
      case SkipCue():
        setState(() => _skippedSeat = cue.playerId);
        await Future<void>.delayed(Motion.scale(AppDurations.aceFlash));
        if (mounted) setState(() => _skippedSeat = null);
      case ChainGrowCue():
        await Future<void>.delayed(Motion.scale(AppDurations.chainPulse));
      case ChainBreakCue():
        await Future<void>.delayed(Motion.scale(AppDurations.quick));
      case RecycleCue():
        await _animateRecycle(cue.count);
      case InvalidCue():
        await Future<void>.delayed(Motion.scale(AppDurations.micro));
      case SuitChosenCue():
        await Future<void>.delayed(Motion.scale(AppDurations.ambientShift));
      case TurnCue():
      case ReactionCue():
        setState(() {});
    }
  }

  Future<void> _animatePlay(String playerId, GameCard card) async {
    final from = _seatCentre(playerId);
    final to = _centreOf(_discardKey);
    if (to == null) return;

    final isViewer = playerId == c.viewingPlayer.id;
    // Hide the card at its destination until the flight lands (§29).
    setState(() => _hidden.add(card.id));

    await _fly(
      card: card,
      from: from,
      to: to,
      width: isViewer ? _handCardWidth : _tableCardWidth * 0.8,
      startFaceUp: isViewer,
      endFaceUp: true,
      startAngle: isViewer ? 0 : (from.dx < to.dx ? 0.25 : -0.25),
      endAngle: (math.Random(card.id.hashCode).nextDouble() - 0.5) * 0.22,
      duration: AppDurations.cardPlay,
    );

    if (mounted) setState(() => _hidden.remove(card.id));
  }

  Future<void> _animateDraw(
    String playerId,
    List<GameCard> cards,
    bool isPenalty,
  ) async {
    if (cards.isEmpty) return;
    final from = _centreOf(_drawKey);
    final to = _seatCentre(playerId);
    if (from == null) return;

    final isViewer = playerId == c.viewingPlayer.id;
    // A long penalty animates a few cards and tops the rest up instantly, so
    // taking +8 never turns into a wait (§30).
    const maxAnimated = 4;
    final animated = cards.take(maxAnimated).toList();

    setState(() => _hidden.addAll(animated.map((e) => e.id)));

    final futures = <Future<void>>[];
    for (var i = 0; i < animated.length; i++) {
      if (i > 0) {
        await Future<void>.delayed(Motion.scale(AppDurations.penaltyStagger));
      }
      futures.add(
        _fly(
          card: animated[i],
          from: from,
          to: to,
          width: isViewer ? _handCardWidth * 0.92 : _opponentCardWidth * 1.6,
          startFaceUp: false,
          endFaceUp: isViewer,
          startAngle: 0,
          endAngle: isViewer ? 0 : 0.1,
          duration: AppDurations.cardDraw,
        ),
      );
    }
    await Future.wait(futures);
    if (mounted) {
      setState(() => _hidden.removeAll(animated.map((e) => e.id)));
    }
  }

  /// §18 — the discard sweeping back under the stock. A handful of cards
  /// stand in for the whole pile: enough to read as a shuffle, short enough
  /// not to stall the turn.
  Future<void> _animateRecycle(int count) async {
    final from = _centreOf(_discardKey);
    final to = _centreOf(_drawKey);
    if (from == null || to == null) {
      await Future<void>.delayed(Motion.scale(AppDurations.cardPlay));
      return;
    }
    final shown = math.min(5, math.max(2, count));
    final futures = <Future<void>>[];
    for (var i = 0; i < shown; i++) {
      if (i > 0) {
        await Future<void>.delayed(Motion.scale(AppDurations.penaltyStagger));
      }
      futures.add(
        _fly(
          card: c.state.topCard,
          from: from,
          to: to,
          width: _tableCardWidth,
          startFaceUp: false,
          endFaceUp: false,
          startAngle: (i.isEven ? 1 : -1) * (0.18 + i * 0.06),
          endAngle: 0,
          duration: AppDurations.cardDraw,
        ),
      );
    }
    await Future.wait(futures);
  }

  Future<void> _fly({
    required GameCard card,
    required Offset from,
    required Offset to,
    required double width,
    required bool startFaceUp,
    required bool endFaceUp,
    required double startAngle,
    required double endAngle,
    required Duration duration,
  }) async {
    final controller = AnimationController(
      vsync: this,
      duration: Motion.scale(duration),
    );
    final flight = CardFlight(
      id: _flightId++,
      card: card,
      from: from,
      to: to,
      controller: controller,
      width: width,
      startFaceUp: startFaceUp,
      endFaceUp: endFaceUp,
      backId: settings.settings.cardBackId,
      startAngle: startAngle,
      endAngle: endAngle,
      highContrast: settings.settings.highContrast,
    );
    setState(() => _flights.add(flight));
    await controller.forward();
    if (mounted) {
      setState(() => _flights.remove(flight));
    } else {
      _flights.remove(flight);
    }
    controller.dispose();
  }

  // ------------------------------------------------------------------- exit

  Future<void> _confirmExit() async {
    final bool leave;
    if (c.isOnline) {
      // Online, walking away is a forfeit: say so plainly.
      final s = Strings.s;
      leave = await AppDialog.confirm(
        title: s.onlineForfeitTitle,
        body: s.onlineForfeitBody,
        confirmLabel: s.onlineForfeit,
        cancelLabel: s.cancel,
        destructive: true,
      );
    } else {
      leave =
          await showExitDialog(context, accent: settings.theme.accent) == true;
    }
    if (!leave) return;
    await c.abandon();
    Get.until((route) => route.settings.name == AppRoutes.home);
    if (c.isOnline) OnlineMatchLauncher.dismiss();
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Obx(() {
        // Touching `revision` is what subscribes this screen to engine changes.
        c.revision.value;
        final theme = settings.theme;
        final viewer = c.viewingPlayer;
        final opponents = c.opponents;

        return Scaffold(
          backgroundColor: theme.backdropTop,
          body: Stack(
            key: _rootKey,
            // Expand explicitly: the flight and banner layers collapse to
            // nothing when idle, and a loose Stack would size itself to them
            // and take the whole table down with it.
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: AppBackground(
                  theme: theme,
                  motifStrength: 0.55,
                  child: SafeArea(
                    child: Column(
                      children: [
                        _topBar(theme.accent),
                        Expanded(child: _table(opponents, theme.accent)),
                        _playerStrip(viewer, theme.accent),
                        _actionRow(theme.accent),
                        _hand(viewer),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: CardFlightLayer(flights: _flights)),
              Positioned.fill(child: _bannerLayer()),
              if (c.pendingSuitChoice.value != null && c.isHumanTurn)
                Positioned.fill(
                  child: SuitRitual(
                    card: c.pendingSuitChoice.value!,
                    cardWidth: _tableCardWidth,
                    onChosen: c.chooseSuit,
                  ),
                ),
              if (_reactionsOpen)
                Positioned.fill(
                  child: ReactionSheet(
                    accent: theme.accent,
                    phrases: switch (c) {
                      final OnlineMatchController online =>
                        online.reactionPhrases,
                      _ => null,
                    },
                    onDismiss: () => setState(() => _reactionsOpen = false),
                    onPick: (phrase) {
                      c.sendReaction(phrase);
                      setState(() => _reactionsOpen = false);
                    },
                  ),
                ),
              if (c.handoverPlayerId.value != null)
                Positioned.fill(
                  child: HandoverOverlay(
                    playerName:
                        c.state.playerById(c.handoverPlayerId.value!)?.name ??
                        '',
                    avatarId:
                        c.state
                            .playerById(c.handoverPlayerId.value!)
                            ?.avatarId ??
                        'lucia',
                    backId: settings.settings.cardBackId,
                    accent: theme.accent,
                    onReady: c.confirmHandover,
                  ),
                ),
              if (_coach != null && c.handoverPlayerId.value == null)
                Positioned.fill(
                  child: CoachMark(
                    icon: _coach!.$2,
                    message: _coach!.$3,
                    accent: theme.accent,
                    onDismiss: () {
                      settings.markCoachMarkSeen(_coach!.$1);
                      _nextCoachMark();
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  /// §M — timer and connection come from the driver: a local match reports
  /// neither; an online one reports the server's deadline and the socket.
  TableSessionStatus get _session => c.tableStatus.value;

  Widget _topBar(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          IconPill(icon: AppIcon.back, size: 38, onTap: _confirmExit),
          // §M — the rules reference, reachable without leaving the match.
          const SizedBox(width: AppSpacing.xs),
          IconPill(
            icon: AppIcon.rules,
            size: 38,
            tooltip: Strings.s.tableRules,
            onTap: () => Get.toNamed<void>(AppRoutes.howToPlay),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                '${Strings.s.round} ${c.state.round}',
                style: AppText.label.copyWith(letterSpacing: 2),
              ),
              if (c.state.isDailyChallenge)
                Text(
                  Strings.s.dailyChallenge,
                  style: AppText.caption.copyWith(fontSize: 9, color: accent),
                ),
            ],
          ),
          const Spacer(),
          // §M — turn timer and connection state. Both come from the session
          // status; an offline match produces neither, so nothing is drawn.
          if (_session.hasTimer) ...[
            TurnTimerRing(
              progress: _session.timerProgress,
              secondsRemaining: _session.turnSecondsRemaining!,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          if (_session.showsConnection) ...[
            _ConnectionDot(status: _session.connection),
            const SizedBox(width: AppSpacing.xs),
          ],
          IconPill(
            icon: AppIcon.reactions,
            size: 38,
            accent: accent,
            onTap: () => setState(() => _reactionsOpen = true),
          ),
        ],
      ),
    );
  }

  /// Seats around the felt, plus the two piles at its centre.
  Widget _table(List<GamePlayer> opponents, Color accent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final positions = _seatPositions(opponents.length);
        final angles = _seatAngles(opponents.length);
        final activeIndex = _activeSeatIndex(opponents);

        return Stack(
          children: [
            Positioned.fill(
              child: TableSurface(
                theme: settings.theme,
                activeSuit: c.state.activeSuit,
                intensity: c.busy.value ? 0.75 : 1.0,
              ),
            ),
            Positioned.fill(
              child: DirectionRing(
                seatAngles: angles,
                activeIndex: activeIndex,
                accent: accent,
              ),
            ),
            for (var i = 0; i < opponents.length; i++)
              Align(
                alignment: positions[i],
                child: KeyedSubtree(
                  key: _seatKeys[opponents[i].id],
                  child: OpponentSeat(
                    player: opponents[i],
                    isActive: c.currentPlayer.id == opponents[i].id,
                    cardWidth: _opponentCardWidth,
                    backId: settings.settings.cardBackId,
                    targetScore: c.state.rules.targetScore,
                    accent: accent,
                    compact: opponents.length > 2,
                    skipped: _skippedSeat == opponents[i].id,
                    reaction: c.reactions[opponents[i].id],
                  ),
                ),
              ),
            Align(
              // Slightly above the middle of the felt: it leaves the lower
              // arc clear for the direction ring and the turn banner.
              alignment: const Alignment(0, 0.14),
              child: _centrePiles(accent),
            ),
          ],
        );
      },
    );
  }

  Widget _centrePiles(Color accent) {
    final cw = _tableCardWidth;
    final discard = c.state.discardPile;
    final visible = discard
        .where((card) => !_hidden.contains(card.id))
        .toList();
    final top = visible.isEmpty ? null : visible.last;
    final beneath = visible.length <= 1
        ? <GameCard>[]
        : visible.sublist(math.max(0, visible.length - 3), visible.length - 1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            KeyedSubtree(
              key: _drawKey,
              child: DrawPileView(
                count: c.state.drawPileCount,
                cardWidth: cw,
                backId: settings.settings.cardBackId,
                highlighted: c.canInteract && c.canDraw,
                onTap: c.canInteract ? c.drawCard : null,
              ),
            ),
            // §11 — the Chain Storm wraps the stock the penalty will come from.
            Positioned.fill(
              child: Center(
                child: ChainStorm(
                  level: c.chainLevel.value,
                  total: c.chainTotal.value,
                  size: Size(cw * 1.9, cw * 1.9),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: cw * 0.20),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KeyedSubtree(
              key: _discardKey,
              child: DiscardPileView(
                top: top,
                beneath: beneath,
                cardWidth: cw,
                highContrast: settings.settings.highContrast,
              ),
            ),
          ],
        ),
        SizedBox(width: cw * 0.10),
        ActiveSuitBadge(suit: c.state.activeSuit, size: cw * 0.52),
      ],
    );
  }

  Widget _playerStrip(GamePlayer viewer, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xs,
        AppSpacing.gutter,
        0,
      ),
      child: PlayerBar(
        player: viewer,
        isActive: c.currentPlayer.id == viewer.id,
        targetScore: c.state.rules.targetScore,
        accent: accent,
        reaction: c.reactions[viewer.id],
      ),
    );
  }

  /// §8 — contextual actions only. There is never a bare "pass" button.
  Widget _actionRow(Color accent) {
    final s = Strings.s;
    final canDraw = c.canInteract && c.canDraw;
    final mustTake = c.canInteract && c.mustTakePenalty;
    final canPass = c.canInteract && c.canEndTurn;

    final children = <Widget>[];
    if (mustTake) {
      children.add(
        Expanded(
          child: PremiumButton(
            label: '${s.takePenalty} +${c.state.pendingDrawCount}',
            size: ButtonSize.medium,
            accent: AppColors.terracottaCoral,
            icon: AppIcon.draw,
            onPressed: c.drawCard,
          ),
        ),
      );
    } else if (canDraw) {
      children.add(
        Expanded(
          child: PremiumButton(
            label: s.drawCard,
            size: ButtonSize.medium,
            variant: ButtonVariant.secondary,
            icon: AppIcon.draw,
            onPressed: c.drawCard,
          ),
        ),
      );
    }
    if (canPass) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: AppSpacing.md));
      }
      children.add(
        Expanded(
          child: PremiumButton(
            label: s.passTurn,
            size: ButtonSize.medium,
            variant: ButtonVariant.ghost,
            onPressed: c.endTurn,
          ),
        ),
      );
    }

    return AnimatedSize(
      duration: Motion.scale(AppDurations.quick),
      curve: Curves.easeOutCubic,
      child: children.isEmpty
          ? const SizedBox(height: AppSpacing.sm, width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                0,
              ),
              child: Row(children: children),
            ),
    );
  }

  Widget _hand(GamePlayer viewer) {
    final cards = viewer.hand
        .where((card) => !_hidden.contains(card.id))
        .toList();
    final playable = c.isHumanTurn && c.currentPlayer.id == viewer.id
        ? c.playableForViewer.toSet()
        : <GameCard>{};

    return KeyedSubtree(
      key: _handKey,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: HandFan(
          cards: cards,
          cardWidth: _handCardWidth,
          playable: playable,
          selected: c.selectedCard.value,
          enabled: c.canInteract && c.currentPlayer.id == viewer.id,
          backId: settings.settings.cardBackId,
          highContrast: settings.settings.highContrast,
          onSelect: c.selectCard,
          onPlay: c.playCard,
          onReject: c.rejectCard,
        ),
      ),
    );
  }

  /// §61 — a brief label, then it gets out of the way.
  Widget _bannerLayer() {
    final text = c.banner.value;
    if (text == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.12),
        child: TweenAnimationBuilder<double>(
          key: ValueKey(text),
          tween: Tween(begin: 0, end: 1),
          duration: Motion.scale(const Duration(milliseconds: 320)),
          curve: Curves.easeOutBack,
          // easeOutBack overshoots past 1: the scale wants that, Opacity
          // asserts on it.
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.85 + t * 0.15, child: child),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              color: AppColors.inkDeep.withValues(alpha: 0.78),
              border: Border.all(
                color: AppColors.antiqueGold.withValues(alpha: 0.55),
              ),
            ),
            child: Text(text, style: AppText.tableShout.copyWith(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ seat layout

  List<Alignment> _seatPositions(int count) {
    switch (count) {
      case 1:
        return const [Alignment(0, -0.86)];
      case 2:
        return const [Alignment(-0.82, -0.80), Alignment(0.82, -0.80)];
      default:
        return const [
          Alignment(-0.92, -0.34),
          Alignment(0, -0.90),
          Alignment(0.92, -0.34),
        ];
    }
  }

  /// Angles used by the direction ring; index 0 is the viewer's own seat.
  List<double> _seatAngles(int count) {
    switch (count) {
      case 1:
        return [math.pi / 2, -math.pi / 2];
      case 2:
        return [math.pi / 2, math.pi * 1.20, math.pi * 1.80];
      default:
        return [math.pi / 2, math.pi, -math.pi / 2, 0];
    }
  }

  int _activeSeatIndex(List<GamePlayer> opponents) {
    final current = c.currentPlayer.id;
    if (current == c.viewingPlayer.id) return 0;
    final i = opponents.indexWhere((p) => p.id == current);
    return i < 0 ? 0 : i + 1;
  }
}

/// §M — a single dot saying whether the table is still talking to the server.
class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.status});

  final NetworkStatus status;

  @override
  Widget build(BuildContext context) {
    final offline = status == NetworkStatus.offline;
    final tint = offline ? AppColors.terracottaCoral : AppColors.fateWarning;
    return Semantics(
      liveRegion: true,
      label: offline ? Strings.s.networkOffline : Strings.s.networkReconnecting,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
