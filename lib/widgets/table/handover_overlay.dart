import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/utils/motion.dart';
import '../../data/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../cards/playing_card.dart';
import '../common/avatar_medallion.dart';
import '../common/premium_button.dart';

/// §67 — the Pass & Play privacy screen.
///
/// Between two people's turns the table is covered completely, so nobody
/// sees a hand that is not theirs. It is an overlay, not a route, so the
/// match state underneath is never disturbed.
class HandoverOverlay extends StatelessWidget {
  const HandoverOverlay({
    super.key,
    required this.playerName,
    required this.avatarId,
    required this.backId,
    required this.onReady,
    this.accent,
  });

  final String playerName;
  final String avatarId;
  final String backId;
  final VoidCallback onReady;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.scale(const Duration(milliseconds: 320)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: ColoredBox(
        color: AppColors.inkDeep.withValues(alpha: 0.97),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = -1; i <= 1; i++)
                      Transform.translate(
                        offset: Offset(i * 34.0, i.abs() * 8.0),
                        child: Transform.rotate(
                          angle: i * 0.16,
                          child: PlayingCard(
                            width: 96,
                            faceUp: false,
                            backId: backId,
                            elevation: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                AvatarMedallion(avatarId: avatarId, size: 72, active: true),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  s.passPhoneTo(playerName.toUpperCase()),
                  textAlign: TextAlign.center,
                  style: AppText.tableShout.copyWith(fontSize: 19),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  s.passPhoneHint,
                  textAlign: TextAlign.center,
                  style: AppText.bodySmall,
                ),
                const Spacer(),
                PremiumButton(
                  label: s.imReady,
                  accent: accent,
                  onPressed: onReady,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
