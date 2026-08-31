import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/legal/legal_config.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/legal_content.dart';

/// Shared renderer for the two legal documents: a scrollable column of
/// titled sections in the app's own visual language, in the player's
/// language, with the "last updated" date at the top. It renders correctly
/// with every [LegalConfig] value unconfigured — no crash, no invented
/// company details.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument Function(String localeCode) document;

  @override
  Widget build(BuildContext context) {
    final locale = Get.find<SettingsController>().settings.localeCode;
    final doc = document(locale);
    final s = Strings.s;
    return ScreenScaffold(
      title: doc.title,
      scrollable: false,
      child: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.xl,
        ),
        children: [
          Text(
            s.legalLastUpdated(LegalConfig.lastUpdated),
            style: AppText.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final section in doc.sections) ...[
            AppPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: AppText.sectionTitle),
                  const SizedBox(height: AppSpacing.sm),
                  Text(section.body, style: AppText.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
