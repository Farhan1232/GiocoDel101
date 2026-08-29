import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../constants/app_spacing.dart';
import 'app_panel.dart';
import 'premium_button.dart';

/// The game's dialog shell — a gold panel rather than a Material card.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.body,
    this.content,
    this.actions = const [],
  });

  final String title;
  final String? body;

  /// Replaces [body] when a dialog needs more than a paragraph.
  final Widget? content;

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AppPanel(
          elevated: true,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppText.screenTitle.copyWith(fontSize: 19),
                textAlign: TextAlign.center,
              ),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  body!,
                  style: AppText.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: AppSpacing.lg),
                content!,
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                ...actions,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Yes/no confirmation. Resolves to false when dismissed.
  static Future<bool> confirm({
    required String title,
    required String body,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AppDialog(
        title: title,
        body: body,
        actions: [
          PremiumButton(
            label: confirmLabel,
            variant: destructive ? ButtonVariant.danger : ButtonVariant.primary,
            size: ButtonSize.medium,
            onPressed: () => Get.back<bool>(result: true),
          ),
          const SizedBox(height: AppSpacing.sm),
          PremiumButton(
            label: cancelLabel,
            variant: ButtonVariant.ghost,
            size: ButtonSize.medium,
            onPressed: () => Get.back<bool>(result: false),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// A single-button notice, used for "not connected yet" explanations.
  static Future<void> notice({
    required String title,
    required String body,
    required String dismissLabel,
  }) {
    return Get.dialog<void>(
      AppDialog(
        title: title,
        body: body,
        actions: [
          PremiumButton(
            label: dismissLabel,
            variant: ButtonVariant.secondary,
            size: ButtonSize.medium,
            onPressed: () => Get.back<void>(),
          ),
        ],
      ),
    );
  }
}

/// A gold-hairline divider used inside panels and dialogs.
class PanelDivider extends StatelessWidget {
  const PanelDivider({super.key, this.height = AppSpacing.lg});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: const Center(
      child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
    ),
  );
}
