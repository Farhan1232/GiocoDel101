import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../game/application/match_launcher.dart';
import '../../../app/router/app_router.dart';
import '../application/home_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../../profile/application/stats_controller.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../app/localization/app_strings.dart';
import '../../game/domain/match_factory.dart';
import '../../../core/storage/game_storage_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/cards/playing_card.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/avatar_medallion.dart';
import '../../../core/widgets/icon_pill.dart';
import '../../../core/widgets/logo_101.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/app_icons.dart';

/// §25 Screen 2 — the identity screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final HomeController _home = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(
          HomeController(Get.find<GameStorageService>()),
          permanent: true,
        );
  late final SettingsController _settings = Get.find<SettingsController>();
  late final StatsController _stats = Get.find<StatsController>();

  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _refresh() => _home.refreshSavedMatch();

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final media = MediaQuery.sizeOf(context);
    final compact = media.height < 700;

    return Obx(() {
      final theme = _settings.theme;
      return Scaffold(
        backgroundColor: theme.backdropTop,
        body: AppBackground(
          theme: theme,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  child: _topBar(theme.accent),
                ),
                // The middle scrolls on short devices; the deck fan stays
                // anchored to the foot of the screen on every size (§47).
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                      ),
                      // Centred in the space between the top bar and the
                      // deck, and scrollable when a short screen needs it.
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: compact ? AppSpacing.lg : AppSpacing.xxl,
                            ),
                            _stagger(0.0, LogoLockup(size: compact ? 74 : 92)),
                            SizedBox(
                              height: compact ? AppSpacing.xl : AppSpacing.xxl,
                            ),
                            _stagger(
                              0.12,
                              PremiumButton(
                                label: s.play,
                                icon: AppIcon.play,
                                accent: theme.accent,
                                onPressed: () async {
                                  await Get.toNamed<void>(AppRoutes.setup);
                                  _refresh();
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (_home.hasSavedMatch.value)
                              _stagger(
                                0.18,
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: _actionCard(
                                    icon: AppIcon.resume,
                                    title: s.resumeMatch,
                                    subtitle: s.resumeMatchHint,
                                    accent: AppColors.mediterraneanTeal,
                                    onTap: () async {
                                      if (!MatchLauncher.resume()) _refresh();
                                    },
                                  ),
                                ),
                              ),
                            _stagger(0.24, _dailyCard(theme.accent)),
                            const SizedBox(height: AppSpacing.md),
                            _stagger(
                              0.30,
                              _actionCard(
                                icon: AppIcon.rules,
                                title: s.howToPlay,
                                subtitle: s.howToPlayHint,
                                accent: AppColors.warmIvory,
                                onTap: () =>
                                    Get.toNamed<void>(AppRoutes.howToPlay),
                              ),
                            ),
                            SizedBox(
                              height: compact ? AppSpacing.lg : AppSpacing.xl,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _stagger(0.4, _deckFan(compact ? 58 : 70)),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Content arrives in a short cascade rather than all at once (§58).
  Widget _stagger(double delay, Widget child) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, inner) {
        final t = ((_entrance.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 18),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }

  Widget _topBar(Color accent) {
    return Row(
      children: [
        IconPill(
          icon: AppIcon.settings,
          accent: accent,
          tooltip: Strings.s.settings,
          onTap: () async {
            await Get.toNamed<void>(AppRoutes.settings);
            _refresh();
          },
        ),
        const Spacer(),
        _profileMedallion(),
        const Spacer(),
        Obx(
          () => IconPill(
            icon: AppIcon.stats,
            accent: accent,
            tooltip: Strings.s.statistics,
            badge: _stats.pendingAchievements.isNotEmpty
                ? const NotificationDot()
                : null,
            onTap: () =>
                Get.toNamed<void>(AppRoutes.settings, arguments: {'tab': 1}),
          ),
        ),
      ],
    );
  }

  Widget _profileMedallion() {
    return Semantics(
      label: Strings.s.profile,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarMedallion(avatarId: _settings.settings.avatarId, size: 38),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              _settings.settings.playerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyCard(Color accent) {
    return Obx(() {
      final done = _stats.dailyCompletedToday;
      final challenge = _home.challenge;
      return _actionCard(
        icon: AppIcon.calendar,
        title: Strings.s.dailyChallenge,
        subtitle: done ? Strings.s.dailyChallengeDone : challenge.title,
        accent: done ? AppColors.success : accent,
        trailing: done
            ? const AppIconView(
                AppIcon.check,
                size: 20,
                color: AppColors.success,
              )
            : null,
        onTap: () {
          final setup = MatchFactory.dailyChallenge(
            challenge: challenge,
            playerName: _settings.settings.playerName,
            avatarId: _settings.settings.avatarId,
          );
          MatchLauncher.launch(setup);
        },
      );
    });
  }

  Widget _actionCard({
    required AppIcon icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return AppPanel(
      accent: accent,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Center(child: AppIconView(icon, size: 20, color: accent)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          trailing ??
              AppIconView(
                AppIcon.play,
                size: 14,
                color: accent.withValues(alpha: 0.55),
              ),
        ],
      ),
    );
  }

  /// A small fanned deck anchoring the foot of the screen (§25).
  ///
  /// Only the top of the fan shows: the cards are clipped to a fixed band so
  /// they read as a deck resting just off the bottom edge, and never spill.
  Widget _deckFan(double cardWidth) {
    final backId = _settings.settings.cardBackId;
    final bandHeight = cardWidth * 0.92;
    return IgnorePointer(
      child: ClipRect(
        child: SizedBox(
          height: bandHeight,
          width: double.infinity,
          child: OverflowBox(
            maxHeight: cardWidth * 1.9,
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: cardWidth * 1.9,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  for (var i = -2; i <= 2; i++)
                    Transform.translate(
                      offset: Offset(i * cardWidth * 0.46, i.abs() * 9.0),
                      child: Transform.rotate(
                        angle: i * 0.13,
                        child: Opacity(
                          opacity: 1 - i.abs() * 0.16,
                          child: PlayingCard(
                            width: cardWidth,
                            faceUp: false,
                            backId: backId,
                            elevation: 0.5,
                            tilt: i * 0.05,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
