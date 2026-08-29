import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/avatar_medallion.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../core/widgets/state_views.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/leaderboard_models.dart';

/// §R — weekly and all-time boards.
///
/// Model-driven: the list is built from [LeaderboardBoard]. There is no
/// ranking service yet, so both boards are empty and say so — no placeholder
/// names, no invented scores.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderboardScope _scope = LeaderboardScope.weekly;

  /// Session 3 replaces this with a repository call.
  LeaderboardBoard get _board => LeaderboardBoard(scope: _scope);

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final settings = Get.find<SettingsController>();

    return ScreenScaffold(
      title: s.leaderboardTitle,
      scrollable: false,
      child: Obx(() {
        final accent = settings.theme.accent;
        final board = _board;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            SegmentedControl<LeaderboardScope>(
              value: _scope,
              accent: accent,
              onChanged: (v) => setState(() => _scope = v),
              options: [
                SegmentOption(
                  value: LeaderboardScope.weekly,
                  label: s.leaderboardWeekly,
                ),
                SegmentOption(
                  value: LeaderboardScope.allTime,
                  label: s.leaderboardAllTime,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: board.isEmpty
                  ? EmptyView(
                      icon: AppIcon.trophy,
                      title: s.commonEmptyTitle,
                      message: s.leaderboardEmpty,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      itemCount: board.entries.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) =>
                          _Row(entry: board.entries[i], accent: accent),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.accent});

  final LeaderboardEntry entry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return AppPanel(
      accent: entry.isSelf ? accent : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Semantics(
        label:
            '${s.leaderboardRank} ${entry.rank}. '
            '${entry.nickname}. ${entry.points} ${s.leaderboardPoints}',
        excludeSemantics: true,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${entry.rank}',
                style: AppText.scoreSmall.copyWith(
                  color: entry.rank <= 3 ? AppColors.goldLight : null,
                ),
              ),
            ),
            AvatarMedallion(avatarId: entry.avatarId, size: 38),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                entry.nickname,
                style: AppText.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${entry.points}', style: AppText.scoreSmall),
          ],
        ),
      ),
    );
  }
}
