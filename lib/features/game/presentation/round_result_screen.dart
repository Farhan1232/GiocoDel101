import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/router/app_router.dart';
import '../application/table_controller.dart';
import '../../online/application/online_match_launcher.dart';
import '../../settings/application/settings_controller.dart';
import '../../profile/application/stats_controller.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/motion.dart';
import '../../achievements/domain/achievements_catalog.dart';
import '../../../app/localization/app_strings.dart';
import '../domain/round_result.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/avatar_medallion.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/app_icons.dart';
import 'widgets/centouno_flourish.dart';
import 'widgets/fate_ring.dart';
import 'last_hand_replay.dart';

/// §36 Screen 5 — the round is scored, one player at a time.
///
/// Rows reveal in sequence: cards left, penalty, and the running total
/// counting up. A player who lands on exactly 101 gets the full Fate Ring
/// reset; a player who overshoots gets the fractured ring.
class RoundResultScreen extends StatefulWidget {
  const RoundResultScreen({super.key});

  @override
  State<RoundResultScreen> createState() => _RoundResultScreenState();
}

class _RoundResultScreenState extends State<RoundResultScreen> {
  final TableController c = Get.find<TableController>();
  final SettingsController settings = Get.find<SettingsController>();
  final StatsController stats = Get.find<StatsController>();

