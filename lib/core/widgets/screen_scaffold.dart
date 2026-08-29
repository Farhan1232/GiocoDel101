import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/table_themes.dart';
import '../../features/settings/application/settings_controller.dart';
import '../constants/app_spacing.dart';
import 'app_background.dart';
import 'app_icons.dart';
import 'icon_pill.dart';

/// The frame every non-table screen sits in.
///
/// One place decides the painted backdrop, the safe area, the title bar and
/// the Android back affordance, so no screen re-invents them and none of them
/// drifts (§6). The body is handed the remaining space and is expected to
/// scroll itself when it needs to.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.child,
    this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.banner,
    this.scrollable = true,
    this.padding =
        const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
    this.maxContentWidth = 560,
  });

  final Widget child;
  final String? title;
  final bool showBack;

  /// Overrides the default `Get.back()`, e.g. to confirm before leaving.
  final VoidCallback? onBack;

  final Widget? trailing;

  /// Sits directly under the title bar — used for the network status shell.
  final Widget? banner;

  /// When false the child is laid out at full height and manages its own
  /// scrolling (the room lobby and the matchmaking screen do).
  final bool scrollable;

  final EdgeInsets padding;

  /// Tablets get a centred column rather than a stretched one (§7).
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Obx(() {
      final TableTheme theme = settings.theme;
      return Scaffold(
        backgroundColor: theme.backdropTop,
        body: AppBackground(
          theme: theme,
          child: SafeArea(
            child: Column(
              children: [
                if (title != null || showBack || trailing != null)
                  _bar(theme),
                ?banner,
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: scrollable
                          ? LayoutBuilder(
                              builder: (context, box) => SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                padding: padding,
                                child: ConstrainedBox(
                                  constraints:
                                      BoxConstraints(minHeight: box.maxHeight),
                                  child: child,
                                ),
                              ),
                            )
                          : Padding(padding: padding, child: child),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _bar(TableTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (showBack)
            IconPill(
              icon: AppIcon.back,
              accent: theme.accent,
              onTap: onBack ?? () => Get.back<void>(),
            )
          else
            const SizedBox(width: 44),
          Expanded(
            child: Text(
              title ?? '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.screenTitle.copyWith(
                fontSize: 18,
                color: theme.isLight ? AppColors.inkDeep : AppColors.textPrimary,
              ),
            ),
          ),
          // Balances the row so the title stays optically centred.
          SizedBox(width: 44, child: trailing),
        ],
      ),
    );
  }
}
