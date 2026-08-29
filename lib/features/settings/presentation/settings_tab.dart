import 'package:flutter/material.dart';

import '../application/settings_controller.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../app/localization/app_strings.dart';
import '../../profile/domain/avatars.dart';
import '../../game/domain/player_type.dart';
import '../domain/settings_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/card_backs.dart';
import '../../../app/theme/table_themes.dart';
import '../../../core/widgets/cards/playing_card.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/avatar_medallion.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../core/widgets/app_icons.dart';

/// §39 — the settings half.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final TextEditingController _name =
      TextEditingController(text: widget.settings.settings.playerName);

  @override
  void dispose() {
    widget.settings.setPlayerName(_name.text);
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final c = widget.settings;
    final v = c.settings;
    final accent = c.theme.accent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xxl),
      children: [
        AppPanel(
          accent: accent,
          child: Column(
            children: [
              const SectionHeading('PROFILO'),
              Row(
                children: [
                  AvatarMedallion(avatarId: v.avatarId, size: 52, active: true),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _name,
                      maxLength: 16,
                      style: AppText.body,
                      cursorColor: accent,
                      onSubmitted: c.setPlayerName,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: s.playerName,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: Avatars.selectable.length,
                  separatorBuilder: (context, i) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final a = Avatars.selectable[i];
                    return GestureDetector(
                      onTap: () => c.setAvatar(a.id),
                      child: AvatarMedallion(
                        avatarId: a.id,
                        size: 46,
                        active: a.id == v.avatarId,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppPanel(
          accent: accent,
          child: Column(
            children: [
              const SectionHeading('AUDIO'),
              SettingRow(
                title: s.soundEffects,
                icon: v.soundEnabled ? AppIcon.sound : AppIcon.soundOff,
                trailing: AppSwitch(
                  value: v.soundEnabled,
                  accent: accent,
                  onChanged: c.setSound,
                ),
              ),
              SettingRow(
                title: s.music,
                icon: v.musicEnabled ? AppIcon.music : AppIcon.musicOff,
                trailing: AppSwitch(
                  value: v.musicEnabled,
                  accent: accent,
                  onChanged: c.setMusic,
                ),
              ),
              SettingRow(
                title: s.haptics,
                icon: AppIcon.haptic,
                trailing: AppSwitch(
                  value: v.hapticsEnabled,
                  accent: accent,
                  onChanged: c.setHaptics,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppPanel(
          accent: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading('GIOCO'),
              Text(s.animationSpeed.toUpperCase(), style: AppText.label),
              const SizedBox(height: AppSpacing.sm),
              SegmentedControl<AnimationSpeed>(
                accent: accent,
                height: 40,
                compact: true,
                value: v.animationSpeed,
                onChanged: c.setAnimationSpeed,
                options: [
                  SegmentOption(
                      value: AnimationSpeed.normal, label: s.animationNormal),
                  SegmentOption(
                      value: AnimationSpeed.fast, label: s.animationFast),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(s.defaultDifficulty.toUpperCase(), style: AppText.label),
              const SizedBox(height: AppSpacing.sm),
              SegmentedControl<BotDifficulty>(
                accent: accent,
                height: 40,
                compact: true,
                value: v.defaultDifficulty,
                onChanged: c.setDefaultDifficulty,
                options: [
                  SegmentOption(
                      value: BotDifficulty.easy, label: s.difficultyEasy),
                  SegmentOption(
                      value: BotDifficulty.normal, label: s.difficultyNormal),
                  SegmentOption(
                      value: BotDifficulty.hard, label: s.difficultyHard),
                ],
              ),
              SettingRow(
                title: s.reduceMotion,
                icon: AppIcon.motion,
                trailing: AppSwitch(
                  value: v.reduceMotion,
                  accent: accent,
                  onChanged: c.setReduceMotion,
                ),
              ),
              SettingRow(
                title: s.highContrast,
                icon: AppIcon.contrast,
                trailing: AppSwitch(
                  value: v.highContrast,
                  accent: accent,
                  onChanged: c.setHighContrast,
                ),
              ),
              SettingRow(
                title: s.largeCards,
                icon: AppIcon.cards,
                trailing: AppSwitch(
                  value: v.largeCardMode,
                  accent: accent,
                  onChanged: c.setLargeCards,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppPanel(
          accent: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(s.tableTheme.toUpperCase()),
              SizedBox(
                height: 74,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: TableThemes.all.length,
                  separatorBuilder: (context, i) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final t = TableThemes.all[i];
                    final unlocked = c.isThemeUnlocked(t.id);
                    final selected = v.themeId == t.id;
                    return GestureDetector(
                      onTap: unlocked ? () => c.setTheme(t.id) : null,
                      child: Container(
                        width: 112,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [t.backdropTop, t.feltInner],
                          ),
                          border: Border.all(
                            color: selected
                                ? t.feltRim
                                : AppColors.hairline.withValues(alpha: 0.4),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!unlocked)
                              const AppIconView(AppIcon.lock,
                                  size: 14, color: AppColors.textSecondary)
                            else if (selected)
                              const AppIconView(AppIcon.check,
                                  size: 14, color: AppColors.warmIvory)
                            else
                              const SizedBox(height: 14),
                            Text(
                              t.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(
                                fontSize: 10.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionHeading(s.cardBack.toUpperCase()),
              SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: CardBacks.all.length,
                  separatorBuilder: (context, i) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final b = CardBacks.all[i];
                    final unlocked = c.isCardBackUnlocked(b.id);
                    final selected = v.cardBackId == b.id;
                    return GestureDetector(
                      onTap: unlocked ? () => c.setCardBack(b.id) : null,
                      child: Opacity(
                        opacity: unlocked ? 1 : 0.4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(
                              color: selected
                                  ? accent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PlayingCard(
                                  width: 44, faceUp: false, backId: b.id),
                              if (!unlocked)
                                const AppIconView(AppIcon.lock,
                                    size: 16, color: AppColors.warmIvory),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
