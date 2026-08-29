import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_button.dart';
import '../application/auth_controller.dart';
import '../domain/auth_validators.dart';
import 'auth_form_scaffold.dart';

/// §E — nickname, email and a confirmed password.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final AuthController _auth = Get.put(AuthController(), tag: 'signup');

  @override
  void dispose() {
    _nickname.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    Get.delete<AuthController>(tag: 'signup');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return AuthFormScaffold(
      title: s.signupTitle,
      intro: null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: s.fieldNickname,
              controller: _nickname,
              textInputAction: TextInputAction.next,
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
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: s.fieldEmail,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return s.valRequired;
                return AuthValidators.isEmailValid(v!)
                    ? null
                    : s.valEmailInvalid;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: s.fieldPassword,
              controller: _password,
              obscure: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              showPasswordLabel: s.showPassword,
              hidePasswordLabel: s.hidePassword,
              onChanged: (_) => _formKey.currentState?.validate(),
              validator: (v) {
                if ((v ?? '').isEmpty) return s.valRequired;
                return AuthValidators.isPasswordValid(v!)
                    ? null
                    : s.valPasswordShort;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: s.fieldConfirmPassword,
              controller: _confirm,
              obscure: true,
              textInputAction: TextInputAction.done,
              showPasswordLabel: s.showPassword,
              hidePasswordLabel: s.hidePassword,
              validator: (v) {
                if ((v ?? '').isEmpty) return s.valRequired;
                return v == _password.text ? null : s.valPasswordMismatch;
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            Obx(
              () => PremiumButton(
                label: s.signupCta,
                loading: _auth.status.value == AuthFormStatus.submitting,
                onPressed: _submit,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    s.signupHaveAccount,
                    style: AppText.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.offNamed<void>(AppRoutes.login),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    foregroundColor: AppColors.antiqueGold,
                  ),
                  child: Text(s.authSignIn, style: AppText.label),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() => AuthFormScaffold.submit(formKey: _formKey, auth: _auth);
}
