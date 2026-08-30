import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../application/match_launcher.dart';
import '../../../app/router/app_router.dart';
import 'dart:async';

import '../application/table_controller.dart';
import '../../online/application/online_match_controller.dart';
import '../../online/application/online_match_launcher.dart';
import '../../profile/application/profile_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../app/localization/app_strings.dart';
import '../domain/match_factory.dart';
import '../domain/game_player.dart';
import '../domain/game_state.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/avatar_medallion.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/app_icons.dart';
import 'victory_flourish.dart';

/// §37 Screen 6 — the match is over.
class MatchResultScreen extends StatefulWidget {
  const MatchResultScreen({super.key});

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> {
  final TableController c = Get.find<TableController>();
  final SettingsController settings = Get.find<SettingsController>();

  @override
  void initState() {
    super.initState();
    AudioService.instance.play(Sfx.victory);
    HapticService.instance.strong();
    // §49 — a finished match must never reappear as "Continua partita".
    c.persistNow();
    // Online: the server has settled XP, streaks and badges by now.
    if (c.isOnline && Get.isRegistered<ProfileController>()) {
      unawaited(Get.find<ProfileController>().reload());
    }
  }

  GamePlayer? get _winner =>
      c.state.winnerId == null ? null : c.state.playerById(c.state.winnerId!);

  Timer? _rematchPoll;
  Worker? _nextMatch;

  void _rematch() {
    final online = c;
    if (online is OnlineMatchController) {
      unawaited(online.requestRematch());
      _rematchPoll ??= Timer.periodic(
        const Duration(seconds: 3),
        (_) => online.pollRematch(),
      );
      _nextMatch ??= ever<String?>(online.nextMatchId, (id) {
        if (id != null && mounted) {
          _rematchPoll?.cancel();
          unawaited(OnlineMatchLauncher.launch(id, replace: true));
        }
      });
      return;
    }
    final state = c.state;
    final setup = state.mode == GameMode.vsComputer
        ? MatchFactory.vsComputer(
            playerName: settings.settings.playerName,
            avatarId: settings.settings.avatarId,
            playerCount: state.players.length,
            difficulty:
                state.players
                    .firstWhere(
                      (p) => p.isBot,
                      orElse: () => state.players.first,
                    )
                    .difficulty ??
                settings.settings.defaultDifficulty,
            rules: state.rules,
          )
        : MatchFactory.passAndPlay(
            names: state.players.map((p) => p.name).toList(),
            avatarIds: state.players.map((p) => p.avatarId).toList(),
            rules: state.rules,
          );
    MatchLauncher.launch(setup, replace: true);
  }

  void _home() {
    Get.until((route) => route.settings.name == AppRoutes.home);
    if (c.isOnline) OnlineMatchLauncher.dismiss();
  }

  @override
  void dispose() {
    _rematchPoll?.cancel();
    _nextMatch?.dispose();
    super.dispose();
  }

  /// Online: the rematch is a vote; show where it stands.
  Widget _rematchStatus() {
    final online = c;
    if (online is! OnlineMatchController) return const SizedBox.shrink();
    return Obx(() {
      if (!online.rematchRequested.value) return const SizedBox.shrink();
      final s = Strings.s;
      final text = online.nextMatchId.value != null
          ? s.lobbyStarting
          : s.onlineRematchWaiting(
              online.rematchVotes.value,
              online.rematchNeeded.value,
            );
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          text,
          style: AppText.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final theme = settings.theme;
    final winner = _winner;
    final stats = c.state.stats;
    final humanWon = winner?.id == c.humanIds.first;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.backdropTop,
        body: AppBackground(
          theme: theme,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Text(s.matchWinner, style: AppText.sectionTitle),
                        SizedBox(
                          height: 190,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VictoryFlourish(size: 190, accent: theme.accent),
                            ],
                          ),
                        ),
                        if (winner != null) ...[
                          AvatarMedallion(
                            avatarId: winner.avatarId,
                            size: 76,
                            active: true,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            winner.name,
                            style: AppText.heroTitle.copyWith(
                              fontSize: 30,
                              letterSpacing: 3,
                              color: humanWon
                                  ? AppColors.goldLight
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${winner.score} ${s.finalPoints.toLowerCase()}',
                            style: AppText.caption,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        AppPanel(
                          accent: theme.accent,
                          child: Column(
                            children: [
                              _stat(
                                AppIcon.restart,
                                s.roundsPlayed,
                                '${c.state.round}',
                              ),
                              _divider(),
                              _stat(
                                AppIcon.cards,
                                s.cardsPlayed,
                                '${stats.cardsPlayed}',
                              ),
                              _divider(),
                              _stat(
                                AppIcon.chain,
                                s.longestChain,
                                stats.longestChain == 0
                                    ? '—'
                                    : '+${stats.longestChain * c.state.rules.drawTwoPenalty}',
                              ),
                              _divider(),
                              _stat(
                                AppIcon.ring,
                                s.bestComeback,
                                stats.bestComeback <= 0
                                    ? '—'
                                    : '${stats.bestComeback}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _finalTable(theme.accent),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: Column(
                    children: [
                      _rematchStatus(),
                      PremiumButton(
                        label: s.rematch,
                        accent: theme.accent,
                        icon: AppIcon.restart,
                        onPressed: _rematch,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          if (!c.isOnline) ...[
                            Expanded(
                              child: PremiumButton(
                                label: s.newMatch,
                                variant: ButtonVariant.secondary,
                                // Small keeps "Nuova Partita" from
                                // ellipsising when it shares the row with
                                // Home.
                                size: ButtonSize.small,
                                onPressed: () {
                                  Get.until(
                                    (route) =>
                                        route.settings.name == AppRoutes.home,
                                  );
                                  Get.toNamed<void>(AppRoutes.setup);
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                          ],
                          Expanded(
                            child: PremiumButton(
                              label: s.home,
                              variant: ButtonVariant.ghost,
                              size: ButtonSize.small,
                              icon: AppIcon.home,
                              onPressed: _home,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() =>
      const Divider(color: AppColors.hairline, height: AppSpacing.lg);

  Widget _stat(AppIcon icon, String label, String value) => Row(
    children: [
      AppIconView(icon, size: 17, color: AppColors.textSecondary),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Text(label, style: AppText.bodySmall)),
      Text(value, style: AppText.scoreSmall.copyWith(fontSize: 15)),
    ],
  );

  Widget _finalTable(Color accent) {
    final players = List<GamePlayer>.of(c.state.players)
      ..sort((a, b) {
        if (a.eliminated != b.eliminated) return a.eliminated ? 1 : -1;
        return a.score.compareTo(b.score);
      });
    return Column(
      children: [
        for (final p in players)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppPanel(
              accent: p.eliminated ? AppColors.danger : accent,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  AvatarMedallion(
                    avatarId: p.avatarId,
                    size: 32,
                    dimmed: p.eliminated,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(fontSize: 14),
                    ),
                  ),
                  if (p.eliminated)
                    Text(
                      Strings.s.eliminated,
                      style: AppText.caption.copyWith(
                        color: AppColors.danger,
                        fontSize: 10,
                      ),
                    )
                  else
                    Text(
                      '${p.score}',
                      style: AppText.scoreSmall.copyWith(fontSize: 15),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
