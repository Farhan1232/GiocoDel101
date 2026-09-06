import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/card_backs.dart';
import '../../../app/theme/deck_styles.dart';
import '../../../app/theme/table_themes.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/cards/card_back_painter.dart';
import '../../../core/widgets/cards/card_face_painter.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../../game/domain/card_rank.dart';
import '../../game/domain/card_suit.dart';
import '../../game/domain/game_card.dart';
import '../../settings/application/settings_controller.dart';
import '../application/purchase_controller.dart';
import '../domain/entitlement.dart';
import '../domain/shop_catalog.dart';
import 'cosmetic_gate.dart';

/// §shop — the Negozio.
///
/// Five optional cosmetics, each a permanent one-time purchase. The game —
/// every rule, every mode, online and offline — stays free; nothing here is
/// an advantage. Everything the player reads about a product, above all its
/// price, comes from the store's own localized metadata
/// (`ProductDetails.price`), never from a hard-coded string: the client can
/// re-price in Play Console / App Store Connect without an app update. A
/// product the store has not returned shows an honest "unavailable" line —
/// never an invented price.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final PurchaseController c = Get.find<PurchaseController>();
  final SettingsController settings = Get.find<SettingsController>();

  /// Set when the shop was opened by tapping a locked cosmetic
  /// (`Get.toNamed(AppRoutes.shop, arguments: productId)`). That item is
  /// scrolled to, outlined, and its purchase is started as soon as the store
  /// has answered — the tap the player made WAS "I want to buy this one".
  String? _target;
  bool _targetHandled = false;

  /// The card the player has their eye on: ringed in gold. Set by the
  /// locked-cosmetic route that opened the shop, and by any tap.
  String? _selected;
  final Map<String, GlobalKey> _cardKeys = {
    for (final p in ShopCatalog.products) p.id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _target = args is String && ShopCatalog.byId(args) != null ? args : null;
    _selected = _target;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await c.load();
      if (mounted) await _openTarget();
    });
  }

  /// Brings the tapped item into view and hands it to the store. Runs once:
  /// a failed or cancelled purchase leaves the player on the shop, in
  /// control, rather than re-opening the payment sheet under their thumb.
  Future<void> _openTarget() async {
    final target = _target;
    if (target == null || _targetHandled || !mounted) return;
    _targetHandled = true;

    // The cards only exist once `load()` has moved the phase off `loading`;
    // wait for the frame that paints them or there is nothing to scroll to.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final key = _cardKeys[target];
    final box = key?.currentContext;
    if (box != null && box.mounted) {
      await Scrollable.ensureVisible(
        box,
        duration: AppDurations.screenTransition,
        alignment: 0.1,
      );
    }
    if (!mounted) return;
    if (!_signedIn) return;
    if (c.owns(ShopCatalog.byId(target)!.entitlement)) return;
    if (c.products[target] == null) return;
    await c.buy(target);
  }

  bool get _signedIn => Get.find<SessionController>().isSignedIn;

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return ScreenScaffold(
      title: s.shopTitle,
      child: Obx(() {
        final phase = c.phase.value;
        if (phase == PurchasePhase.idle || phase == PurchasePhase.loading) {
          return const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxl),
            child: LoadingView(),
          );
        }
        // The scaffold scrolls; this is just the column it scrolls.
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                s.shopIntro,
                style: AppText.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                s.shopTapToBuy,
                style: AppText.caption.copyWith(color: AppColors.antiqueGold),
              ),
              if (!_signedIn) ...[
                const SizedBox(height: AppSpacing.md),
                _notice(s.premiumSignInRequired, icon: AppIcon.players),
              ] else if (phase == PurchasePhase.storeUnavailable) ...[
                const SizedBox(height: AppSpacing.md),
                _notice(s.premiumStoreUnavailable, icon: AppIcon.lock),
                const SizedBox(height: AppSpacing.sm),
                PremiumButton(
                  label: s.commonRetry,
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.small,
                  onPressed: c.load,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _statusBanner(s),
              for (final product in ShopCatalog.products) ...[
                // The item the player came here to buy is ringed in gold so
                // the shop opens on an answer to their tap, not on a wall of
                // five identical cards.
                Container(
                  key: _cardKeys[product.id],
                  decoration: product.id == _selected
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppRadii.lg + 3,
                          ),
                          border: Border.all(
                            color: AppColors.antiqueGold,
                            width: 2,
                          ),
                        )
                      : null,
                  padding: EdgeInsets.all(product.id == _selected ? 3 : 0),
                  child: _itemCard(s, product),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              PremiumButton(
                label: s.premiumRestore,
                variant: ButtonVariant.ghost,
                size: ButtonSize.small,
                onPressed: _signedIn && _storeReady ? c.restore : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                s.shopFootnote,
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.lg,
                children: [
                  _legalLink(
                    s.settingsTerms,
                    () => Get.toNamed<void>(AppRoutes.terms),
                  ),
                  _legalLink(
                    s.settingsPrivacy,
                    () => Get.toNamed<void>(AppRoutes.privacy),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  bool get _storeReady =>
      c.phase.value != PurchasePhase.storeUnavailable &&
      c.phase.value != PurchasePhase.loading;

  /// One line describing where the flow stands right now — purchase in
  /// flight, verification, a success or a mapped error. Empty when idle.
  Widget _statusBanner(AppLocalizations s) {
    final phase = c.phase.value;
    final String? text = switch (phase) {
      PurchasePhase.purchasing => s.premiumPending,
      PurchasePhase.verifying => s.premiumVerifying,
      PurchasePhase.success => s.premiumSuccess,
      PurchasePhase.restored => s.premiumRestored,
      PurchasePhase.error => _errorText(s, c.lastError.value),
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();
    final busy =
        phase == PurchasePhase.purchasing || phase == PurchasePhase.verifying;
    final failed = phase == PurchasePhase.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy) ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppText.bodySmall.copyWith(
                color: failed ? AppColors.terracottaCoral : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(AppLocalizations s, ShopProduct product) {
    final owned = c.owns(product.entitlement);
    final store = c.products[product.id];
    final busyThis = c.busyProductId.value == product.id;

    return AppPanel(
      onTap: owned ? null : () => _buy(product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _preview(product),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.displayName,
                            style: AppText.sectionTitle,
                          ),
                        ),
                        if (owned)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppIconView(
                                AppIcon.check,
                                size: 14,
                                color: AppColors.antiqueGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                s.shopOwned,
                                style: AppText.caption.copyWith(
                                  color: AppColors.antiqueGold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(product.description, style: AppText.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (owned)
            _selectionControl(s, product)
          else ...[
            PremiumButton(
              // The store's own localized price whenever it has answered.
              // Before that — a shop whose products are still being set up —
              // the card carries an openly indicative figure so it can be
              // read and pressed, and the press says what is missing.
              label: busyThis
                  ? s.premiumPending
                  : s.premiumBuyFor(
                      store?.price ?? ShopCatalog.indicativePrice,
                    ),
              icon: AppIcon.check,
              size: ButtonSize.small,
              onPressed: busyThis ? null : () => _buy(product),
            ),
            if (store == null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                s.shopPriceIndicative(ShopCatalog.indicativePrice),
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// One tap, one answer. Signed out it asks for the account the entitlement
  /// would be granted to; otherwise it hands the product to the store and,
  /// if the sheet cannot open, names the precise reason — which used to be
  /// the silence the player was left with.
  Future<void> _buy(ShopProduct product) async {
    setState(() => _selected = product.id);
    final s = Strings.s;

    if (!_signedIn) {
      await CosmeticGate.openLocked(entitlementId: product.entitlement);
      return;
    }

    final failure = await c.buy(product.id);
    if (failure == null || !mounted) return;

    await AppDialog.notice(
      title: s.shopCannotBuyTitle,
      body: switch (failure) {
        PurchaseError.storeUnavailable => s.shopStoreMissingBody,
        PurchaseError.productMissing => s.shopProductMissingBody(product.id),
        _ => _errorText(s, failure),
      },
      dismissLabel: s.gotIt,
    );
  }

  /// Owned items switch between selected and available. Selection is a local
  /// preference; OWNERSHIP stayed server-side to get here.
  Widget _selectionControl(AppLocalizations s, ShopProduct product) {
    final bool inUse = switch (product.kind) {
      CosmeticKind.tableTheme =>
        settings.settings.themeId == product.cosmeticId,
      CosmeticKind.cardBack =>
        settings.settings.cardBackId == product.cosmeticId,
      CosmeticKind.deckStyle =>
        settings.settings.deckStyleId == product.cosmeticId,
      CosmeticKind.gadget => settings.settings.gadgetId == product.cosmeticId,
    };
    return PremiumButton(
      label: inUse
          ? (product.kind == CosmeticKind.gadget ? s.shopRemove : s.shopInUse)
          : s.shopUse,
      variant: inUse ? ButtonVariant.ghost : ButtonVariant.secondary,
      size: ButtonSize.small,
      onPressed: () async {
        switch (product.kind) {
          case CosmeticKind.tableTheme:
            if (!inUse) await settings.setTheme(product.cosmeticId);
          case CosmeticKind.cardBack:
            if (!inUse) await settings.setCardBack(product.cosmeticId);
          case CosmeticKind.deckStyle:
            await settings.setDeckStyle(
              inUse ? DeckStyles.napoletane.id : product.cosmeticId,
            );
          case CosmeticKind.gadget:
            await settings.setGadget(inUse ? '' : product.cosmeticId);
        }
        setState(() {});
      },
    );
  }

  Widget _preview(ShopProduct product) {
    const double w = 64;
    final Widget child = switch (product.kind) {
      CosmeticKind.tableTheme => _themePreview(
        TableThemes.byId(product.cosmeticId),
      ),
      CosmeticKind.cardBack => CustomPaint(
        painter: CardBackPainter(design: CardBacks.byId(product.cosmeticId)),
      ),
      CosmeticKind.deckStyle => _gildedFacePreview(),
      CosmeticKind.gadget => CustomPaint(painter: _SigilPreviewPainter()),
    };
    final tall =
        product.kind == CosmeticKind.cardBack ||
        product.kind == CosmeticKind.deckStyle;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: SizedBox(width: w, height: tall ? w * 1.45 : w, child: child),
    );
  }

  Widget _themePreview(TableTheme t) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [t.backdropTop, t.feltInner, t.backdropBottom],
      ),
      border: Border.all(color: t.feltRim.withValues(alpha: 0.7)),
      borderRadius: BorderRadius.circular(AppRadii.sm),
    ),
    child: const SizedBox.expand(),
  );

  /// The same gilded treatment CardFaceImage applies in play, on a fixed
  /// sample card, so the preview shows exactly what the purchase changes.
  Widget _gildedFacePreview() => ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      1.06, 0.04, 0, 0, 8, //
      0.03, 0.98, 0, 0, 2, //
      0, 0.02, 0.84, 0, -6, //
      0, 0, 0, 1, 0,
    ]),
    child: CustomPaint(
      painter: CardFacePainter(
        card: const GameCard(CardSuit.denari, CardRank.asso),
      ),
    ),
  );

  Widget _notice(String message, {required AppIcon icon}) => AppPanel(
    child: Row(
      children: [
        AppIconView(icon, size: 20, color: AppColors.antiqueGold),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message, style: AppText.bodySmall)),
      ],
    ),
  );

  Widget _legalLink(String label, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    child: Text(
      label,
      style: AppText.caption.copyWith(
        color: AppColors.textMuted,
        decoration: TextDecoration.underline,
      ),
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

/// Small stand-alone rendering of the Sigillo del 101 for its shop card.
class _SigilPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final at = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.36;
    const gold = Color(0xFFD9A441);

    canvas.drawCircle(
      at,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = gold.withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      at,
      r * 0.82,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = gold.withValues(alpha: 0.5),
    );

    final label = TextPainter(
      text: TextSpan(
        text: '101',
        style: TextStyle(
          fontSize: r * 0.72,
          fontWeight: FontWeight.w700,
          color: gold,
          fontFamily: 'Cinzel',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
  }

  @override
  bool shouldRepaint(_SigilPreviewPainter oldDelegate) => false;
}
