import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/bindings/backend_services.dart';
import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
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
    if (!_online) {
      // Still redraw: coming back from the sign-in screen changes what the
      // caption under the button has to say, even with nothing to fetch.
      if (mounted) setState(() {});
      return;
    }
    try {
      final status = await _repo.status();
      if (mounted) setState(() => _status = status);
    } on DailyRewardException {
      // Leave the calendar at day zero; pressing claim still explains itself.
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  /// Why today's reward cannot be taken, or null when it can.
  ///
  /// The button is never dead: each of these is said out loud when it is
  /// pressed, and the one that has a way forward offers it.
  String? get _blockedBecause {
    final s = Strings.s;
    final session = Get.find<SessionController>();
    if (!OnlineStatus.isConfigured) return s.authBackendPending;
    if (!session.isSignedIn) return s.onlineSignInRequired;
    if (session.isGuest) return s.dailyRewardGuestHint;
    if (_status?.claimedToday ?? false) return s.dailyRewardClaimedToday;
    return null;
  }

  Future<void> _claim() async {
    if (_busy) return;
    final s = Strings.s;
    final session = Get.find<SessionController>();

    // Signing in is the one refusal the player can act on from here, so it
    // is offered rather than merely explained.
    if (OnlineStatus.isConfigured && !session.isSignedIn) {
      final go = await AppDialog.confirm(
        title: s.dailyRewardTitle,
        body: s.onlineSignInRequired,
        confirmLabel: s.authSignIn,
        cancelLabel: s.cancel,
      );
      if (go) await Get.toNamed<void>(AppRoutes.authLanding);
      if (mounted) await _refresh();
      return;
    }
    final blocked = _blockedBecause;
    if (blocked != null) {
      await AppDialog.notice(
        title: s.dailyRewardTitle,
        body: blocked,
        dismissLabel: s.gotIt,
      );
      return;
    }

    setState(() => _busy = true);
    final before = _status?.coins ?? 0;
    DailyRewardStatus? claimed;
    DailyRewardException? failure;
    try {
      claimed = await _repo.claim();
    } on DailyRewardException catch (error) {
      failure = error;
    }
    if (!mounted) return;
    // The button stops spinning before anything is said, so the dialog is
    // never talking over a control that still looks busy.
    setState(() {
      _busy = false;
      if (claimed != null) _status = claimed;
    });

    if (claimed != null) {
      // The ladder redraws either way; this names what was actually won,
      // which is the server's number and not the client's guess.
      final won = claimed.coins - before;
      await AppDialog.notice(
        title: s.dailyRewardWonTitle,
        body: won > 0 ? s.dailyRewardWonBody(won) : s.dailyRewardTomorrow,
        dismissLabel: s.gotIt,
      );
      return;
    }
    await AppDialog.notice(
      title: s.commonErrorTitle,
      body: switch (failure!.error) {
        DailyRewardError.guestNotAllowed => s.dailyRewardGuestHint,
        DailyRewardError.alreadyClaimed => s.dailyRewardClaimedToday,
        _ => s.dailyRewardClaimFailed,
      },
      dismissLabel: s.gotIt,
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final settings = Get.find<SettingsController>();
    final status = _status;
    final calendar = DailyRewardCalendar.forStreak(
      status?.streak ?? 0,
      claimedToday: status?.claimedToday ?? false,
    );
    // The caption says only what the intro above it does not. When the
    // reward is there for the taking it says nothing at all, rather than
    // printing the same sentence twice under the button.
    final caption = _blockedBecause;

    return ScreenScaffold(
      title: s.dailyRewardTitle,
      // The screen lays itself out: the ladder is centred in the space it
      // has and the button is anchored at the bottom, so neither is left
      // stranded halfway down an empty page.
      scrollable: false,
      child: Obx(() {
        final accent = settings.theme.accent;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    // Centred while it fits, scrolled the moment a large
                    // text scale makes it taller than the space.
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            style: AppText.label.copyWith(
                              color: AppColors.goldLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        _Ladder(calendar: calendar, accent: accent),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            PremiumButton(
              label: s.dailyRewardClaim,
              accent: accent,
              loading: _busy,
              // Always pressable: _claim answers for every refusal.
              onPressed: _claim,
            ),
            if (caption != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                caption,
                style: AppText.caption.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      }),
    );
  }
}

/// The seven day tiles, four across on a phone and seven on a tablet.
class _Ladder extends StatelessWidget {
  const _Ladder({required this.calendar, required this.accent});

  final DailyRewardCalendar calendar;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth > 460 ? 7 : 4;
        final width =
            (box.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          // Seven tiles over four columns leave the last row three wide:
          // centred it reads as a ladder, left-aligned as a hole in the grid.
          alignment: WrapAlignment.center,
          children: [
            for (final day in calendar.days)
              SizedBox(
                width: width,
                child: _DayTile(day: day, accent: accent),
              ),
          ],
        );
      },
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
              // "Giorno 1" all but fills the tile, so without this the label
              // sits hard against the left edge while the trophy and the
              // amount below it are centred.
              textAlign: TextAlign.center,
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
