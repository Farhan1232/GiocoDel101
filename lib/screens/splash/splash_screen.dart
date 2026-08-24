import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes.dart';
import '../../core/utils/motion.dart';
import '../../controllers/settings_controller.dart';
import '../../models/card_suit.dart';
import '../../services/audio_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/table_themes.dart';
import '../../widgets/cards/playing_card.dart';
import '../../widgets/cards/suit_art.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/logo_101.dart';

/// §24 Screen 1 — a short, deliberate opening.
///
/// A card rises from the bottom, the four suits settle into orbit, and gold
/// light crosses the 101. It runs about 1.7s and never stalls: if the app is
/// ready sooner the route change simply happens at the end of the beat.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
    vsync: this,
    duration: Motion.reduceMotion
        ? const Duration(milliseconds: 650)
        : const Duration(milliseconds: 1750),
  );
    _c.forward();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Get.offNamed<void>(AppRoutes.home);
      }
    });
    // A single soft riffle as the logo lands. Held so it can be cancelled if
    // the screen goes away first.
    _riffle = Timer(const Duration(milliseconds: 420), () {
      AudioService.instance.play(Sfx.shuffle, volume: 0.45);
    });
  }

  Timer? _riffle;

  @override
  void dispose() {
    _riffle?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>().theme
        : TableThemes.napoliNotte;

    return Scaffold(
      backgroundColor: AppColors.inkDeep,
      body: AppBackground(
        theme: theme,
        motifStrength: 0.7,
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              final cardRise = Curves.easeOutCubic.transform(
                  ((t - 0.02) / 0.42).clamp(0.0, 1.0));
              final logoIn = Curves.easeOutBack.transform(
                  ((t - 0.24) / 0.40).clamp(0.0, 1.0));
              final orbit = ((t - 0.32) / 0.55).clamp(0.0, 1.0);
              final shimmer = ((t - 0.55) / 0.40).clamp(0.0, 1.0);
              final fadeOut = ((t - 0.90) / 0.10).clamp(0.0, 1.0);

              return Opacity(
                opacity: 1 - fadeOut * 0.35,
                child: SizedBox(
                  width: 320,
                  height: 380,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Card entering from below, behind the mark.
                      Transform.translate(
                        // Settles below the mark rather than behind it, so the wordmark
                        // stays legible against the felt-dark back.
                        offset: Offset(0, 250 - cardRise * 162),
                        child: Transform.rotate(
                          angle: (1 - cardRise) * 0.45,
                          child: Opacity(
                            opacity: cardRise.clamp(0.0, 1.0) * 0.95,
                            child: PlayingCard(
                              width: 108,
                              faceUp: false,
                              backId: theme.cardBackId,
                              elevation: 1.6,
                            ),
                          ),
                        ),
                      ),
                      // Suits taking their places around the mark.
                      if (orbit > 0)
                        CustomPaint(
                          size: const Size(320, 320),
                          painter: _SuitOrbitPainter(progress: orbit),
                        ),
                      // The mark.
                      Transform.scale(
                        scale: 0.86 + logoIn * 0.14,
                        child: Opacity(
                          opacity: logoIn.clamp(0.0, 1.0),
                          child: Logo101(size: 86, shimmer: shimmer),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SuitOrbitPainter extends CustomPainter {
  const _SuitOrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = 118.0;
    for (var i = 0; i < CardSuit.values.length; i++) {
      final suit = CardSuit.values[i];
      final delay = i * 0.12;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final eased = Curves.easeOutCubic.transform(t);
      final angle = -math.pi / 2 + (i / 4) * math.pi * 2 + (1 - eased) * 0.9;
      final r = radius * (0.55 + eased * 0.45);
      final at = c + Offset(math.cos(angle), math.sin(angle)) * r;
      SuitArt.draw(
        canvas,
        Rect.fromCenter(center: at, width: 30, height: 30),
        suit,
        SuitPalette.of(suit),
        detail: 0.45,
        opacity: eased * 0.9,
      );
    }
  }

  @override
  bool shouldRepaint(_SuitOrbitPainter old) => old.progress != progress;
}