  late final RoundResult result;
  int _revealed = 0;
  bool _replaying = false;
  String? _resetting;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    result =
        c.lastRoundResult.value ??
        const RoundResult(
          roundNumber: 0,
          winnerId: '',
          winnerName: '',
          rows: [],
          matchOver: false,
        );
    if (!c.isOnline) {
      // Online, the server is the only bookkeeper (docs/SECURITY.md).
      unawaited(
        stats.recordRound(
          match: c.state,
          result: result,
          humanId: c.humanIds.first,
        ),
      );
    }
    _dealtElsewhere = ever<RoundResult?>(c.lastRoundResult, (value) {
      // Another seat (or the server's 30 s deal) started the next round:
      // this sheet has nothing left to say.
      if (value == null &&
          mounted &&
          Get.currentRoute == AppRoutes.roundResult) {
        Get.back<void>();
      }
    });
    _revealNext();
  }

  Worker? _dealtElsewhere;

  void _revealNext() {
    _timer?.cancel();
    if (_revealed >= result.rows.length) {
      if (result.matchOver) {
        _timer = Timer(const Duration(milliseconds: 700), _goToMatchResult);
      }
      return;
    }
    final row = result.rows[_revealed];
    setState(() => _revealed++);

    if (row.hitExact101) {
      // §17 — the signature moment gets the whole stage for a beat.
      setState(() => _resetting = row.playerId);
      AudioService.instance.play(Sfx.reset101);
      HapticService.instance.strong();
      _timer = Timer(Motion.scale(const Duration(milliseconds: 2400)), () {
        if (mounted) setState(() => _resetting = null);
        _revealNext();
      });
      return;
    }
    if (row.eliminated) {
      AudioService.instance.play(Sfx.eliminate);
      HapticService.instance.strong();
    } else if (row.penalty > 0) {
      AudioService.instance.play(Sfx.scoreTick, volume: 0.8);
    }
    _timer = Timer(
      Motion.scale(const Duration(milliseconds: 620)),
      _revealNext,
    );
  }

  void _goToMatchResult() {
    if (!mounted) return;
    if (!c.isOnline) {
      unawaited(stats.recordMatch(match: c.state, humanId: c.humanIds.first));
    }
    Get.offNamed<void>(AppRoutes.matchResult);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dealtElsewhere?.dispose();
    super.dispose();
  }

  Future<void> _nextRound() async {
    Get.back<void>();
    await c.beginNextRound();
  }

  Future<void> _exit() async {
    await c.abandon();
    Get.until((route) => route.settings.name == AppRoutes.home);
    if (c.isOnline) OnlineMatchLauncher.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final theme = settings.theme;
    final done = _revealed >= result.rows.length;
    final newBadges = stats.pendingAchievements;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.backdropTop.withValues(alpha: 0.96),
        body: Stack(
          children: [
            AppBackground(
              theme: theme,
              motifStrength: 0.5,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Text(s.roundComplete, style: AppText.sectionTitle),
                    const SizedBox(height: AppSpacing.md),
                    _winnerBadge(theme.accent),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.gutter,
                        ),
                        itemCount: result.rows.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) => AnimatedOpacity(
                          duration: Motion.scale(
                            const Duration(milliseconds: 300),
                          ),
                          opacity: i < _revealed ? 1 : 0.18,
                          child: _row(result.rows[i], theme.accent),
                        ),
                      ),
                    ),
                    if (newBadges.isNotEmpty) _achievements(newBadges),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.gutter),
                      child: Column(
                        children: [
                          if (LastHandReplay.isAvailable(c.state))
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: PremiumButton(
                                label: s.replayLastHand,
                                variant: ButtonVariant.ghost,
                                size: ButtonSize.small,
                                icon: AppIcon.restart,
                                onPressed: () =>
                                    setState(() => _replaying = true),
                              ),
                            ),
                          if (!result.matchOver)
                            PremiumButton(
                              label: s.nextRound,
                              accent: theme.accent,
                              icon: AppIcon.play,
                              onPressed: done ? _nextRound : null,
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          PremiumButton(
                            label: result.matchOver
                                ? s.matchWinner
                                : s.exitToMenu,
                            variant: ButtonVariant.secondary,
                            size: ButtonSize.medium,
                            onPressed: result.matchOver
                                ? (done ? _goToMatchResult : null)
                                : _exit,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_resetting != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: AppColors.inkDeep.withValues(alpha: 0.55),
                    child: Center(
                      child: CentounoFlourish(
                        playerName: c.state.playerById(_resetting!)?.name ?? '',
                        accent: theme.accent,
                      ),
                    ),
                  ),
                ),
              ),
            if (_replaying)
              Positioned.fill(
                child: LastHandReplay(
                  match: c.state,
                  accent: theme.accent,
                  onClose: () => setState(() => _replaying = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _winnerBadge(Color accent) {
    final winner = c.state.playerById(result.winnerId);
    if (winner == null) return const SizedBox.shrink();
    return Column(
      children: [
        AvatarMedallion(avatarId: winner.avatarId, size: 64, active: true),
        const SizedBox(height: AppSpacing.sm),
        Text(
          winner.name,
          style: AppText.body.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
        Text(Strings.s.roundWinner, style: AppText.caption),
      ],
    );
  }

  Widget _row(PlayerRoundResult row, Color accent) {
    final player = c.state.playerById(row.playerId);
    final isResetting = _resetting == row.playerId;

    return AppPanel(
      accent: row.eliminated
          ? AppColors.danger
          : row.hitExact101
          ? AppColors.goldLight
          : accent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          FateRing(
            score: row.newScore,
            size: 56,
            target: c.state.rules.targetScore,
            eliminated: row.eliminated,
            playReset: isResetting,
            showLabel: false,
            accent: accent,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (player != null)
                      AvatarMedallion(avatarId: player.avatarId, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${row.cardsLeft} ${Strings.s.cardsLeft} · '
                  '${Strings.s.penalty} ${row.penalty}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _scoreChange(row),
        ],
      ),
    );
  }

  Widget _scoreChange(PlayerRoundResult row) {
    if (row.eliminated) {
      return Text(
        Strings.s.eliminated,
        style: AppText.label.copyWith(color: AppColors.danger, fontSize: 11),
      );
    }
    if (row.hitExact101) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${row.previousScore} + ${row.penalty}', style: AppText.caption),
          Text(
            Strings.s.savedFrom101,
            style: AppText.label.copyWith(
              color: AppColors.goldLight,
              fontSize: 12,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('${row.previousScore} + ${row.penalty}', style: AppText.caption),
        TweenAnimationBuilder<double>(
          tween: Tween(
            begin: row.previousScore.toDouble(),
            end: row.newScore.toDouble(),
          ),
          duration: Motion.scale(const Duration(milliseconds: 620)),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => Text(
            '${value.round()}',
            style: AppText.scoreSmall.copyWith(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _achievements(List<String> ids) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final id in ids)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                color: AppColors.goldMid.withValues(alpha: 0.16),
                border: Border.all(
                  color: AppColors.goldMid.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIconView(
                    AppIcon.trophy,
                    size: 14,
                    color: AppColors.goldLight,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    Strings.s.achievementTitle(id),
                    style: AppText.caption.copyWith(color: AppColors.goldLight),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
