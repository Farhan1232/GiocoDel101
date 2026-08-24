import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/match_launcher.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/setup_controller.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/motion.dart';
import '../../data/app_strings.dart';
import '../../data/bot_roster.dart';
import '../../game/match_factory.dart';
import '../../models/match_state.dart';
import '../../models/player_type.dart';
import '../../storage/local_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/table_themes.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/app_panel.dart';
import '../../widgets/common/app_switch.dart';
import '../../widgets/common/avatar_medallion.dart';
import '../../widgets/common/icon_pill.dart';
import '../../widgets/common/premium_button.dart';
import '../../widgets/common/segmented_control.dart';
import '../../widgets/icons/app_icons.dart';

/// §26 Screen 3 — one clean setup screen, advanced rules folded away.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final SettingsController _settings = Get.find<SettingsController>();
  late final SetupController _setup = Get.put(
    SetupController(
      Get.find<LocalStorage>(),
      defaultDifficulty: _settings.settings.defaultDifficulty,
    ),
  );
  late final TextEditingController _name =
      TextEditingController(text: _settings.settings.playerName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await _settings.setPlayerName(_name.text);
    await _setup.persist();
    final rules = _setup.buildRules();
    final setup = _setup.mode.value == GameMode.vsComputer
        ? MatchFactory.vsComputer(
            playerName: _settings.settings.playerName,
            avatarId: _settings.settings.avatarId,
            playerCount: _setup.playerCount.value,
            difficulty: _setup.difficulty.value,
            rules: rules,
          )
        : MatchFactory.passAndPlay(
            names: [
              _settings.settings.playerName,
              ..._setup.passAndPlayNames
                  .take(_setup.playerCount.value - 1),
            ],
            avatarIds: [
              _settings.settings.avatarId,
              ...BotRoster.all.map((b) => b.avatarId),
            ],
            rules: rules,
          );
    MatchLauncher.launch(setup, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return Obx(() {
      final theme = _settings.theme;
      final accent = theme.accent;
      return Scaffold(
        backgroundColor: theme.backdropTop,
        body: AppBackground(
          theme: theme,
          motifStrength: 0.7,
          child: SafeArea(
            child: Column(
              children: [
                _header(s.newGame),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0,
                        AppSpacing.gutter, AppSpacing.lg),
                    children: [
                      _tablePreview(accent),
                      const SizedBox(height: AppSpacing.lg),
                      _block(s.mode, SegmentedControl<GameMode>(
                        accent: accent,
                        value: _setup.mode.value,
                        onChanged: (v) => _setup.mode.value = v,
                        options: [
                          SegmentOption(
                              value: GameMode.vsComputer,
                              label: s.modeVsComputer,
                              icon: AppIcon.difficulty),
                          SegmentOption(
                              value: GameMode.passAndPlay,
                              label: s.modePassAndPlay,
                              icon: AppIcon.players),
                        ],
                      )),
                      _block(s.playersCount, SegmentedControl<int>(
                        accent: accent,
                        value: _setup.playerCount.value,
                        onChanged: (v) => _setup.playerCount.value = v,
                        options: const [
                          SegmentOption(value: 2, label: '2'),
                          SegmentOption(value: 3, label: '3'),
                          SegmentOption(value: 4, label: '4'),
                        ],
                      )),
                      if (_setup.mode.value == GameMode.vsComputer)
                        _block(s.difficulty, SegmentedControl<BotDifficulty>(
                          accent: accent,
                          value: _setup.difficulty.value,
                          onChanged: (v) => _setup.difficulty.value = v,
                          options: [
                            SegmentOption(
                                value: BotDifficulty.easy, label: s.difficultyEasy),
                            SegmentOption(
                                value: BotDifficulty.normal,
                                label: s.difficultyNormal),
                            SegmentOption(
                                value: BotDifficulty.hard, label: s.difficultyHard),
                          ],
                        )),
                      _block(s.playerName, _nameField(accent)),
                      if (_setup.mode.value == GameMode.passAndPlay)
                        _passAndPlayNames(accent),
                      _block(s.tableTheme, _themePicker()),
                      const SizedBox(height: AppSpacing.sm),
                      _advanced(accent),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0,
                      AppSpacing.gutter, AppSpacing.lg),
                  child: PremiumButton(
                    label: s.startMatch,
                    icon: AppIcon.play,
                    accent: accent,
                    onPressed: _start,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _header(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.md),
        child: Row(
          children: [
            IconPill(icon: AppIcon.back, onTap: Get.back<void>),
            Expanded(
              child: Text(title,
                  textAlign: TextAlign.center, style: AppText.screenTitle),
            ),
            const SizedBox(width: 44),
          ],
        ),
      );

  Widget _block(String label, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.xs, bottom: AppSpacing.sm),
              child: Text(label.toUpperCase(), style: AppText.label),
            ),
            child,
          ],
        ),
      );

  Widget _nameField(Color accent) => TextField(
        controller: _name,
        maxLength: 16,
        textCapitalization: TextCapitalization.words,
        style: AppText.body,
        cursorColor: accent,
        decoration: InputDecoration(
          counterText: '',
          hintText: Strings.s.playerName,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppIconView(AppIcon.edit,
                size: 18, color: AppColors.textSecondary),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 46, minHeight: 46),
        ),
      );

  Widget _passAndPlayNames(Color accent) {
    return _block(
      'Altri giocatori',
      Column(
        children: [
          for (var i = 0; i < _setup.playerCount.value - 1; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TextField(
                controller: TextEditingController(
                    text: _setup.passAndPlayNames[i])
                  ..selection = TextSelection.collapsed(
                      offset: _setup.passAndPlayNames[i].length),
                maxLength: 16,
                style: AppText.body,
                cursorColor: accent,
                onChanged: (v) => _setup.passAndPlayNames[i] =
                    v.trim().isEmpty ? 'Giocatore ${i + 2}' : v.trim(),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Giocatore ${i + 2}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _themePicker() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: TableThemes.all.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final t = TableThemes.all[i];
          final unlocked = _settings.isThemeUnlocked(t.id);
          final selected = _settings.settings.themeId == t.id;
          return GestureDetector(
            onTap: unlocked ? () => _settings.setTheme(t.id) : null,
            child: AnimatedContainer(
              duration: Motion.scale(AppDurations.quick),
              width: 132,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.md),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [t.backdropTop, t.feltInner, t.backdropBottom],
                ),
                border: Border.all(
                  color: selected
                      ? t.feltRim
                      : AppColors.hairline.withValues(alpha: 0.4),
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: t.accent.withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: -4,
                        ),
                      ]
                    : null,
              ),
              // A scrim under the caption: the lighter tables would otherwise
              // leave the label unreadable against their own felt.
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: -AppSpacing.sm - 2,
                    right: -AppSpacing.sm - 2,
                    bottom: -AppSpacing.sm - 2,
                    height: 62,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(AppRadii.md)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.inkDeep.withValues(alpha: 0.0),
                            AppColors.inkDeep.withValues(alpha: 0.82),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!unlocked)
                    const Align(
                      alignment: Alignment.topRight,
                      child: AppIconView(AppIcon.lock,
                          size: 16, color: AppColors.warmIvory),
                    ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            )),
                        const SizedBox(height: 2),
                        Text(
                          unlocked ? t.tagline : Strings.s.locked,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// §26 — collapsed by default so the main screen stays uncluttered.
  Widget _advanced(Color accent) {
    return AppPanel(
      accent: accent,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                _setup.advancedOpen.value = !_setup.advancedOpen.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  AppIconView(AppIcon.rules, size: 18, color: accent),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(Strings.s.advancedRules,
                        style:
                            AppText.body.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (!_setup.isDefaultRules)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: NotificationDot(color: accent),
                    ),
                  AnimatedRotation(
                    duration: Motion.scale(AppDurations.quick),
                    turns: _setup.advancedOpen.value ? 0.5 : 0,
                    child: const AppIconView(AppIcon.chevronDown,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: Motion.scale(AppDurations.quick),
            crossFadeState: _setup.advancedOpen.value
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                const Divider(color: AppColors.hairline, height: 1),
                SettingRow(
                  title: Strings.s.startingHand,
                  trailing: _stepper(
                    value: _setup.startingHand.value,
                    min: 3,
                    max: 10,
                    accent: accent,
                    onChanged: (v) => _setup.startingHand.value = v,
                  ),
                ),
                _ruleSwitch(Strings.s.ruleStackTwos, Strings.s.ruleStackTwosHint,
                    _setup.stackTwos, accent),
                _ruleSwitch(Strings.s.ruleWildNine, Strings.s.ruleWildNineHint,
                    _setup.wildNine, accent),
                _ruleSwitch(Strings.s.ruleVoluntaryDraw,
                    Strings.s.ruleVoluntaryDrawHint, _setup.voluntaryDraw, accent),
                _ruleSwitch(Strings.s.ruleExactReset,
                    Strings.s.ruleExactResetHint, _setup.exactReset, accent),
                _ruleSwitch(Strings.s.ruleEliminate,
                    Strings.s.ruleEliminateHint, _setup.eliminate, accent),
                if (!_setup.isDefaultRules)
                  Padding(
                    padding: const EdgeInsets.only(
                        top: AppSpacing.sm, bottom: AppSpacing.md),
                    child: PremiumButton(
                      label: 'Ripristina regole',
                      variant: ButtonVariant.ghost,
                      size: ButtonSize.small,
                      expand: false,
                      onPressed: _setup.resetRules,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleSwitch(String title, String hint, RxBool value, Color accent) =>
      SettingRow(
        title: title,
        hint: hint,
        trailing: AppSwitch(
          value: value.value,
          accent: accent,
          onChanged: (v) => value.value = v,
        ),
      );

  Widget _stepper({
    required int value,
    required int min,
    required int max,
    required Color accent,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepButton('−', value > min ? () => onChanged(value - 1) : null, accent),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text('$value', style: AppText.scoreSmall),
        ),
        _stepButton('+', value < max ? () => onChanged(value + 1) : null, accent),
      ],
    );
  }

  Widget _stepButton(String glyph, VoidCallback? onTap, Color accent) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceSunken,
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: Text(glyph,
              style: AppText.body
                  .copyWith(fontSize: 18, color: accent, height: 1)),
        ),
      ),
    );
  }

  /// §26 — card-shaped seats arranged around a small table.
  Widget _tablePreview(Color accent) {
    final count = _setup.playerCount.value;
    final vsComputer = _setup.mode.value == GameMode.vsComputer;
    final names = <String>[
      _name.text.isEmpty ? _settings.settings.playerName : _name.text,
      if (vsComputer)
        ...BotRoster.all.take(count - 1).map((b) => b.name)
      else
        ..._setup.passAndPlayNames.take(count - 1),
    ];
    final avatars = <String>[
      _settings.settings.avatarId,
      ...BotRoster.all.take(count - 1).map((b) => b.avatarId),
    ];

    return SizedBox(
      height: 176,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The felt.
          Container(
            width: 168,
            height: 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(54),
              gradient: RadialGradient(
                colors: [
                  _settings.theme.feltInner,
                  _settings.theme.feltOuter,
                ],
              ),
              border: Border.all(
                  color: _settings.theme.feltRim.withValues(alpha: 0.55),
                  width: 2),
            ),
            alignment: Alignment.center,
            child: Text('101',
                style: AppText.screenTitle.copyWith(
                  fontSize: 22,
                  color: _settings.theme.feltRim.withValues(alpha: 0.75),
                )),
          ),
          for (var i = 0; i < count; i++)
            _seat(i, count, names[i], avatars[i], accent),
        ],
      ),
    );
  }

  Widget _seat(int index, int count, String name, String avatarId, Color accent) {
    // Index 0 always sits at the bottom; the rest spread around the felt.
    return Transform.translate(
      key: ValueKey('seat_${count}_$index'),
      offset: _seatOffsets(count)[index],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarMedallion(
            avatarId: avatarId,
            size: 40,
            active: index == 0,
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: 68,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                color: index == 0 ? accent : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Offset> _seatOffsets(int count) {
    switch (count) {
      case 2:
        return const [Offset(0, 62), Offset(0, -62)];
      case 3:
        return const [Offset(0, 62), Offset(-104, -34), Offset(104, -34)];
      default:
        return const [
          Offset(0, 62),
          Offset(-116, 0),
          Offset(0, -62),
          Offset(116, 0),
        ];
    }
  }
}
