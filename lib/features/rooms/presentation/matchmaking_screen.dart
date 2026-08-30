import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/bindings/backend_services.dart';
import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/avatar_medallion.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../auth/application/session_controller.dart';
import '../../game/application/match_launcher.dart';
import '../../game/domain/match_factory.dart';
import '../../online/domain/online_match_models.dart';
import '../../online/domain/online_status.dart';
import '../../settings/application/settings_controller.dart';

/// §L — the quick-match queue.
///
/// The player picks a table size, joins the server's queue and waits. The
/// elapsed counter is real; the seat row shows the player and, honestly,
/// nothing else until the server has assembled a room from real waiting
/// players — no opponent is ever announced that is not seated in a row of
/// `room_players`. Cancelling really leaves the queue.
class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  /// After this long with nobody else in the queue the screen offers an
  /// OFFLINE match against bots instead. It is offered, never substituted:
  /// the seats are labelled as the computer's and nothing is ranked.
  static const int cpuOfferAfterSeconds = 30;

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late final SettingsController _settings = Get.find<SettingsController>();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  Timer? _tick;
  Timer? _heartbeat;
  int _elapsed = 0;
  int _seats = 2;
  bool _searching = false;
  bool _matched = false;
  String? _error;

  /// Quick matches all play with the same clock so any two waiting players
  /// are compatible; private rooms choose their own.
  static const int _quickMatchTimerSeconds = 30;

  bool get _offersCpu =>
      _searching &&
      !_matched &&
      _elapsed >= MatchmakingScreen.cpuOfferAfterSeconds;

  /// Leaves the queue for real, then seats the same table size against bots.
  Future<void> _continueAgainstCpu() async {
    _tick?.cancel();
    _heartbeat?.cancel();
    final seats = _seats;
    if (_searching && !_matched) {
      try {
        await Get.find<BackendServices>().matchmaking.cancel();
      } catch (_) {
        // Already out of the queue, or offline: either way we are leaving.
      }
    }
    _searching = false;
    if (!mounted) return;
    final settings = _settings.settings;
    MatchLauncher.launch(
      MatchFactory.vsComputer(
        playerName: settings.playerName,
        avatarId: settings.avatarId,
        playerCount: seats,
        difficulty: settings.defaultDifficulty,
      ),
      replace: true,
    );
  }

  bool get _canSearch =>
      OnlineStatus.isConfigured && Get.find<SessionController>().isSignedIn;

  @override
  void initState() {
    super.initState();
    if (Motion.allowAmbient) _pulse.repeat();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _heartbeat?.cancel();
    _pulse.dispose();
    if (_searching && !_matched) {
      unawaited(Get.find<BackendServices>().matchmaking.cancel());
    }
    super.dispose();
  }

  Future<void> _search() async {
    if (!_canSearch || _searching) return;
    setState(() {
      _searching = true;
      _error = null;
      _elapsed = 0;
    });
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
    final queue = Get.find<BackendServices>().matchmaking;
    try {
      final entry = await queue.enqueue(
        playerCount: _seats,
        turnTimerSeconds: _quickMatchTimerSeconds,
      );
      if (!mounted) return;
      if (entry.isMatched) {
        await _matchedInto(entry);
        return;
      }
      // The queue is re-checked by the server on every heartbeat; matching
      // is done by the last compatible player to arrive.
      _heartbeat = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
    } on OnlineException catch (e) {
      if (!mounted) return;
      _tick?.cancel();
      setState(() {
        _searching = false;
        _error = switch (e.error) {
          OnlineError.conflict => Strings.s.matchmakingBusy,
          OnlineError.notSignedIn => Strings.s.onlineSignInRequired,
          // The service is configured but cannot be reached right now:
          // say so, and leave the offline game one tap away.
          OnlineError.network ||
          OnlineError.unavailable ||
          OnlineError.unknown => Strings.s.onlineUnavailableRetry,
          _ => Strings.s.authBackendPending,
        };
      });
    }
  }

  Future<void> _poll() async {
    if (!_searching || _matched) return;
    final queue = Get.find<BackendServices>().matchmaking;
    final entry = await queue.heartbeat();
    if (!mounted || !_searching) return;
    if (entry == null) {
      // Our row is gone: matched and swept, or expired. Re-enqueue.
      unawaited(_search());
      return;
    }
    if (entry.isMatched) await _matchedInto(entry);
  }

  Future<void> _matchedInto(QueueEntry entry) async {
    if (_matched) return;
    _matched = true;
    _tick?.cancel();
    _heartbeat?.cancel();
    setState(() {});
    final room = await Get.find<BackendServices>().rooms.load(entry.roomId!);
    if (!mounted) return;
    if (room == null) {
      _matched = false;
      unawaited(_search());
      return;
    }
    await Get.offNamed<void>(AppRoutes.roomLobby, arguments: room);
  }

  Future<void> _cancel() async {
    _tick?.cancel();
    _heartbeat?.cancel();
    if (_searching && !_matched) {
      await Get.find<BackendServices>().matchmaking.cancel();
    }
    _searching = false;
    Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return ScreenScaffold(
      title: s.matchmakingTitle,
      onBack: _cancel,
      child: Obx(() {
        final accent = _settings.theme.accent;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 168,
              width: 168,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => CustomPaint(
                  painter: _RadarPainter(
                    progress: _searching ? _pulse.value : 0,
                    colour: accent,
                  ),
                  child: child,
                ),
                child: Center(
                  child: AvatarMedallion(
                    avatarId: _settings.settings.avatarId,
                    size: 64,
                    active: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (!_searching) ...[
              Text(s.matchmakingPlayers, style: AppText.label),
              const SizedBox(height: AppSpacing.sm),
              SegmentedControl<int>(
                options: const [
                  SegmentOption(value: 2, label: '2'),
                  SegmentOption(value: 3, label: '3'),
                  SegmentOption(value: 4, label: '4'),
                ],
                value: _seats,
                accent: accent,
                onChanged: (n) => setState(() => _seats = n),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              _error ??
                  (_matched
                      ? s.matchmakingMatched
                      : _searching
                      ? s.matchmakingSearching(_seats)
                      : _canSearch
                      ? s.onlineQuickMatchHint
                      : OnlineStatus.isConfigured
                      ? s.onlineSignInRequired
                      : s.authBackendPending),
              style: AppText.body.copyWith(
                color: _error != null
                    ? AppColors.terracottaCoral
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_searching)
              Text(
                s.matchmakingElapsed(_elapsed),
                style: AppText.scoreSmall.copyWith(color: AppColors.textMuted),
              ),
            const SizedBox(height: AppSpacing.xxl),
            Text(s.matchmakingFound(1, _seats), style: AppText.label),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _seats; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: i == 0
                        ? AvatarMedallion(
                            avatarId: _settings.settings.avatarId,
                            size: 44,
                          )
                        : _emptySeat(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
            if (_offersCpu) ...[
              Text(
                s.matchmakingCpuHint,
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              PremiumButton(
                label: s.matchmakingCpuOffer,
                accent: accent,
                icon: AppIcon.difficulty,
                onPressed: _continueAgainstCpu,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (!_searching)
              PremiumButton(
                label: s.matchmakingSearch,
                accent: accent,
                onPressed: _canSearch ? _search : null,
              ),
            const SizedBox(height: AppSpacing.sm),
            PremiumButton(
              label: s.matchmakingCancel,
              variant: ButtonVariant.ghost,
              size: ButtonSize.medium,
              onPressed: _cancel,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      }),
    );
  }

  Widget _emptySeat() => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.surfaceSunken,
      border: Border.all(color: AppColors.hairline),
    ),
  );
}

/// Three expanding rings. Decorative only — still while nothing is searched.
class _RadarPainter extends CustomPainter {
  const _RadarPainter({required this.progress, required this.colour});

  final double progress;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final radius = maxRadius * (0.34 + t * 0.66);
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = colour.withValues(alpha: (1 - t) * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.progress != progress || old.colour != colour;
}
