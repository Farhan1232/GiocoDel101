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
import '../application/session_controller.dart';
import '../domain/auth_validators.dart';
import '../../purchases/presentation/cosmetic_gate.dart';
import 'auth_form_scaffold.dart';

/// §D — email and password, validated locally, authenticated by Supabase.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AuthController _auth = Get.put(
    AuthController(Get.find<SessionController>()),
    tag: 'login',
  );

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    Get.delete<AuthController>(tag: 'login');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return AuthFormScaffold(
      title: s.loginTitle,
      intro: null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              showPasswordLabel: s.showPassword,
              hidePasswordLabel: s.hidePassword,
              validator: (v) {
                if ((v ?? '').isEmpty) return s.valRequired;
                return AuthValidators.isPasswordValid(v!)
                    ? null
                    : s.valPasswordShort;
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Get.toNamed<void>(AppRoutes.forgotPassword),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  foregroundColor: AppColors.mediterraneanTeal,
                ),
                child: Text(s.loginForgot, style: AppText.caption),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Obx(
              () => PremiumButton(
                label: s.loginCta,
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
                    s.loginNoAccount,
                    style: AppText.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.offNamed<void>(AppRoutes.signup),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    foregroundColor: AppColors.antiqueGold,
                  ),
                  child: Text(s.authRegister, style: AppText.label),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() => AuthFormScaffold.submit(
    formKey: _formKey,
    auth: _auth,
    action: () =>
        _auth.session.signIn(email: _email.text, password: _password.text),
    onSuccess: (_) async {
      await Get.offAllNamed<void>(AppRoutes.home);
      // If they came here from a locked cosmetic, finish that purchase.
      await CosmeticGate.resumeAfterSignIn();
    },
  );
}
