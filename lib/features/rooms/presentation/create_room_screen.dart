import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../app/bindings/backend_services.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../auth/application/session_controller.dart';
import '../../online/domain/online_status.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/remote_room.dart';
import '../application/create_room_controller.dart';
import '../domain/room_models.dart';

/// §I — configures a room. No networking: the config is built and handed on.
class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  late final CreateRoomController _room = Get.put(CreateRoomController());
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    Get.delete<CreateRoomController>();
    super.dispose();
  }

  bool _creating = false;

  bool get _canCreateOnline =>
      OnlineStatus.isConfigured && Get.find<SessionController>().isSignedIn;

  /// With a signed-in session the room is created on the server and the
  /// lobby receives the real row (code included). Otherwise the lobby is
  /// shown with the config alone and says the service is not connected.
  Future<void> _create(RoomConfig config) async {
    if (_creating) return;
    if (!_canCreateOnline) {
      await Get.toNamed<void>(AppRoutes.roomLobby, arguments: config);
      return;
    }
    setState(() => _creating = true);
    try {
      final room = await Get.find<BackendServices>().rooms.create(config);
      if (!mounted) return;
      await Get.toNamed<void>(AppRoutes.roomLobby, arguments: room);
    } on RoomException catch (error) {
      final s = Strings.s;
      await AppDialog.notice(
        title: s.commonErrorTitle,
        body: error.error == RoomError.alreadyInMatch
            ? s.roomAlreadyInMatch
            : s.roomCreateFailed,
        dismissLabel: s.gotIt,
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final settings = Get.find<SettingsController>();

    return ScreenScaffold(
      title: s.createRoomTitle,
      child: Obx(() {
        final accent = settings.theme.accent;
        final config = _room.config.value;
        final rules = config.rules;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            SectionHeading(s.playersCount.toUpperCase()),
            const SizedBox(height: AppSpacing.sm),
            SegmentedControl<int>(
              value: config.playerCount,
              accent: accent,
              onChanged: _room.setPlayerCount,
              options: const [
                SegmentOption(value: 2, label: '2'),
                SegmentOption(value: 3, label: '3'),
                SegmentOption(value: 4, label: '4'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: '${s.createRoomName} · ${s.commonOptional}',
              controller: _name,
              hint: s.createRoomNameHint,
              maxLength: 24,
              textCapitalization: TextCapitalization.sentences,
              onChanged: _room.setName,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPanel(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: SettingRow(
                title: s.createRoomPrivate,
                hint: s.createRoomPrivateHint,
                trailing: AppSwitch(
                  value: config.isPrivate,
                  accent: accent,
                  onChanged: _room.setPrivate,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeading(s.createRoomTimer.toUpperCase()),
            const SizedBox(height: AppSpacing.sm),
            SegmentedControl<TurnTimer>(
              value: config.turnTimer,
              accent: accent,
              compact: true,
              onChanged: _room.setTurnTimer,
              options: [
                SegmentOption(
                  value: TurnTimer.off,
                  label: s.createRoomTimerOff,
                ),
                for (final t in const [
                  TurnTimer.fifteen,
                  TurnTimer.thirty,
                  TurnTimer.sixty,
                ])
                  SegmentOption(value: t, label: '${t.seconds}s'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeading(s.createRoomHouseRules.toUpperCase()),
            const SizedBox(height: AppSpacing.sm),
            AppPanel(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                children: [
                  SettingRow(
                    title: s.ruleStackTwos,
                    hint: s.ruleStackTwosHint,
                    trailing: AppSwitch(
                      value: rules.stackDrawTwos,
                      accent: accent,
                      onChanged: _room.toggleStackTwos,
                    ),
                  ),
                  SettingRow(
                    title: s.ruleWildNine,
                    hint: s.ruleWildNineHint,
                    trailing: AppSwitch(
                      value: rules.wildNineCanAlwaysPlay,
                      accent: accent,
                      onChanged: _room.toggleWildNine,
                    ),
                  ),
                  SettingRow(
                    title: s.ruleExactReset,
                    hint: s.ruleExactResetHint,
                    trailing: AppSwitch(
                      value: rules.exact101ResetsToZero,
                      accent: accent,
                      onChanged: _room.toggleExactReset,
                    ),
                  ),
                  SettingRow(
                    title: s.ruleEliminate,
                    hint: s.ruleEliminateHint,
                    trailing: AppSwitch(
                      value: rules.eliminateAbove101,
                      accent: accent,
                      onChanged: _room.toggleEliminate,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PremiumButton(
              label: s.createRoomCta,
              accent: accent,
              loading: _creating,
              onPressed: () => _create(config),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _canCreateOnline ? s.lobbyStartPending : s.authBackendPending,
              style: AppText.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      }),
    );
  }
}
