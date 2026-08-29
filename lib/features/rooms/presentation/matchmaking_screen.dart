import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/avatar_medallion.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../online/domain/online_status.dart';
import '../../settings/application/settings_controller.dart';

/// §L — the waiting screen for a quick match.
///
/// The elapsed counter is real: it counts the time actually spent on this
/// screen. The seat row shows the player and, honestly, nothing else — no
/// opponent is ever announced, because none is being found. When there is no
/// backend at all the screen says so instead of spinning forever.
class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

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
  int _elapsed = 0;

  /// Quick match seats four; only the local player is ever seated.
  static const int _seats = 4;

  @override
  void initState() {
    super.initState();
    if (Motion.allowAmbient) _pulse.repeat();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return ScreenScaffold(
      title: s.matchmakingTitle,
      onBack: () => Get.back<void>(),
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
                    progress: _pulse.value,
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
            Text(
              OnlineStatus.isConfigured ? s.matchmakingBody : s.authBackendPending,
              style: AppText.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
            PremiumButton(
              label: s.matchmakingCancel,
              variant: ButtonVariant.ghost,
              size: ButtonSize.medium,
              onPressed: () => Get.back<void>(),
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

/// Three expanding rings. Decorative only — it is not tied to any search.
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
