import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/router/app_router.dart';

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
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/premium_button.dart';
import '../../auth/application/session_controller.dart';
import '../../online/domain/online_status.dart';
import '../../profile/application/profile_controller.dart';

/// §39 — the settings half.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final TextEditingController _name = TextEditingController(
    text: widget.settings.settings.playerName,
  );

  @override
  void dispose() {
    // Nothing is written here on purpose. Persisting from dispose() mutates
    // the settings Rx while the framework is unmounting the tree, which marks
    // still-mounted ancestor Obx widgets dirty during a locked phase and
    // throws "setState() called during build". The name is committed as it is
    // typed instead (see onChanged below), so leaving the screen has nothing
    // left to save.
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
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.xxl,
      ),
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
                      // Committed per keystroke rather than on teardown.
                      // The field keeps its own controller, so the rebuild
                      // this triggers does not disturb the cursor, and the
                      // name now survives the app being killed mid-edit.
                      onChanged: c.setPlayerName,
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
                    value: AnimationSpeed.normal,
                    label: s.animationNormal,
                  ),
                  SegmentOption(
                    value: AnimationSpeed.fast,
                    label: s.animationFast,
                  ),
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
                    value: BotDifficulty.easy,
                    label: s.difficultyEasy,
                  ),
                  SegmentOption(
                    value: BotDifficulty.normal,
                    label: s.difficultyNormal,
                  ),
                  SegmentOption(
                    value: BotDifficulty.hard,
                    label: s.difficultyHard,
                  ),
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
                              const AppIconView(
                                AppIcon.lock,
                                size: 14,
                                color: AppColors.textSecondary,
                              )
                            else if (selected)
                              const AppIconView(
                                AppIcon.check,
                                size: 14,
                                color: AppColors.warmIvory,
                              )
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
                              color: selected ? accent : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PlayingCard(
                                width: 44,
                                faceUp: false,
                                backId: b.id,
                              ),
                              if (!unlocked)
                                const AppIconView(
                                  AppIcon.lock,
                                  size: 16,
                                  color: AppColors.warmIvory,
                                ),
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
        const SizedBox(height: AppSpacing.lg),
        _languagePanel(s, c, accent),
        const SizedBox(height: AppSpacing.lg),
        _accountPanel(s, accent),
      ],
    );
  }

  /// §9 — Italian and English, switched live.
  Widget _languagePanel(
    AppLocalizations s,
    SettingsController c,
    Color accent,
  ) {
    return AppPanel(
      child: Column(
        children: [
          SectionHeading(s.settingsLanguage.toUpperCase()),
          const SizedBox(height: AppSpacing.sm),
          SegmentedControl<String>(
            value: c.locale.languageCode,
            accent: accent,
            onChanged: (code) => c.setLocale(Locale(code)),
            options: [
              SegmentOption(value: 'it', label: s.settingsLanguageItalian),
              SegmentOption(value: 'en', label: s.settingsLanguageEnglish),
            ],
          ),
        ],
      ),
    );
  }

  /// §U — the account rows.
  ///
  /// Shows who is signed in (email, or "Guest" for an anonymous session),
  /// offers sign-in when a backend exists and nobody is, and sign-out when a
  /// real session exists. The legal links always show.
  Widget _accountPanel(AppLocalizations s, Color accent) {
    void pending(String title) => AppDialog.notice(
      title: title,
      body: s.settingsLinkPending,
      dismissLabel: s.gotIt,
    );

    final session = Get.find<SessionController>();
    final profile = Get.find<ProfileController>();

    return AppPanel(
      child: Column(
        children: [
          SectionHeading(s.settingsAccount),
          if (OnlineStatus.isConfigured)
            Obx(() {
              final current = session.session.value;
              final nickname = profile.profile.value?.nickname;
              final String line;
              if (current == null) {
                line = s.accountSignedOut;
              } else if (current.isGuest) {
                line = s.accountSignedInAs(nickname ?? s.accountGuestLabel);
              } else {
                line = s.accountSignedInAs(current.email ?? nickname ?? '');
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(line, style: AppText.bodySmall),
                    if (current?.isGuest ?? false) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        s.accountGuestUpgradeHint,
                        style: AppText.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          SettingRow(
            title: s.profile,
            icon: AppIcon.players,
            trailing: const AppIconView(
              AppIcon.chevronDown,
              size: 14,
              color: AppColors.textMuted,
            ),
            onTap: () => Get.toNamed<void>(AppRoutes.profile),
          ),
          SettingRow(
            title: s.settingsPrivacy,
            icon: AppIcon.rules,
            trailing: const AppIconView(
              AppIcon.chevronDown,
              size: 14,
              color: AppColors.textMuted,
            ),
            onTap: () => pending(s.settingsPrivacy),
          ),
          SettingRow(
            title: s.settingsTerms,
            icon: AppIcon.rules,
            trailing: const AppIconView(
              AppIcon.chevronDown,
              size: 14,
              color: AppColors.textMuted,
            ),
            onTap: () => pending(s.settingsTerms),
          ),
          if (OnlineStatus.isConfigured) ...[
            const SizedBox(height: AppSpacing.md),
            Obx(() {
              final current = session.session.value;
              if (current == null) {
                return PremiumButton(
                  label: s.authSignIn,
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.small,
                  onPressed: () => Get.toNamed<void>(AppRoutes.authLanding),
                );
              }
              if (current.isGuest) {
                // A guest can leave, but must be told what that costs.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PremiumButton(
                      label: s.authRegister,
                      variant: ButtonVariant.secondary,
                      size: ButtonSize.small,
                      onPressed: () => Get.toNamed<void>(AppRoutes.authLanding),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PremiumButton(
                      label: s.settingsLogoutGuest,
                      variant: ButtonVariant.ghost,
                      size: ButtonSize.small,
                      onPressed: () => _signOut(session, guest: true),
                    ),
                  ],
                );
              }
              return PremiumButton(
                label: s.settingsLogout,
                variant: ButtonVariant.danger,
                size: ButtonSize.small,
                onPressed: () => _signOut(session),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _signOut(SessionController session, {bool guest = false}) async {
    final s = Strings.s;
    final ok = await AppDialog.confirm(
      title: s.settingsLogout,
      body: guest ? s.settingsGuestLogoutBody : s.settingsLogoutBody,
      confirmLabel: s.settingsLogout,
      cancelLabel: s.cancel,
      destructive: true,
    );
    if (!ok) return;
    await session.signOut();
    await Get.offAllNamed<void>(AppRoutes.authLanding);
  }
}
