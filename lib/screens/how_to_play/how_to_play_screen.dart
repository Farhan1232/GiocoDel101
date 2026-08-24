import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/motion.dart';
import '../../data/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/icon_pill.dart';
import '../../widgets/common/premium_button.dart';
import '../../widgets/icons/app_icons.dart';
import 'tutorial_figures.dart';

/// §38 Screen 7 — the rules, shown rather than written out.
///
/// Ten swipeable cards, each carrying a real illustration built from the same
/// deck the game deals, so nothing here can drift from the actual rules.
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final PageController _pages = PageController();
  final SettingsController settings = Get.find<SettingsController>();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<_Lesson> _lessons(double cw) {
    final s = Strings.s;
    return [
      _Lesson(s.tutorialGoal, s.tutorialGoalBody, TutorialFigures.goal(cw)),
      _Lesson(
        s.tutorialMatch,
        s.tutorialMatchBody,
        TutorialFigures.matching(cw),
      ),
      _Lesson(
        s.tutorialDraw,
        s.tutorialDrawBody,
        TutorialFigures.drawing(cw, settings.settings.cardBackId),
      ),
      _Lesson(s.tutorialAce, s.tutorialAceBody, TutorialFigures.ace(cw)),
      _Lesson(s.tutorialTwo, s.tutorialTwoBody, TutorialFigures.chain(cw)),
      _Lesson(
        s.tutorialCavallo,
        s.tutorialCavalloBody,
        TutorialFigures.cavallo(cw),
      ),
      _Lesson(
        s.tutorialScoring,
        s.tutorialScoringBody,
        TutorialFigures.scoring(cw),
      ),
      _Lesson(s.tutorial101, s.tutorial101Body, TutorialFigures.reset101()),
      _Lesson(
        s.tutorialOver101,
        s.tutorialOver101Body,
        TutorialFigures.eliminated(),
      ),
      _Lesson(s.tutorialWin, s.tutorialWinBody, TutorialFigures.victory(cw)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = settings.theme;
    final width = MediaQuery.sizeOf(context).width;
    final cw = (width * 0.19).clamp(52.0, 92.0);
    final lessons = _lessons(cw);

    return Scaffold(
      backgroundColor: theme.backdropTop,
      body: AppBackground(
        theme: theme,
        motifStrength: 0.6,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.md,
                  AppSpacing.gutter,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconPill(icon: AppIcon.back, onTap: Get.back<void>),
                    Expanded(
                      child: Text(
                        Strings.s.howToPlay,
                        textAlign: TextAlign.center,
                        style: AppText.screenTitle.copyWith(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: lessons.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _page(lessons[i], i),
                ),
              ),
              _dots(lessons.length, theme.accent),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: PremiumButton(
                  label: _index == lessons.length - 1 ? 'Ho capito' : 'Avanti',
                  accent: theme.accent,
                  size: ButtonSize.medium,
                  onPressed: () {
                    if (_index == lessons.length - 1) {
                      Get.back<void>();
                    } else {
                      _pages.nextPage(
                        duration: Motion.scale(
                          const Duration(milliseconds: 320),
                        ),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _page(_Lesson lesson, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(flex: 5, child: Center(child: lesson.figure)),
          Expanded(
            flex: 4,
            // Long copy on a 360x640 screen must scroll, not overflow (§47).
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.antiqueGold.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: AppText.caption.copyWith(
                            color: AppColors.antiqueGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Text(
                          lesson.title,
                          style: AppText.screenTitle.copyWith(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    lesson.body,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(fontSize: 14.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dots(int count, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: i == _index
                    ? accent
                    : AppColors.warmIvory.withValues(alpha: 0.25),
              ),
            ),
        ],
      ),
    );
  }
}

class _Lesson {
  const _Lesson(this.title, this.body, this.figure);

  final String title;
  final String body;
  final Widget figure;
}
