import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../application/purchase_controller.dart';
import '../domain/entitlement.dart';

/// §IAP — the purchase screen.
///
/// Everything the player reads about the product — title, description and
/// above all the price — comes from the store's own metadata, never from a
/// hard-coded string. The screen renders exactly one [PurchasePhase] at a
/// time and none of them can spin forever: every async path ends in ready,
/// a message, or an error with a retry.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PurchaseController c = Get.find<PurchaseController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) c.load();
    });
  }

  bool get _signedIn => Get.find<SessionController>().isSignedIn;

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return ScreenScaffold(
      title: s.premiumTitle,
      child: Obx(() {
        if (c.isPremium) return _activePanel(s);
        if (!_signedIn) {
          return _message(s.premiumSignInRequired, icon: AppIcon.players);
        }
        return switch (c.phase.value) {
          PurchasePhase.idle || PurchasePhase.loading => const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxl),
            child: LoadingView(),
          ),
          PurchasePhase.storeUnavailable => _retryable(
            s.premiumStoreUnavailable,
          ),
          PurchasePhase.productMissing => _retryable(s.premiumProductMissing),
          PurchasePhase.purchasing => _busy(s.premiumPending),
          PurchasePhase.verifying => _busy(s.premiumVerifying),
          PurchasePhase.success => _message(
            s.premiumSuccess,
            icon: AppIcon.check,
          ),
          PurchasePhase.restored => _message(
            s.premiumRestored,
            icon: AppIcon.check,
          ),
          PurchasePhase.ready || PurchasePhase.error => _offer(s),
        };
      }),
    );
  }

  Widget _offer(AppLocalizations s) {
    final product = c.product.value;
    final error = c.phase.value == PurchasePhase.error
        ? _errorText(s, c.lastError.value)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        if (product != null)
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title, style: AppText.sectionTitle),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(product.description, style: AppText.bodySmall),
                ],
              ],
            ),
          ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            error,
            textAlign: TextAlign.center,
            style: AppText.bodySmall.copyWith(color: AppColors.terracottaCoral),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (product != null)
          PremiumButton(
            label: s.premiumBuyFor(product.price),
            icon: AppIcon.check,
            onPressed: c.buy,
          ),
        const SizedBox(height: AppSpacing.sm),
        PremiumButton(
          label: s.premiumRestore,
          variant: ButtonVariant.ghost,
          size: ButtonSize.small,
          onPressed: c.restore,
        ),
      ],
    );
  }

  Widget _activePanel(AppLocalizations s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        AppPanel(
          child: Column(
            children: [
              const AppIconView(
                AppIcon.check,
                size: 40,
                color: AppColors.antiqueGold,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(s.premiumActive, style: AppText.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              Text(
                s.premiumActiveBody,
                textAlign: TextAlign.center,
                style: AppText.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _busy(String message) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xxl),
    child: LoadingView(message: message),
  );

  Widget _message(String message, {required AppIcon icon}) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl),
    child: AppPanel(
      child: Column(
        children: [
          AppIconView(icon, size: 36, color: AppColors.antiqueGold),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center, style: AppText.body),
        ],
      ),
    ),
  );

  Widget _retryable(String message) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl),
    child: ErrorView(
      title: message,
      retryLabel: Strings.s.commonRetry,
      onRetry: c.load,
    ),
  );

  String _errorText(AppLocalizations s, PurchaseError? error) =>
      switch (error) {
        PurchaseError.cancelled => s.premiumCancelled,
        PurchaseError.paymentFailed => s.premiumFailed,
        PurchaseError.verificationFailed ||
        PurchaseError.unknown => s.premiumVerifyFailed,
        PurchaseError.verificationUnavailable =>
          s.premiumVerificationUnavailable,
        PurchaseError.alreadyOwnedElsewhere => s.premiumOwnedElsewhere,
        PurchaseError.nothingToRestore => s.premiumNothingToRestore,
        PurchaseError.network => s.premiumNetwork,
        PurchaseError.notSignedIn => s.premiumSignInRequired,
        PurchaseError.storeUnavailable => s.premiumStoreUnavailable,
        PurchaseError.productMissing => s.premiumProductMissing,
        null => s.premiumFailed,
      };
}
