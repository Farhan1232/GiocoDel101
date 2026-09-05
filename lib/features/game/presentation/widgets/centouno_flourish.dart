import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/motion.dart';
import 'fate_ring.dart';

/// §17 — the CENTOUNO! moment.
///
/// The word rises in struck gold with one slow sheen passing over it, the
/// Fate Ring completes and resets underneath, and the score counts down
/// from 101 to 0. One event, three quiet beats — no confetti, no bounce.
/// Under Reduce Motion the composition simply appears.
class CentounoFlourish extends StatefulWidget {
  const CentounoFlourish({
    super.key,
    required this.playerName,
    this.accent = AppColors.antiqueGold,
    this.target = 101,
    this.ringSize = 112,
    this.onFinished,
  });

  final String playerName;
  final Color accent;
  final int target;
  final double ringSize;
  final VoidCallback? onFinished;

  @override
  State<CentounoFlourish> createState() => _CentounoFlourishState();
}

class _CentounoFlourishState extends State<CentounoFlourish>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _sheen;
  late final AnimationController _count;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: Motion.scale(const Duration(milliseconds: 700)),
    )..forward();
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _count = AnimationController(
      vsync: this,
      duration: Motion.scale(const Duration(milliseconds: 1500)),
    );
    if (Motion.allowAmbient) _sheen.repeat();
    Future<void>.delayed(Motion.scale(const Duration(milliseconds: 500)), () {
      if (!mounted) return;
      _count.forward().whenComplete(() {
        if (mounted) widget.onFinished?.call();
      });
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _sheen.dispose();
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return Semantics(
      liveRegion: true,
      label: '${s.centounoTitle}. ${s.centounoBody(widget.playerName)}',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _sheen, _count]),
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_enter.value);
          final score =
              (widget.target *
                      (1 - Curves.easeInOutCubic.transform(_count.value)))
                  .round();
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (rect) => _goldSheen(rect, _sheen.value),
                    child: Text(
                      s.centounoTitle,
                      textAlign: TextAlign.center,
                      style: AppText.heroTitle.copyWith(
                        fontSize: 40,
                        letterSpacing: 6,
                        color: AppColors.goldLight,
                        shadows: [
                          Shadow(
                            color: AppColors.goldShadow.withValues(alpha: 0.6),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      FateRing(
                        score: 0,
                        size: widget.ringSize,
                        target: widget.target,
                        playReset: true,
                        showLabel: false,
                        accent: widget.accent,
                      ),
                      Text(
                        '$score',
                        style: AppText.scoreLarge.copyWith(
                          fontSize: widget.ringSize * 0.3,
                          color: score == 0
                              ? AppColors.goldLight
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    s.centounoBody(widget.playerName),
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// A narrow bright band sweeping left to right across the lettering.
  static Shader _goldSheen(Rect rect, double phase) {
    final x = -0.6 + phase * 2.2;
    return ui.Gradient.linear(
      Offset(rect.left + rect.width * (x - 0.3), rect.top),
      Offset(rect.left + rect.width * (x + 0.3), rect.bottom),
      const [
        AppColors.goldDeep,
        AppColors.goldMid,
        AppColors.goldLight,
        AppColors.goldMid,
        AppColors.goldDeep,
      ],
      const [0.0, 0.3, 0.5, 0.7, 1.0],
      TileMode.clamp,
      Matrix4.rotationZ(-math.pi / 10).storage,
    );
  }
}
