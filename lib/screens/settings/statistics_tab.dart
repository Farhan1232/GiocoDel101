import 'package:flutter/material.dart';

import '../../controllers/stats_controller.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/achievements_catalog.dart';
import '../../data/app_strings.dart';
import '../../models/card_suit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/cards/suit_art.dart';
import '../../widgets/common/app_panel.dart';
import '../../widgets/common/premium_button.dart';
import '../../widgets/icons/app_icons.dart';

/// §39/§41 — lifetime numbers and the achievement shelf, in one place.
class StatisticsTab extends StatelessWidget {
  const StatisticsTab({
    super.key,
    required this.stats,
    required this.accent,
  });

  final StatsController stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final v = stats.stats;
    final empty = v.matchesPlayed == 0 && v.roundsPlayed == 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xxl),
      children: [
        if (empty)
          AppPanel(
            accent: accent,
            child: Row(
              children: [
                AppIconView(AppIcon.stats, size: 20, color: accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(s.noStatsYet, style: AppText.bodySmall)),
              ],
            ),
          ),
        if (!empty) ...[
          _headline(v.winPercentage, v.matchesWon, v.matchesPlayed),
          const SizedBox(height: AppSpacing.md),
          AppPanel(
            accent: accent,
            child: Column(
              children: [
                const SectionHeading('PARTITE'),
                _row(AppIcon.play, s.statMatches, '${v.matchesPlayed}'),
                _row(AppIcon.trophy, s.statWins, '${v.matchesWon}'),
                _row(AppIcon.restart, s.statRoundsWon,
                    '${v.roundsWon} / ${v.roundsPlayed}'),
                _row(AppIcon.difficulty, s.statStreak, '${v.currentStreak}'),
                _row(AppIcon.ring, s.statBestStreak, '${v.bestStreak}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPanel(
            accent: accent,
            child: Column(
              children: [
                const SectionHeading('CARTE'),
                _row(AppIcon.cards, s.statCards, '${v.cardsPlayed}'),
                _row(AppIcon.play, s.statAces, '${v.acesPlayed}'),
                _row(AppIcon.draw, s.statTwos, '${v.twosPlayed}'),
                _row(AppIcon.chain, s.statChain,
                    v.longestChain == 0 ? '—' : '+${v.longestChain * 2}'),
                _suitRow(s.statFavouriteSuit, v.favouriteSuit),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPanel(
            accent: accent,
            child: Column(
              children: [
                const SectionHeading('IL 101'),
                _row(AppIcon.ring, s.statResets, '${v.resets101}'),
                _row(AppIcon.stats, s.statComeback,
                    v.largestComeback <= 0 ? '—' : '${v.largestComeback}'),
                _row(AppIcon.calendar, s.dailyChallenge,
                    '${v.dailyChallengesCompleted}'),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _achievements(),
        const SizedBox(height: AppSpacing.xl),
        PremiumButton(
          label: s.resetStatistics,
          variant: ButtonVariant.ghost,
          size: ButtonSize.medium,
          onPressed: () => _confirmReset(context),
        ),
      ],
    );
  }

  Widget _headline(int percent, int won, int played) {
    return AppPanel(
      accent: accent,
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(84),
                  painter: _WinRingPainter(
                      percent: percent / 100, accent: accent),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$percent%', style: AppText.scoreLarge.copyWith(
                        fontSize: 22)),
                    Text(Strings.s.statWinRate.split(' ').first.toUpperCase(),
                        style: AppText.caption.copyWith(fontSize: 8.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Strings.s.statWinRate, style: AppText.label),
                const SizedBox(height: AppSpacing.xs),
                Text('$won / $played',
                    style: AppText.scoreLarge.copyWith(fontSize: 26)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppIcon icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm - 2),
        child: Row(
          children: [
            AppIconView(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppText.bodySmall)),
            Text(value, style: AppText.scoreSmall.copyWith(fontSize: 14)),
          ],
        ),
      );

  Widget _suitRow(String label, CardSuit? suit) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm - 2),
        child: Row(
          children: [
            const AppIconView(AppIcon.suits,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppText.bodySmall)),
            if (suit == null)
              Text('—', style: AppText.scoreSmall.copyWith(fontSize: 14))
            else
              SizedBox(
                width: 26,
                height: 26,
                child: CustomPaint(painter: _SuitGlyphPainter(suit)),
              ),
          ],
        ),
      );

  /// §41 — achievements live inside Statistics, never on a screen of their own.
  Widget _achievements() {
    return AppPanel(
      accent: accent,
      child: Column(
        children: [
          SectionHeading(
            Strings.s.achievements.toUpperCase(),
            trailing: Text(
              '${stats.stats.unlockedAchievements.length}'
              '/${AchievementsCatalog.all.length}',
              style: AppText.caption,
            ),
          ),
          for (final a in AchievementsCatalog.all)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Opacity(
                opacity: stats.hasAchievement(a.id) ? 1 : 0.45,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stats.hasAchievement(a.id)
                            ? AppColors.goldMid.withValues(alpha: 0.16)
                            : AppColors.surfaceSunken,
                        border: Border.all(
                          color: stats.hasAchievement(a.id)
                              ? AppColors.goldMid.withValues(alpha: 0.7)
                              : AppColors.hairline,
                        ),
                      ),
                      child: Center(
                        child: AppIconView(
                          stats.hasAchievement(a.id)
                              ? _iconFor(a.icon)
                              : AppIcon.lock,
                          size: 16,
                          color: stats.hasAchievement(a.id)
                              ? AppColors.goldLight
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title,
                              style: AppText.body.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700)),
                          Text(a.description, style: AppText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static AppIcon _iconFor(String key) => switch (key) {
        'chain' => AppIcon.chain,
        'ring' => AppIcon.ring,
        'suits' => AppIcon.suits,
        'hand' => AppIcon.hand,
        'calendar' => AppIcon.calendar,
        _ => AppIcon.trophy,
      };

  Future<void> _confirmReset(BuildContext context) async {
    final s = Strings.s;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.inkDeep.withValues(alpha: 0.72),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.resetStatistics,
                  style: AppText.screenTitle.copyWith(fontSize: 19)),
              const SizedBox(height: AppSpacing.md),
              Text(s.resetStatisticsBody,
                  textAlign: TextAlign.center, style: AppText.bodySmall),
              const SizedBox(height: AppSpacing.xl),
              PremiumButton(
                label: s.cancel,
                size: ButtonSize.medium,
                variant: ButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: AppSpacing.sm),
              PremiumButton(
                label: s.confirm,
                size: ButtonSize.medium,
                variant: ButtonVariant.danger,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) await stats.resetAll();
  }
}

class _WinRingPainter extends CustomPainter {
  const _WinRingPainter({required this.percent, required this.accent});

  final double percent;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.42;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.08
        ..color = AppColors.surfaceSunken,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -1.5708,
      6.2832 * percent.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = size.width * 0.08
        ..color = accent,
    );
  }

  @override
  bool shouldRepaint(_WinRingPainter old) => old.percent != percent;
}

class _SuitGlyphPainter extends CustomPainter {
  const _SuitGlyphPainter(this.suit);

  final CardSuit suit;

  @override
  void paint(Canvas canvas, Size size) {
    SuitArt.draw(canvas, Offset.zero & size, suit, SuitPalette.of(suit),
        detail: 0.5);
  }

  @override
  bool shouldRepaint(_SuitGlyphPainter old) => old.suit != suit;
}
