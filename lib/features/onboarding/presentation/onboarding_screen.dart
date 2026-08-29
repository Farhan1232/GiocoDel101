import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/cards/playing_card.dart';
import '../../../core/widgets/premium_button.dart';
import '../../game/domain/card_rank.dart';
import '../../game/domain/card_suit.dart';
import '../../game/domain/game_card.dart';
import '../../settings/application/settings_controller.dart';

/// First run — three pages, then never again (§B).
///
/// Completion is written to the settings blob, so a reinstall shows it once
/// more and an update does not.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  final SettingsController _settings = Get.find<SettingsController>();

  int _index = 0;

  static const int _pageCount = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pageCount - 1;

  Future<void> _finish() async {
    await _settings.completeOnboarding();
    await Get.offAllNamed<void>(AppRoutes.home);
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _pages.nextPage(
      duration: Motion.scale(AppDurations.screenTransition),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return Obx(() {
      final theme = _settings.theme;
      return Scaffold(
        backgroundColor: theme.backdropTop,
        body: AppBackground(
          theme: theme,
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AppSpacing.sm,
                      AppSpacing.gutter,
                      0,
                    ),
                    child: TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        // 48dp target even though the label is short (§8).
                        minimumSize: const Size(64, 48),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: Text(s.commonSkip, style: AppText.label),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (i) => setState(() => _index = i),
                    children: [
                      _Page(
                        art: const _DeckArt(),
                        title: s.onboard1Title,
                        body: s.onboard1Body,
                        accent: theme.accent,
                      ),
                      _Page(
                        art: const _RulesArt(),
                        title: s.onboard2Title,
                        body: s.onboard2Body,
                        accent: theme.accent,
                      ),
                      _Page(
                        art: const _FriendsArt(),
                        title: s.onboard3Title,
                        body: s.onboard3Body,
                        accent: theme.accent,
                      ),
                    ],
                  ),
                ),
                _dots(theme.accent),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.lg,
                    AppSpacing.gutter,
                    AppSpacing.xl,
                  ),
                  child: PremiumButton(
                    label: _isLast ? s.commonStart : s.commonNext,
                    accent: theme.accent,
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _dots(Color accent) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < _pageCount; i++)
        AnimatedContainer(
          duration: AppDurations.quick,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: i == _index ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == _index ? accent : AppColors.hairline,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
    ],
  );
}

class _Page extends StatelessWidget {
  const _Page({
    required this.art,
    required this.title,
    required this.body,
    required this.accent,
  });

  final Widget art;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: box.maxHeight * 0.06),
              SizedBox(
                height: box.maxHeight * 0.42,
                child: Center(child: art),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.screenTitle.copyWith(fontSize: 22),
              ),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: AppColors.textSecondary),
                ),
              ),
              SizedBox(height: box.maxHeight * 0.06),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page 1 — three real cards from the real deck, fanned.
class _DeckArt extends StatelessWidget {
  const _DeckArt();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth * 0.32).clamp(74.0, 130.0);
        const cards = [
          GameCard(CardSuit.denari, CardRank.re),
          GameCard(CardSuit.coppe, CardRank.cavallo),
          GameCard(CardSuit.bastoni, CardRank.fante),
        ];
        return Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < cards.length; i++)
              Transform.translate(
                offset: Offset((i - 1) * width * 0.62, (i == 1 ? -10 : 6)),
                child: Transform.rotate(
                  angle: (i - 1) * 0.16,
                  child: PlayingCard(
                    width: width,
                    card: cards[i],
                    elevation: i == 1 ? 1.0 : 0.7,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Page 2 — the three special cards the rules turn on.
class _RulesArt extends StatelessWidget {
  const _RulesArt();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth * 0.26).clamp(64.0, 108.0);
        const cards = [
          GameCard(CardSuit.spade, CardRank.ace),
          GameCard(CardSuit.coppe, CardRank.two),
          GameCard(CardSuit.denari, CardRank.cavallo),
        ];
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < cards.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Transform.rotate(
                  angle: (i - 1) * 0.08,
                  child: PlayingCard(width: width, card: cards[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Page 3 — four backs around a table, one per seat.
class _FriendsArt extends StatelessWidget {
  const _FriendsArt();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest.shortestSide;
        final width = (size * 0.24).clamp(52.0, 92.0);
        final radius = size * 0.34;
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: radius * 2.05,
                height: radius * 2.05,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceSunken.withValues(alpha: 0.7),
                  border: Border.all(color: AppColors.hairline),
                ),
              ),
              for (var i = 0; i < 4; i++)
                Transform.translate(
                  offset: Offset(
                    [0.0, 1.0, 0.0, -1.0][i] * radius,
                    [1.0, 0.0, -1.0, 0.0][i] * radius,
                  ),
                  child: Transform.rotate(
                    angle: i * 1.5707963,
                    child: PlayingCard(width: width, faceUp: false),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
