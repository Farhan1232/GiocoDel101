import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/bindings/backend_services.dart';
import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../auth/application/session_controller.dart';
import '../../online/domain/online_status.dart';
import '../../settings/application/settings_controller.dart';
import '../application/daily_reward_repository.dart';
import '../domain/daily_reward.dart';

/// §T — the seven-day ladder.
///
/// The calendar is drawn from what the server says about this account
/// (`my_daily_reward_status`); claiming calls `claim_daily_reward`, which
/// decides the day and the amount itself. Guests see the ladder but are told
/// an account is needed to claim; without a backend the button explains that
/// rather than crediting coins that go nowhere.
class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({super.key});

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen> {
  DailyRewardStatus? _status;
  bool _busy = false;

  bool get _online =>
      OnlineStatus.isConfigured && Get.find<SessionController>().isSignedIn;

  DailyRewardRepository get _repo => Get.find<BackendServices>().dailyRewards;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!_online) return;
    try {
      final status = await _repo.status();
      if (mounted) setState(() => _status = status);
    } on DailyRewardException {
      // Leave the calendar at day zero; the claim button stays disabled.
    } catch (_) {}
  }

  Future<void> _claim() async {
    if (_busy) return;
    setState(() => _busy = true);
    final s = Strings.s;
    try {
      final next = await _repo.claim();
      if (mounted) setState(() => _status = next);
    } on DailyRewardException catch (error) {
      await AppDialog.notice(
        title: s.commonErrorTitle,
        body: switch (error.error) {
          DailyRewardError.guestNotAllowed => s.dailyRewardGuestHint,
          DailyRewardError.alreadyClaimed => s.dailyRewardClaimedToday,
          _ => s.dailyRewardClaimFailed,
        },
        dismissLabel: s.gotIt,
      );
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final settings = Get.find<SettingsController>();
    final session = Get.find<SessionController>();
    final status = _status;
    final calendar = DailyRewardCalendar.forStreak(
      status?.streak ?? 0,
      claimedToday: status?.claimedToday ?? false,
    );
    final canClaim = _online && (status?.canClaim ?? false);

    final String caption;
    if (!OnlineStatus.isConfigured) {
      caption = s.authBackendPending;
    } else if (!session.isSignedIn) {
      caption = s.onlineSignInRequired;
    } else if (session.isGuest) {
      caption = s.dailyRewardGuestHint;
    } else if (status?.claimedToday ?? false) {
      caption = s.dailyRewardClaimedToday;
    } else {
      caption = s.dailyRewardBody;
    }

    return ScreenScaffold(
      title: s.dailyRewardTitle,
      child: Obx(() {
        final accent = settings.theme.accent;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              s.dailyRewardBody,
              style: AppText.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (status != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                s.dailyRewardBalance(status.coins),
                style: AppText.label.copyWith(color: AppColors.goldLight),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(
              builder: (context, box) {
                // Four across on a phone, seven on anything wide enough.
                final columns = box.maxWidth > 460 ? 7 : 4;
                final width =
                    (box.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final day in calendar.days)
                      SizedBox(
                        width: width,
                        child: _DayTile(day: day, accent: accent),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            PremiumButton(
              label: s.dailyRewardClaim,
              accent: accent,
              loading: _busy,
              onPressed: canClaim ? _claim : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              caption,
              style: AppText.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      }),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.accent});

  final DailyRewardDay day;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final active = day.isToday;
    final colour = day.isClaimed
        ? AppColors.mediterraneanTeal
        : (active ? accent : AppColors.textMuted);

    return Semantics(
      label:
          '${s.dailyRewardDay(day.day)}. ${day.amount}. '
          '${day.isClaimed ? s.dailyRewardClaimed : ''}',
      excludeSemantics: true,
      child: AppPanel(
        accent: active ? accent : null,
        tintStrength: active ? 1.0 : 0.3,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.dailyRewardDay(day.day),
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppIconView(
              day.isClaimed ? AppIcon.check : AppIcon.trophy,
              size: 20,
              color: colour,
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${day.amount}',
                style: AppText.scoreSmall.copyWith(color: colour),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
