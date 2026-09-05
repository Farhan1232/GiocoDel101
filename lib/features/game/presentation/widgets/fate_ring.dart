import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/utils/motion.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

/// §17 — the 101 Fate Ring.
///
/// A compact arc that fills from 0 to the target score and grows more tense
/// as it goes: calm, bright, warning, danger. Landing on exactly 101 plays
/// the game's signature moment — the ring completes, a gold shockwave breaks
/// it into shards, the shards spin back together, and the number turns to
/// zero under the word SALVO!
class FateRing extends StatefulWidget {
  const FateRing({
    super.key,
    required this.score,
    required this.size,
    this.target = 101,
    this.eliminated = false,
    this.playReset = false,
    this.onResetFinished,
    this.showLabel = true,
    this.accent,
  });

  final int score;
  final double size;
  final int target;
  final bool eliminated;

  /// Set true for one frame's worth of state to fire the 101 sequence.
  final bool playReset;
  final VoidCallback? onResetFinished;

  final bool showLabel;

  /// Table themes can tint the ring's rim.
  final Color? accent;

  @override
  State<FateRing> createState() => _FateRingState();
}

class _FateRingState extends State<FateRing> with TickerProviderStateMixin {
  late final AnimationController _reset;
  late final AnimationController _pulse;

  late int _displayed = widget.score;
  int _from = 0;

