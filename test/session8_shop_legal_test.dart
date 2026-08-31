// Session 8 — five cosmetic products, entitlement-gated selection, and the
// legal screens.
//
// What is proven here: the paid cosmetics stay locked until the (fake)
// purchase stack answers for their entitlement; a revoked entitlement drops
// the app back to the free defaults without crashing; the deck style is
// pushed to the card renderer; the shop renders every product with the
// STORE's price string and never a hard-coded one; and both legal documents
// render in Italian and English, at small-phone size, with every owner
// placeholder unconfigured.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/app/theme/app_theme.dart';
import 'package:gioco_del_101/app/theme/card_backs.dart';
import 'package:gioco_del_101/app/theme/deck_styles.dart';
import 'package:gioco_del_101/app/theme/table_gadgets.dart';
import 'package:gioco_del_101/app/theme/table_themes.dart';
import 'package:gioco_del_101/core/legal/legal_config.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/features/legal/domain/legal_content.dart';
import 'package:gioco_del_101/features/legal/presentation/privacy_screen.dart';
import 'package:gioco_del_101/features/legal/presentation/terms_screen.dart';
import 'package:gioco_del_101/features/purchases/application/entitlement_repository.dart';
import 'package:gioco_del_101/features/purchases/application/purchase_controller.dart';
import 'package:gioco_del_101/features/purchases/application/purchase_store.dart';
import 'package:gioco_del_101/features/purchases/domain/entitlement.dart';
import 'package:gioco_del_101/features/purchases/domain/shop_catalog.dart';
import 'package:gioco_del_101/features/purchases/presentation/shop_screen.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';

class _ShopFakeStore implements PurchaseStore {
  final _events = StreamController<List<StorePurchase>>.broadcast();

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<StoreProducts> queryProducts(Set<String> ids) async => StoreProducts(
    found: [
      for (final id in ids)
        StoreProduct(
          id: id,
          title: id,
          description: 'store copy',
          price: 'STORE-PRICE-$id',
        ),
    ],
    notFound: const [],
  );

  @override
  Stream<List<StorePurchase>> get purchases => _events.stream;

  @override
  Future<void> buyNonConsumable(StoreProduct product) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> complete(StorePurchase purchase) async {}
}

class _ShopFakeEntitlements implements EntitlementRepository {
  final List<OwnedEntitlement> rows = [];

  @override
  Future<List<OwnedEntitlement>> status() async => rows;

  @override
  Future<OwnedEntitlement> verify({
    required String platform,
    required String productId,
    required String verificationData,
    String? transactionId,
  }) async =>
      throw const PurchaseException(PurchaseError.verificationUnavailable);
}

Future<SettingsController> _boot() async {
  SharedPreferences.setMockInitialValues({});
  Get.reset();
  final storage = await LocalStorage.open();
  InitialBinding(storage).dependencies();
  Motion.reduceMotion = true;
  return Get.find<SettingsController>();
}

