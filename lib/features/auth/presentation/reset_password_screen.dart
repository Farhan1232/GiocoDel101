import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_button.dart';
import '../application/auth_controller.dart';
import '../application/session_controller.dart';
import '../domain/auth_validators.dart';
import 'auth_form_scaffold.dart';

/// The other half of "forgot password".
///
/// Reached only by opening the link in the reset email: the app is already
/// holding the recovery session Supabase issued for it, so there is nothing
/// left to prove and no old password to type — just the new one, twice.
///
/// The screen is never a dead end. Whatever the backend answers is shown by
/// name, and a spent link says so instead of failing quietly.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final AuthController _auth = Get.put(
    AuthController(Get.find<SessionController>()),
    tag: 'reset',
  );

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    Get.delete<AuthController>(tag: 'reset');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return AuthFormScaffold(
      title: s.resetPasswordTitle,
      intro: s.resetPasswordBody,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: s.fieldNewPassword,
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
                label: s.resetPasswordCta,
                loading: _auth.status.value == AuthFormStatus.submitting,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() => AuthFormScaffold.submit(
    formKey: _formKey,
    auth: _auth,
    action: () => _auth.session.updatePassword(_password.text),
    onSuccess: (_) async {
      final s = Strings.s;
      await AppDialog.notice(
        title: s.resetPasswordDoneTitle,
        body: s.resetPasswordDoneBody,
        dismissLabel: s.gotIt,
      );
      _auth.reset();
      // The recovery session is a real one: they are signed in with the new
      // password already, so there is nothing to log into.
      await Get.offAllNamed<void>(AppRoutes.home);
    },
  );
}
