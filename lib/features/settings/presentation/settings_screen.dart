import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../application/settings_controller.dart';
import '../../profile/application/stats_controller.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/icon_pill.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../core/widgets/app_icons.dart';
import 'settings_tab.dart';
import '../../profile/presentation/statistics_tab.dart';

/// §39 Screen 8 — settings and statistics behind one segmented control.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController settings = Get.find<SettingsController>();
  final StatsController stats = Get.find<StatsController>();
  late int _tab;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _tab = (args is Map && args['tab'] is int) ? args['tab'] as int : 0;
    // Opening the statistics tab acknowledges any new badges.
    if (_tab == 1) stats.drainPendingAchievements();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return Obx(() {
      final theme = settings.theme;
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
                          _tab == 0 ? s.settings : s.statistics,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.screenTitle.copyWith(fontSize: 20),
                        ),
                      ),
                      // Balances the back button so the title stays centred.
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  child: SegmentedControl<int>(
                    accent: theme.accent,
                    value: _tab,
                    onChanged: (v) {
                      setState(() => _tab = v);
                      if (v == 1) stats.drainPendingAchievements();
                    },
                    options: [
                      SegmentOption(
                        value: 0,
                        label: s.sectionSettings,
                        icon: AppIcon.settings,
                      ),
                      SegmentOption(
                        value: 1,
                        label: s.sectionStatistics,
                        icon: AppIcon.stats,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _tab == 0
                        ? SettingsTab(
                            key: const ValueKey('settings'),
                            settings: settings,
                          )
                        : StatisticsTab(
                            key: const ValueKey('stats'),
                            stats: stats,
                            accent: theme.accent,
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
}