Future<void> _render(WidgetTester tester, Widget child, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    ),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  tearDown(() {
    Motion.reduceMotion = false;
  });

  group('entitlement gating (§12, §13)', () {
    test('paid cosmetics are locked until the server says otherwise', () async {
      final settings = await _boot();
      // With no purchase stack answer, nothing paid unlocks.
      settings.entitlementCheck = null;
      expect(settings.isThemeUnlocked('tavolo_oro'), isFalse);
      expect(settings.isThemeUnlocked('tavolo_classico'), isFalse);
      expect(settings.isCardBackUnlocked('oro_reale'), isFalse);
      expect(settings.isDeckStyleUnlocked('inciso_oro'), isFalse);
      expect(settings.isGadgetUnlocked('sigillo'), isFalse);
      // The free defaults stay free.
      expect(settings.isThemeUnlocked('napoli_notte'), isTrue);
      expect(settings.isCardBackUnlocked('oro'), isTrue);
      expect(settings.isDeckStyleUnlocked('napoletane'), isTrue);
    });

    test('selection of a locked cosmetic is refused', () async {
      final settings = await _boot();
      settings.entitlementCheck = (_) => false;
      await settings.setTheme('tavolo_oro');
      await settings.setCardBack('oro_reale');
      await settings.setDeckStyle('inciso_oro');
      await settings.setGadget('sigillo');
      expect(settings.settings.themeId, 'napoli_notte');
      expect(settings.settings.cardBackId, 'oro');
      expect(settings.settings.deckStyleId, 'napoletane');
      expect(settings.settings.gadgetId, '');
    });

    test('an owned entitlement unlocks exactly its item', () async {
      final settings = await _boot();
      final owned = <String>{'table.gold'};
      settings.entitlementCheck = owned.contains;
      expect(settings.isThemeUnlocked('tavolo_oro'), isTrue);
      expect(settings.isThemeUnlocked('tavolo_classico'), isFalse);
      expect(settings.isCardBackUnlocked('oro_reale'), isFalse);
      await settings.setTheme('tavolo_oro');
      expect(settings.settings.themeId, 'tavolo_oro');
      // The gold theme prefers the gold back, but that back is NOT owned —
      // the free back must survive.
      expect(settings.settings.cardBackId, 'oro');
    });

    test('owning everything unlocks everything, each independently', () async {
      final settings = await _boot();
      settings.entitlementCheck = (_) => true;
      for (final t in TableThemes.all) {
        if (t.entitlementId != null) {
          expect(settings.isThemeUnlocked(t.id), isTrue, reason: t.id);
        }
      }
      for (final b in CardBacks.all) {
        if (b.entitlementId != null) {
          expect(settings.isCardBackUnlocked(b.id), isTrue, reason: b.id);
        }
      }
      await settings.setDeckStyle('inciso_oro');
      await settings.setGadget('sigillo');
      expect(settings.deckStyle.id, 'inciso_oro');
      expect(settings.gadget?.id, 'sigillo');
    });

    test('a revoked entitlement falls back to the free defaults', () async {
      final settings = await _boot();
      var owned = true;
      settings.entitlementCheck = (_) => owned;
      await settings.setTheme('tavolo_oro');
      await settings.setCardBack('oro_reale');
      await settings.setDeckStyle('inciso_oro');
      await settings.setGadget('sigillo');
      expect(settings.theme.id, 'tavolo_oro');
      // Refund / another account signs in: everything paid vanishes.
      owned = false;
      settings.refreshCosmetics();
      expect(settings.theme.id, 'napoli_notte');
      expect(settings.cardBack.id, 'oro');
      expect(settings.deckStyle.id, 'napoletane');
      expect(settings.gadget, isNull);
      expect(CardStyle.deckStyleId, 'napoletane');
    });

    test('the deck style is pushed to the card renderer', () async {
      final settings = await _boot();
      settings.entitlementCheck = (_) => true;
      expect(CardStyle.deckStyleId, 'napoletane');
      expect(CardStyle.gilded, isFalse);
      await settings.setDeckStyle('inciso_oro');
      expect(CardStyle.deckStyleId, 'inciso_oro');
      expect(CardStyle.gilded, isTrue);
      await settings.setDeckStyle('napoletane');
      expect(CardStyle.gilded, isFalse);
    });

    test('the gadget is a toggle and clears cleanly', () async {
      final settings = await _boot();
      settings.entitlementCheck = (_) => true;
      await settings.setGadget('sigillo');
      expect(settings.gadget?.id, 'sigillo');
      await settings.setGadget('');
      expect(settings.gadget, isNull);
      expect(TableGadgets.byId(''), isNull);
    });
  });

  group('the shop (§9)', () {
    testWidgets('renders all five products with the store price string only', (
      tester,
    ) async {
      await _boot();
      Get.delete<PurchaseController>(force: true);
      final purchases = Get.put<PurchaseController>(
        PurchaseController(
          store: _ShopFakeStore(),
          entitlements: _ShopFakeEntitlements(),
        ),
        permanent: true,
      );
      purchases.onInit();

      await _render(tester, const ShopScreen(), const Size(390, 844));
      expect(tester.takeException(), isNull);

      for (final p in ShopCatalog.products) {
        expect(find.text(p.displayName), findsOneWidget, reason: p.id);
        // The price on screen is the fake store's own metadata string —
        // proof the UI shows store-returned prices, not compiled-in ones.
        expect(
          find.textContaining('STORE-PRICE-${p.id}'),
          findsOneWidget,
          reason: '${p.id} must price from store metadata',
        );
      }
      expect(
        find.textContaining('€'),
        findsNothing,
        reason: 'no hard-coded currency anywhere in the shop',
      );
    });

    testWidgets('an owned item shows Sbloccato and a selection control, '
        'not a purchase button', (tester) async {
      await _boot();
      Get.delete<PurchaseController>(force: true);
      final server = _ShopFakeEntitlements()
        ..rows.add(
          const OwnedEntitlement(
            entitlement: 'table.gold',
            status: EntitlementStatus.active,
            productId: ShopCatalog.tableGoldId,
            platform: 'android',
          ),
        );
      final purchases = Get.put<PurchaseController>(
        PurchaseController(store: _ShopFakeStore(), entitlements: server),
        permanent: true,
      );
      purchases.onInit();
      Get.find<SettingsController>().entitlementCheck = purchases.owns;

      await _render(tester, const ShopScreen(), const Size(390, 844));
      expect(tester.takeException(), isNull);
      expect(find.text('Sbloccato'), findsOneWidget);
      expect(
        find.textContaining('STORE-PRICE-${ShopCatalog.tableGoldId}'),
        findsNothing,
        reason: 'an owned item is never offered for sale again',
      );
      expect(find.text('Usa'), findsOneWidget);
    });

    testWidgets('shop renders clean at the small-phone floor', (tester) async {
      await _boot();
      await _render(tester, const ShopScreen(), const Size(360, 640));
      expect(tester.takeException(), isNull);
      expect(find.text('Ripristina acquisti'), findsOneWidget);
    });
  });

  group('legal screens (§18, §19, §37)', () {
    test('both documents have their sections in both languages', () {
      for (final locale in const ['it', 'en']) {
        final terms = LegalContent.terms(locale);
        final privacy = LegalContent.privacy(locale);
        expect(terms.sections.length, greaterThanOrEqualTo(12));
        expect(privacy.sections.length, greaterThanOrEqualTo(10));
        for (final s in [...terms.sections, ...privacy.sections]) {
          expect(s.title, isNotEmpty);
          expect(s.body, isNotEmpty);
        }
      }
      expect(LegalContent.terms('it').title, 'Termini e Condizioni');
      expect(LegalContent.terms('en').title, 'Terms & Conditions');
      expect(LegalContent.privacy('it').title, 'Informativa sulla Privacy');
      expect(LegalContent.privacy('en').title, 'Privacy Policy');
    });

    test('unconfigured owner details stay honest placeholders', () {
      // This build defines no LEGAL_* dart-defines, so the config is empty
      // and the text must say so rather than inventing a company.
      expect(LegalConfig.hasEntityName, isFalse);
      final body = LegalContent.terms('en').sections.first.body;
      expect(body, contains('owner to be designated'));
    });

    testWidgets('terms and privacy render clean, small phone, both languages', (
      tester,
    ) async {
      final settings = await _boot();
      for (final locale in const ['it', 'en']) {
        await settings.setLocale(Locale(locale));
        await _render(tester, const TermsScreen(), const Size(360, 640));
        expect(tester.takeException(), isNull, reason: 'terms $locale');
        await _render(tester, const PrivacyScreen(), const Size(360, 640));
        expect(tester.takeException(), isNull, reason: 'privacy $locale');
      }
      // Scrolling reaches the last section without overflow.
      await tester.drag(find.byType(ListView), const Offset(0, -8000));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('free content stays free (§11)', () {
    test(
      'the default theme, back and deck carry no entitlement and no lock',
      () {
        expect(TableThemes.napoliNotte.entitlementId, isNull);
        expect(TableThemes.napoliNotte.unlockAchievementId, isNull);
        expect(CardBacks.oro.entitlementId, isNull);
        expect(CardBacks.oro.unlockAchievementId, isNull);
        expect(DeckStyles.napoletane.entitlementId, isNull);
      },
    );

    test(
      'achievement cosmetics still unlock by achievement, not purchase',
      () async {
        final settings = await _boot();
        settings.entitlementCheck = (_) => false; // owns nothing
        expect(settings.isThemeUnlocked('maiolica'), isFalse);
        await settings.unlock(themeId: 'maiolica', cardBackId: 'cobalto');
        expect(settings.isThemeUnlocked('maiolica'), isTrue);
        expect(settings.isCardBackUnlocked('cobalto'), isTrue);
      },
    );
  });
}
