import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../app/bindings/backend_services.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../auth/application/session_controller.dart';
import '../../online/domain/online_status.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/remote_room.dart';
import '../domain/room_models.dart';

/// §J — six characters, pasteable, validated.
class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _code = TextEditingController();
  bool _joining = false;

  bool get _canJoinOnline =>
      OnlineStatus.isConfigured && Get.find<SessionController>().isSignedIn;

  String get _value => RoomCode.normalise(_code.text);

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || !mounted) return;
    final code = RoomCode.normalise(text);
    _code.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final settings = Get.find<SettingsController>();

    return ScreenScaffold(
      title: s.joinRoomTitle,
      child: Obx(() {
        final accent = settings.theme.accent;
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                s.joinRoomBody,
                style: AppText.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppTextField(
                label: s.lobbyRoomCode,
                controller: _code,
                maxLength: RoomCode.length,
                textCapitalization: TextCapitalization.characters,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  // Uppercases and drops look-alikes as the player types.
                  TextInputFormatter.withFunction((old, next) {
                    final code = RoomCode.normalise(next.text);
                    return TextEditingValue(
                      text: code,
                      selection: TextSelection.collapsed(offset: code.length),
                    );
                  }),
                ],
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    RoomCode.isValid(v ?? '') ? null : s.joinRoomInvalid,
                trailing: TextButton(
                  onPressed: _paste,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: accent,
                  ),
                  child: Text(s.joinRoomPaste, style: AppText.label),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _CodeDots(filled: _value.length, accent: accent),
              const SizedBox(height: AppSpacing.xxl),
              PremiumButton(
                label: s.joinRoomCta,
                accent: accent,
                // Disabled until the code is well formed — no request is even
                // attempted with an obviously wrong code.
                loading: _joining,
                onPressed: RoomCode.isValid(_value) ? _join : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _canJoinOnline ? s.lobbyStartPending : s.authBackendPending,
                style: AppText.caption.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _join() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_joining) return;
    if (!_canJoinOnline) {
      await Get.toNamed<void>(AppRoutes.roomLobby, arguments: _value);
      return;
    }
    setState(() => _joining = true);
    try {
      final room = await Get.find<BackendServices>().rooms.join(_value);
      if (!mounted) return;
      await Get.toNamed<void>(AppRoutes.roomLobby, arguments: room);
    } on RoomException catch (error) {
      final s = Strings.s;
      await AppDialog.notice(
        title: s.commonErrorTitle,
        body: switch (error.error) {
          RoomError.notFound || RoomError.invalidCode => s.roomNotFound,
          RoomError.full => s.roomFull,
          _ => s.roomJoinFailed,
        },
        dismissLabel: s.gotIt,
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }
}

/// Six slots that fill as the code is typed.
class _CodeDots extends StatelessWidget {
  const _CodeDots({required this.filled, required this.accent});

  final int filled;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < RoomCode.length; i++)
          Container(
            width: 26,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: i < filled ? accent : AppColors.hairline,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
      ],
    );
  }
}
