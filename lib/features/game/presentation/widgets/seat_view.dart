import 'package:flutter/material.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/motion.dart';
import '../../../../app/localization/app_strings.dart';
import '../../domain/game_player.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/avatar_medallion.dart';
import 'fate_ring.dart';
import 'hand_fan.dart';

/// §27/§61 — an opponent's place at the table.
///
/// Medallion, name, card count, and the 101 Fate Ring. The medallion's rim
/// lights when it is this seat's turn, so the player never has to read a
/// label to know where play is.
class OpponentSeat extends StatelessWidget {
  const OpponentSeat({
    super.key,
    required this.player,
    required this.isActive,
    required this.cardWidth,
    required this.backId,
    required this.targetScore,
    this.reaction,
    this.skipped = false,
    this.compact = false,
    this.accent,
  });

  final GamePlayer player;
  final bool isActive;
  final double cardWidth;
  final String backId;
  final int targetScore;

  /// §23 — a phrase floating over this seat, if any.
  final String? reaction;

  /// §9 — this seat has just been skipped by an Ace.
  final bool skipped;

  final bool compact;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ringSize = compact ? 46.0 : 54.0;
    final medallion = compact ? 40.0 : 46.0;

    return AnimatedOpacity(
      duration: Motion.scale(AppDurations.quick),
      opacity: player.eliminated ? 0.45 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OpponentHand(
            count: player.cardCount,
            cardWidth: cardWidth,
            backId: backId,
          ),
          // Enough clearance that the fan never sits on the Fate Ring.
          const SizedBox(height: AppSpacing.sm),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // The Fate Ring is the mount the medallion sits inside.
              FateRing(
                score: player.score,
                size: ringSize,
                target: targetScore,
                eliminated: player.eliminated,
                showLabel: false,
                accent: accent,
              ),
              Positioned.fill(
                child: Center(
                  child: AvatarMedallion(
                    avatarId: player.avatarId,
                    size: medallion * 0.62,
                    active: isActive,
                    dimmed: player.eliminated,
                    glow: isActive ? 1 : 0,
                  ),
                ),
              ),
              Positioned(
                right: -10,
                bottom: -4,
                child: CardCountChip(
                  count: player.cardCount,
                  accent: accent ?? AppColors.antiqueGold,
                  warn: player.cardCount == 1 && !player.eliminated,
                ),
              ),
              if (skipped)
                Positioned(
                  top: -22,
                  child: _floating(
                    Strings.s.turnSkipped,
                    AppColors.goldLight,
                  ),
                ),
              if (reaction != null)
                Positioned(
                  top: -26,
                  child: _floating(reaction!, AppColors.warmIvory),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: compact ? 76 : 92,
            child: Text(
              player.name,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                fontSize: 10.5,
                color: isActive
                    ? (accent ?? AppColors.antiqueGold)
                    : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${player.score}',
            style: AppText.scoreSmall.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _floating(String text, Color colour) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween(begin: 0, end: 1),
      duration: Motion.scale(const Duration(milliseconds: 260)),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(
        scale: 0.7 + t * 0.3,
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: AppColors.inkDeep.withValues(alpha: 0.88),
          border: Border.all(color: colour.withValues(alpha: 0.55)),
        ),
        child: Text(
          text,
          style: AppText.caption.copyWith(
            fontSize: 9.5,
            letterSpacing: 0.9,
            color: colour,
          ),
        ),
      ),
    );
  }
}

/// The local player's strip: medallion, name, Fate Ring and score (§27).
class PlayerBar extends StatelessWidget {
  const PlayerBar({
    super.key,
    required this.player,
    required this.isActive,
    required this.targetScore,
    this.reaction,
    this.accent,
    this.trailing,
    this.resetting = false,
    this.onResetFinished,
  });

  final GamePlayer player;
  final bool isActive;
  final int targetScore;
  final String? reaction;
  final Color? accent;
  final Widget? trailing;

  /// §17 — plays the full 101 sequence in place.
  final bool resetting;
  final VoidCallback? onResetFinished;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            FateRing(
              score: player.score,
              size: 58,
              target: targetScore,
              eliminated: player.eliminated,
              playReset: resetting,
              onResetFinished: onResetFinished,
              showLabel: false,
              accent: accent,
            ),
            AvatarMedallion(
              avatarId: player.avatarId,
              size: 34,
              active: isActive,
              glow: isActive ? 1 : 0,
            ),
            if (reaction != null)
              Positioned(
                top: -26,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppColors.inkDeep.withValues(alpha: 0.9),
                    border: Border.all(
                        color: AppColors.warmIvory.withValues(alpha: 0.5)),
                  ),
                  child: Text(reaction!,
                      style: AppText.caption.copyWith(fontSize: 9.5)),
                ),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? (accent ?? AppColors.antiqueGold)
                      : AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text('${player.score}',
                      style: AppText.scoreSmall.copyWith(fontSize: 15)),
                  Text(' / $targetScore', style: AppText.caption),
                  const SizedBox(width: AppSpacing.sm),
                  CardCountChip(
                    count: player.cardCount,
                    accent: accent ?? AppColors.antiqueGold,
                    warn: player.cardCount == 1,
                  ),
                ],
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
