import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/avatar_medallion.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../auth/domain/auth_validators.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/avatars.dart';

/// §Q — nickname and avatar, saved locally.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SettingsController _settings = Get.find<SettingsController>();
  late final TextEditingController _nickname =
      TextEditingController(text: _settings.settings.playerName);
  late String _avatarId = _settings.settings.avatarId;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _settings.setPlayerName(_nickname.text);
    await _settings.setAvatar(_avatarId);
    Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return ScreenScaffold(
      title: s.editProfileTitle,
      child: Obx(() {
        final accent = _settings.theme.accent;
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: AvatarMedallion(
                  avatarId: _avatarId,
                  size: 96,
                  active: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: s.fieldNickname,
                controller: _nickname,
                maxLength: AuthValidators.maxNicknameLength,
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return s.valRequired;
                  if (v!.trim().length < AuthValidators.minNicknameLength) {
                    return s.valNicknameShort;
                  }
                  return AuthValidators.isNicknameValid(v)
                      ? null
                      : s.valNicknameLong;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeading(s.editProfileAvatar.toUpperCase()),
              const SizedBox(height: AppSpacing.md),
              AppPanel(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final avatar in Avatars.all)
                      Semantics(
                        button: true,
                        selected: avatar.id == _avatarId,
                        label: avatar.id,
                        child: GestureDetector(
                          onTap: () => setState(() => _avatarId = avatar.id),
                          // A 56dp medallion inside a 64dp target (§8).
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: Center(
                              child: AvatarMedallion(
                                avatarId: avatar.id,
                                size: 56,
                                active: avatar.id == _avatarId,
                                dimmed: avatar.id != _avatarId,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PremiumButton(
                label: s.commonSave,
                accent: accent,
                onPressed: _save,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      }),
    );
  }
}