  @override
  void initState() {
    super.initState();
    _reset =
        AnimationController(
          vsync: this,
          duration: Motion.scale(AppDurations.fateRingReset),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onResetFinished?.call();
        });
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.playReset) _startReset();
    _syncPulse();
  }

  @override
  void didUpdateWidget(FateRing old) {
    super.didUpdateWidget(old);
    if (widget.score != old.score && !widget.playReset) {
      _from = _displayed;
      _displayed = widget.score;
    }
    if (widget.playReset && !old.playReset) _startReset();
    _syncPulse();
  }

  void _startReset() {
    _from = widget.target;
    _displayed = 0;
    _reset.forward(from: 0);
  }

  void _syncPulse() {
    final tense =
        !widget.eliminated &&
        widget.score >= widget.target - 2 &&
        Motion.allowAmbient;
    if (tense && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!tense && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _reset.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_reset, _pulse]),
          builder: (context, _) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: _from.toDouble(), end: _displayed.toDouble()),
              duration: Motion.scale(const Duration(milliseconds: 700)),
              curve: Curves.easeOutCubic,
              builder: (context, animatedScore, _) {
                return CustomPaint(
                  painter: _FateRingPainter(
                    score: _reset.isAnimating ? _resetScore() : animatedScore,
                    target: widget.target.toDouble(),
                    reset: _reset.isAnimating ? _reset.value : 0.0,
                    pulse: _pulse.value,
                    eliminated: widget.eliminated,
                    accent: widget.accent,
                  ),
                  child: _centre(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// During the sequence the arc holds full, then empties as the ring reforms.
  double _resetScore() {
    final t = _reset.value;
    if (t < 0.55) return widget.target.toDouble();
    return widget.target * (1 - ((t - 0.55) / 0.45)).clamp(0.0, 1.0);
  }

  Widget _centre() {
    final t = _reset.value;
    final showZero = _reset.isAnimating ? t > 0.78 : true;
    final value = showZero ? _displayed : widget.target;
    final salvo = _reset.isAnimating && t > 0.74;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 220),
            scale: salvo ? 1.12 : 1.0,
            child: Text(
              widget.eliminated ? '—' : '$value',
              style:
                  (widget.size > 64 ? AppText.scoreLarge : AppText.scoreSmall)
                      .copyWith(
                        fontSize: widget.size * 0.30,
                        color: widget.eliminated
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
            ),
          ),
          if (widget.showLabel && widget.size > 58)
            SizedBox(
              height: widget.size * 0.14,
              child: salvo
                  ? FittedBox(
                      child: Text(
                        Strings.s.savedFrom101,
                        style: AppText.label.copyWith(
                          color: AppColors.goldLight,
                          fontSize: widget.size * 0.11,
                          letterSpacing: 1.4,
                        ),
                      ),
                    )
                  : Text(
                      widget.eliminated
                          ? Strings.s.eliminated
                          : '/ ${widget.target}',
                      style: AppText.caption.copyWith(
                        fontSize: widget.size * 0.10,
                        color: widget.eliminated
                            ? AppColors.danger
                            : AppColors.textMuted,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _FateRingPainter extends CustomPainter {
  const _FateRingPainter({
    required this.score,
    required this.target,
    required this.reset,
    required this.pulse,
    required this.eliminated,
    this.accent,
  });

  final double score;
  final double target;

  /// 0 when idle, otherwise the 101 sequence's progress.
  final double reset;
  final double pulse;
  final bool eliminated;
  final Color? accent;

  static const double _start = -math.pi * 0.5;
  static const double _sweep = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.42;
    final width = size.width * 0.085;
    final progress = (score / target).clamp(0.0, 1.0);

    // Track.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = AppColors.inkDeep.withValues(alpha: 0.55),
    );

    // Tick marks every tenth, so the scale is readable without numbers.
    if (size.width > 46) {
      for (var i = 0; i <= 10; i++) {
        final a = _start + _sweep * (i / 10);
        final outer = c + Offset(math.cos(a), math.sin(a)) * (r + width * 0.52);
        final inner = c + Offset(math.cos(a), math.sin(a)) * (r + width * 0.16);
        canvas.drawLine(
          inner,
          outer,
          Paint()
            ..strokeWidth = size.width * 0.012
            ..color = AppColors.warmIvory.withValues(
              alpha: i == 10 ? 0.55 : 0.20,
            ),
        );
      }
    }

    if (eliminated) {
      _paintFractured(canvas, c, r, width);
      return;
    }

    final zone = _zoneColour(score);
    final shards = reset > 0.30 && reset < 0.80;

    if (!shards) {
      // Progress arc.
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        _start,
        _sweep * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width
          ..shader = ui.Gradient.sweep(
            c,
            [
              AppColors.fateCalm,
              zone,
              Color.lerp(zone, AppColors.goldLight, 0.35)!,
            ],
            const [0.0, 0.7, 1.0],
            TileMode.clamp,
            _start,
            _start + _sweep,
          ),
      );
      // Head of the arc catches the light.
      if (progress > 0.01 && progress < 1.0) {
        final a = _start + _sweep * progress;
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * r,
          width * 0.42,
          Paint()..color = Color.lerp(zone, Colors.white, 0.55)!,
        );
      }
    } else {
      _paintShards(canvas, c, r, width);
    }

    // Danger breathing at 99-100.
    if (pulse > 0 && reset == 0) {
      canvas.drawCircle(
        c,
        r + width * (0.5 + pulse * 0.7),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.012
          ..color = AppColors.fateDanger.withValues(alpha: 0.42 * (1 - pulse)),
      );
    }

    // The shockwave that breaks the ring open.
    if (reset > 0.16 && reset < 0.52) {
      final t = ((reset - 0.16) / 0.36).clamp(0.0, 1.0);
      canvas.drawCircle(
        c,
        r * (1 + t * 1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * (1.4 - t) * 0.9
          ..color = AppColors.goldLight.withValues(alpha: (1 - t) * 0.85),
      );
      canvas.drawCircle(
        c,
        r * (1 + t * 0.9),
        Paint()..color = AppColors.goldMid.withValues(alpha: (1 - t) * 0.16),
      );
    }

    // Gold flash at the moment the ring completes.
    if (reset > 0.08 && reset < 0.26) {
      final t = ((reset - 0.08) / 0.18).clamp(0.0, 1.0);
      canvas.drawCircle(
        c,
        r * 1.05,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 1.25
          ..color = AppColors.goldLight.withValues(
            alpha: math.sin(t * math.pi) * 0.9,
          ),
      );
    }
  }

  /// The ring in pieces, spinning apart and then back together.
  void _paintShards(Canvas canvas, Offset c, double r, double width) {
    const count = 9;
    // 0 at full separation, 1 back in place.
    final t = ((reset - 0.30) / 0.50).clamp(0.0, 1.0);
    final apart = math.sin((1 - t) * math.pi * 0.5);

    for (var i = 0; i < count; i++) {
      final a0 = _start + _sweep * (i / count);
      final span = _sweep / count * 0.72;
      final mid = a0 + span / 2;
      final push = apart * r * 0.55;
      final spin = apart * 1.4 * (i.isEven ? 1 : -1);

      canvas.save();
      canvas.translate(
        c.dx + math.cos(mid) * push,
        c.dy + math.sin(mid) * push,
      );
      canvas.rotate(spin);
      canvas.translate(-c.dx, -c.dy);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a0,
        span,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width
          ..color = Color.lerp(
            AppColors.goldLight,
            AppColors.goldMid,
            t,
          )!.withValues(alpha: 0.55 + 0.45 * t),
      );
      canvas.restore();
    }
  }

  void _paintFractured(Canvas canvas, Offset c, double r, double width) {
    const count = 7;
    for (var i = 0; i < count; i++) {
      final a0 = _start + _sweep * (i / count);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a0 + 0.06,
        _sweep / count - 0.16,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt
          ..strokeWidth = width * 0.8
          ..color = AppColors.fateFractured.withValues(alpha: 0.75),
      );
    }
  }

  Color _zoneColour(double value) {
    if (accent != null && value < target * 0.5) {
      return Color.lerp(AppColors.fateCalm, accent!, 0.35)!;
    }
    if (value >= target) return AppColors.goldLight;
    if (value >= target - 1) return AppColors.fateDanger;
    if (value >= target * 0.79) return AppColors.fateWarning;
    if (value >= target * 0.49) return AppColors.fateBright;
    return AppColors.fateCalm;
  }

  @override
  bool shouldRepaint(_FateRingPainter old) =>
      old.score != score ||
      old.reset != reset ||
      old.pulse != pulse ||
      old.eliminated != eliminated;
}
