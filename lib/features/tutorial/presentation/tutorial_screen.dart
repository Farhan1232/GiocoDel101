import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/motion.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/premium_button.dart';
import '../../game/presentation/game_screen.dart';
import '../../game/presentation/widgets/centouno_flourish.dart';
import '../../settings/application/settings_controller.dart';
import '../application/tutorial_controller.dart';
import '../application/tutorial_launcher.dart';
import '../domain/tutorial_lessons.dart';
import 'tutorial_copy.dart';

/// §X — the real table with a lesson card floating over it.
///
/// [GameScreen] draws and animates exactly as in a match; the overlay
/// only tells the player what to do and, once done, what just happened.
class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TutorialController>();
    final settings = Get.find<SettingsController>();
    return Stack(
      fit: StackFit.expand,
      children: [
        const GameScreen(),
        Positioned.fill(
          child: Obx(() {
            c.revision.value;
            return _TutorialOverlay(
              controller: c,
              accent: settings.theme.accent,
            );
          }),
        ),
      ],
    );
  }
}

class _TutorialOverlay extends StatelessWidget {
  const _TutorialOverlay({required this.controller, required this.accent});

  final TutorialController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final s = Strings.s;
    if (c.phase.value == TutorialPhase.finished) {
      return _finished(context, s);
    }
    final lesson = c.lesson;
    final done = c.phase.value == TutorialPhase.lessonDone;
    final opponent = c.opponents.first.name;
    final text = done
        ? s.tutorialLessonDone(
            lesson.id,
            suit: c.chosenSuit.value,
            opponent: opponent,
          )
        : s.tutorialLessonPrompt(lesson.id, c.stepIndex.value);
    final hint = c.hint.value;
    final showCentouno = done && lesson.id == TutorialLessonId.centouno;

    return IgnorePointer(
      ignoring: !done,
      child: SafeArea(
        child: Column(
          children: [
            // Under the top bar, above the opponent's seat.
            const SizedBox(height: 56),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _card(
                key: ValueKey('${lesson.id.key}-${c.stepIndex.value}-$done'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _badge(
                          '${c.lessonIndex.value + 1}/${c.lessons.length}',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            s.tutorialLessonTitle(lesson.id),
                            style: AppText.body.copyWith(
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                        if (done)
                          const AppIconView(
                            AppIcon.check,
                            size: 16,
                            color: AppColors.success,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(text, style: AppText.bodySmall),
                    if (hint != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        hint,
                        style: AppText.caption.copyWith(
                          color: AppColors.terracottaCoral,
                        ),
                      ),
                    ],
                    if (done) ...[
                      const SizedBox(height: AppSpacing.md),
                      PremiumButton(
                        label: c.isLastLesson ? s.tutorialFinish : s.commonNext,
                        accent: accent,
                        size: ButtonSize.small,
                        icon: AppIcon.play,
                        onPressed: c.next,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (showCentouno)
              Expanded(
                child: Center(
                  child: _card(
                    key: const ValueKey('centouno'),
                    child: CentounoFlourish(
                      playerName: opponent,
                      accent: accent,
                      ringSize: 96,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _finished(BuildContext context, AppLocalizations s) {
    return ColoredBox(
      color: AppColors.inkDeep.withValues(alpha: 0.78),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _card(
              key: const ValueKey('finished'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.tutorialCompleteTitle,
                    textAlign: TextAlign.center,
                    style: AppText.screenTitle.copyWith(
                      fontSize: 22,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    s.tutorialCompleteBody,
                    textAlign: TextAlign.center,
                    style: AppText.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PremiumButton(
                    label: s.tutorialPlayNow,
                    accent: accent,
                    icon: AppIcon.play,
                    onPressed: () {
                      Get.until((r) => r.settings.name == AppRoutes.home);
                      TutorialLauncher.dismiss();
                      Get.toNamed<void>(AppRoutes.setup);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PremiumButton(
                    label: s.tutorialReplay,
                    variant: ButtonVariant.secondary,
                    size: ButtonSize.small,
                    onPressed: controller.restart,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PremiumButton(
                    label: s.home,
                    variant: ButtonVariant.ghost,
                    size: ButtonSize.small,
                    icon: AppIcon.home,
                    onPressed: () {
                      Get.until((r) => r.settings.name == AppRoutes.home);
                      TutorialLauncher.dismiss();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Key key, required Widget child}) {
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0, end: 1),
      duration: Motion.scale(const Duration(milliseconds: 280)),
      curve: Curves.easeOutCubic,
      builder: (context, t, inner) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * -10),
          child: inner,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          color: AppColors.surfaceRaised.withValues(alpha: 0.96),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.inkDeep.withValues(alpha: 0.5),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: accent.withValues(alpha: 0.55)),
    ),
    child: Text(
      text,
      style: AppText.caption.copyWith(color: accent, fontSize: 10.5),
    ),
  );
}
