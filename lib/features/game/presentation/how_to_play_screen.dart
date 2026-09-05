import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../settings/application/settings_controller.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/motion.dart';
import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/icon_pill.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_panel.dart';
import '../../tutorial/application/tutorial_launcher.dart';
import '../domain/game_rules.dart';
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

  /// The house rules of the table this screen was opened from, if any.
  GameRules? get _activeRules {
    final args = Get.arguments;
    return args is Map && args['rules'] is GameRules
        ? args['rules'] as GameRules
        : null;
  }

  int get _activeTimer {
    final args = Get.arguments;
    return args is Map ? (args['turnTimer'] as int? ?? 0) : 0;
  }

  /// A table is on screen underneath: offer the tutorial only from Home.
  bool get _fromTable => _activeRules != null;

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
                    IconPill(
                      icon: AppIcon.back,
                      tooltip: Strings.s.commonBack,
                      onTap: Get.back<void>,
                    ),
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
                  label: _index == lessons.length - 1
                      ? Strings.s.gotIt
                      : Strings.s.commonNext,
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
    final rules = _activeRules;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (index == 0 && rules != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: _ActiveRulesPanel(
                rules: rules,
                turnTimer: _activeTimer,
                accent: settings.theme.accent,
              ),
            )
          else if (index == 0 && !_fromTable)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: PremiumButton(
                label: Strings.s.tutorialTitle,
                icon: AppIcon.cards,
                variant: ButtonVariant.secondary,
                size: ButtonSize.small,
                onPressed: () {
                  Get.back<void>();
                  TutorialLauncher.launch();
                },
              ),
            ),
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

/// §M — "which rules is this table playing by?", answered from the match's
/// own [GameRules] rather than from whatever the setup screen last showed.
class _ActiveRulesPanel extends StatelessWidget {
  const _ActiveRulesPanel({
    required this.rules,
    required this.turnTimer,
    required this.accent,
  });

  final GameRules rules;
  final int turnTimer;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    String onOff(bool v) => v ? s.commonOn : s.commonOff;
    final rows = <(String, String)>[
      (s.startingHand, '${rules.startingHandSize}'),
      (s.ruleStackTwos, onOff(rules.stackDrawTwos)),
      (s.ruleWildNine, onOff(rules.wildNineCanAlwaysPlay)),
      (
        s.ruleNineBlock,
        switch (rules.nineBlockMode) {
          NineBlockMode.cancel => s.ruleNineBlockCancel,
          NineBlockMode.passOn => s.ruleNineBlockPassOn,
          NineBlockMode.disabled => s.ruleNineBlockDisabled,
        },
      ),
      (s.ruleVoluntaryDraw, onOff(rules.allowVoluntaryDraw)),
      (s.ruleEliminate, onOff(rules.eliminateAbove101)),
      (s.ruleExactReset, onOff(rules.exact101ResetsToZero)),
      (
        s.createRoomTimer,
        turnTimer > 0
            ? s.createRoomTimerSeconds(turnTimer)
            : s.createRoomTimerOff,
      ),
    ];
    return AppPanel(
      accent: accent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.rulesActiveTitle.toUpperCase(),
            style: AppText.label.copyWith(color: accent),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: AppText.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    row.$2,
                    style: AppText.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
