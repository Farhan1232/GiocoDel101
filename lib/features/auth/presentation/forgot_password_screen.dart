import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_button.dart';
import '../application/auth_controller.dart';
import '../domain/auth_validators.dart';
import 'auth_form_scaffold.dart';

/// §F — one field, full validation, honest outcome.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  late final AuthController _auth = Get.put(AuthController(), tag: 'forgot');

  @override
  void dispose() {
    _email.dispose();
    Get.delete<AuthController>(tag: 'forgot');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return AuthFormScaffold(
      title: s.forgotTitle,
      intro: s.forgotBody,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: s.fieldEmail,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return s.valRequired;
                return AuthValidators.isEmailValid(v!) ? null : s.valEmailInvalid;
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            Obx(
              () => PremiumButton(
                label: s.forgotCta,
                loading: _auth.status.value == AuthFormStatus.submitting,
                onPressed: _submit,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () => Get.back<void>(),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 44),
                foregroundColor: AppColors.mediterraneanTeal,
              ),
              child: Text(s.forgotBackToLogin, style: AppText.label),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() => AuthFormScaffold.submit(formKey: _formKey, auth: _auth);
}
