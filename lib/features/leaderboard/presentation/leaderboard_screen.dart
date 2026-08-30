import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/bindings/backend_services.dart';
import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/avatar_medallion.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../../online/domain/online_status.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/leaderboard_models.dart';

/// §R — weekly and all-time boards.
///
/// Model-driven: the list is built from a [LeaderboardBoard] that comes from
/// one real query (`public.leaderboard`). Without a backend or a session both
/// boards are empty and say so — no placeholder names, no invented scores.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  /// One page: small enough to arrive fast on a phone, large enough that
  /// "Carica altri" is rarely needed.
  static const int pageSize = 25;

  LeaderboardScope _scope = LeaderboardScope.weekly;
  LeaderboardBoard? _board;
  LeaderboardEntry? _mine;
  bool _mineLoaded = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _failed = false;
  int _request = 0;

  bool get _canQuery =>
      OnlineStatus.isConfigured && Get.find<SessionController>().isSignedIn;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_canQuery) {
      setState(() => _board = LeaderboardBoard(scope: _scope));
      return;
    }
    final id = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
      _mine = null;
      _mineLoaded = false;
    });
    final repo = Get.find<BackendServices>().leaderboards;
    try {
      final board = await repo.load(_scope, limit: pageSize, offset: 0);
      if (!mounted || id != _request) return;
      setState(() => _board = board);
      // The player's own row is a second, independent query: a failure
      // here must not take the board down with it.
      try {
        final mine = await repo.myRank(_scope);
        if (!mounted || id != _request) return;
        setState(() {
          _mine = mine;
          _mineLoaded = true;
        });
      } catch (_) {
        if (mounted && id == _request) setState(() => _mineLoaded = false);
      }
    } catch (_) {
      if (!mounted || id != _request) return;
      setState(() => _failed = true);
    } finally {
      if (mounted && id == _request) setState(() => _loading = false);
    }
  }

  /// The next page, appended below the current one.
  Future<void> _loadMore() async {
    final board = _board;
    if (board == null || !board.hasMore || _loadingMore || !_canQuery) return;
    final id = _request;
    setState(() => _loadingMore = true);
    try {
      final next = await Get.find<BackendServices>().leaderboards.load(
        _scope,
        limit: pageSize,
        offset: board.entries.length,
      );
      if (!mounted || id != _request) return;
      setState(() => _board = board.append(next));
    } catch (_) {
      if (!mounted || id != _request) return;
      // Keep what is on screen; the button stays for another try.
    } finally {
      if (mounted && id == _request) setState(() => _loadingMore = false);
    }
  }

  void _select(LeaderboardScope scope) {
    if (scope == _scope) return;
    setState(() => _scope = scope);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final settings = Get.find<SettingsController>();

    return ScreenScaffold(
      title: s.leaderboardTitle,
      scrollable: false,
      child: Obx(() {
        final accent = settings.theme.accent;
        final board = _board ?? LeaderboardBoard(scope: _scope);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            SegmentedControl<LeaderboardScope>(
              value: _scope,
              accent: accent,
              onChanged: _select,
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
            Expanded(child: _body(s, board, accent)),
          ],
        );
      }),
    );
  }

  Widget _body(AppLocalizations s, LeaderboardBoard board, Color accent) {
    if (_loading && board.isEmpty) return LoadingView(accent: accent);
    if (_failed) {
      return ErrorView(
        title: s.commonErrorTitle,
        message: s.leaderboardLoadFailed,
        retryLabel: s.commonRetry,
        onRetry: _load,
      );
    }
    if (OnlineStatus.isConfigured && !_canQuery) {
      return EmptyView(
        icon: AppIcon.trophy,
        title: s.commonEmptyTitle,
        message: s.onlineSignInRequired,
        actionLabel: s.authSignIn,
        onAction: () => Get.toNamed<void>(AppRoutes.authLanding),
      );
    }
    if (board.isEmpty) {
      return EmptyView(
        icon: AppIcon.trophy,
        title: s.commonEmptyTitle,
        message: board.isAvailable
            ? s.leaderboardNoScoresYet
            : s.leaderboardEmpty,
      );
    }
    final selfOnPage = board.entries.any((e) => e.isSelf);
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            itemCount: board.entries.length + (board.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              if (i >= board.entries.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: PremiumButton(
                    label: s.leaderboardLoadMore,
                    variant: ButtonVariant.secondary,
                    size: ButtonSize.small,
                    loading: _loadingMore,
                    onPressed: _loadMore,
                  ),
                );
              }
              return _Row(entry: board.entries[i], accent: accent);
            },
          ),
        ),
        // §R — the player always sees where they stand, even at rank 400.
        if (_mineLoaded && !selfOnPage)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.lg,
            ),
            child: _mine == null
                ? Text(
                    s.leaderboardNotRanked,
                    style: AppText.caption,
                    textAlign: TextAlign.center,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.leaderboardYourRank.toUpperCase(),
                        style: AppText.label,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _Row(entry: _mine!, accent: accent),
                    ],
                  ),
          ),
      ],
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
