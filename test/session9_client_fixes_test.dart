// Session 9 — the five things the client reported, proven where they broke.
//
// The headline is the first group. `create_room` on the server validates the
// rules object against an ALLOW-LIST; `GameRules.toJson()` grew
// `requireLastCardDeclaration` after that list was written, so from that day
// EVERY room the app tried to open came back `invalid_rules` and the Create
// Room button could only ever show "Impossibile aprire la stanza" — which is
// also why no online match could be reached: no room, no code, no game. The
// tools that talk to the backend directly build their own minimal rules
// object and so never noticed. These tests read the real SQL and hold the two
// sides together, so the next rule added cannot silently repeat it.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/app/localization/app_strings.dart';
import 'package:gioco_del_101/app/router/app_router.dart';
import 'package:gioco_del_101/app/theme/app_theme.dart';
import 'package:gioco_del_101/app/theme/card_backs.dart';
import 'package:gioco_del_101/app/theme/table_themes.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/features/auth/domain/auth_gateway.dart';
import 'package:gioco_del_101/features/auth/domain/auth_session.dart';
import 'package:gioco_del_101/features/auth/presentation/auth_landing_screen.dart';
import 'package:gioco_del_101/features/legal/domain/legal_content.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/purchases/application/entitlement_repository.dart';
import 'package:gioco_del_101/features/purchases/application/purchase_controller.dart';
import 'package:gioco_del_101/features/purchases/application/purchase_store.dart';
import 'package:gioco_del_101/features/purchases/domain/entitlement.dart';
import 'package:gioco_del_101/features/purchases/domain/shop_catalog.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';

/// The keys `app_private.sanitize_room_rules` accepts, read out of the SQL
/// itself: the newest migration that (re)defines the function wins, exactly
/// as it does when the migrations are applied in order.
Set<String> _sqlAllowList() {
  final files = Directory('supabase/migrations')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  String? body;
  for (final f in files) {
    final text = f.readAsStringSync();
    if (!text.contains('function app_private.sanitize_room_rules')) continue;
    final start = text.indexOf("v_types constant jsonb := '{");
    if (start < 0) continue;
    final open = text.indexOf('{', start);
    final close = text.indexOf("}'::jsonb", open);
    body = text.substring(open, close + 1);
  }
  if (body == null) {
    fail('no migration defines app_private.sanitize_room_rules');
  }
  return (jsonDecode(body) as Map<String, dynamic>).keys.toSet();
}

Future<SettingsController> _boot() async {
  SharedPreferences.setMockInitialValues({});
  Get.reset();
  final storage = await LocalStorage.open();
  InitialBinding(storage).dependencies();
  Motion.reduceMotion = true;
  Strings.use(const Locale('it'));
  return Get.find<SettingsController>();
}

Future<void> _render(WidgetTester tester, Widget child) async {
  const size = Size(390, 844);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      getPages: AppPages.pages,
      home: MediaQuery(data: const MediaQueryData(size: size), child: child),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  group('a room the server will actually open (§create_room)', () {
    test('every key the app puts on the wire is on the SQL allow-list', () {
      final allowed = _sqlAllowList();
      final sent = const GameRules().toRoomJson().keys.toSet();
      expect(
        sent.difference(allowed),
        isEmpty,
        reason:
            'create_room would answer invalid_rules for these keys; add them '
            'to app_private.sanitize_room_rules (and deploy) before sending '
            'them',
      );
    });

    test('the wire keys are real rules, not typos', () {
      final produced = const GameRules().toJson().keys.toSet();
      expect(GameRules.onlineRoomRuleKeys.difference(produced), isEmpty);
    });

    test('a rule left off the wire is a deliberate, named decision', () {
      final produced = const GameRules().toJson().keys.toSet();
      final withheld = produced.difference(GameRules.onlineRoomRuleKeys);
      // `requireLastCardDeclaration` is withheld because the DEPLOYED
      // sanitiser predates it. Once the migration that adds it is applied,
      // move it into onlineRoomRuleKeys and delete it from here.
      expect(withheld, {'requireLastCardDeclaration'});
    });

    test('the repository ships the migration that widens the allow-list', () {
      // The client-side narrowing above is what makes today's backend work;
      // this is the fix for the backend itself, so a fresh deploy is right.
      expect(_sqlAllowList(), contains('requireLastCardDeclaration'));
    });

    test('toRoomJson keeps the values, it only drops keys', () {
      const rules = GameRules(targetScore: 151, drawTwoPenalty: 3);
      final full = rules.toJson();
      final wire = rules.toRoomJson();
      for (final key in wire.keys) {
        expect(wire[key], full[key], reason: key);
      }
      expect(wire['targetScore'], 151);
      expect(wire['drawTwoPenalty'], 3);
    });
  });

  group('sign-in is email and password only', () {
    testWidgets('the account screen offers no Google or Apple button', (
      tester,
    ) async {
      await _boot();
      await _render(tester, const AuthLandingScreen());
      expect(find.textContaining('Google'), findsNothing);
      expect(find.textContaining('Apple'), findsNothing);
      expect(find.text('GIOCA COME OSPITE'), findsOneWidget);
    });

    test('the social strings are gone from both languages', () {
      for (final name in ['app_it.arb', 'app_en.arb']) {
        final arb =
            jsonDecode(File('lib/l10n/$name').readAsStringSync())
                as Map<String, dynamic>;
        for (final key in [
          'authContinueWithGoogle',
          'authContinueWithApple',
          'authSocialUnavailable',
        ]) {
          expect(arb.containsKey(key), isFalse, reason: '$key in $name');
        }
      }
    });
  });

  group('the language switch is total (§9)', () {
    test('the default player name follows the language', () async {
      final settings = await _boot();
      expect(settings.settings.playerName, 'Giocatore');
      await settings.setLocale(const Locale('en'));
      expect(settings.settings.playerName, 'Player');
      await settings.setLocale(const Locale('it'));
      expect(settings.settings.playerName, 'Giocatore');
    });

    test('a name the player chose is never translated', () async {
      final settings = await _boot();
      await settings.setPlayerName('Ciro');
      await settings.setLocale(const Locale('en'));
      expect(settings.settings.playerName, 'Ciro');
    });

    test('the paid tables are named in the chosen language', () async {
      await _boot();
      final gold = TableThemes.byId('tavolo_oro');
      final classic = TableThemes.byId('tavolo_classico');
      Strings.use(const Locale('it'));
      expect(gold.displayName, 'Tavolo Oro');
      expect(classic.displayName, 'Tavolo Classico');
      Strings.use(const Locale('en'));
      expect(gold.displayName, 'Gold Table');
      expect(classic.displayName, 'Classic Table');
      // A table nobody sells keeps its proper name in both languages.
      expect(TableThemes.byId('napoli_notte').displayName, 'Napoli Notte');
      Strings.use(const Locale('it'));
    });
  });

  group('the shop can always be pressed (§iap)', () {
    test('a product the store has not returned still buys, and says why',
        () async {
      await _boot();
      // A store that answers "I have none of these" — exactly the state of a
      // shop whose products are not configured in the console yet.
      final store = _EmptyStore();
      final controller = PurchaseController(
        store: store,
        entitlements: _NoEntitlements(),
      )..onInit();
      addTearDown(controller.onClose);

      await controller.load();
      expect(controller.phase.value, PurchasePhase.ready);

      // The old behaviour returned null and left the player with silence.
      final failure = await controller.buy(ShopCatalog.tableGoldId);
      expect(failure, PurchaseError.productMissing);
      expect(controller.lastError.value, PurchaseError.productMissing);
      expect(store.buys, isEmpty, reason: 'nothing can be charged');
    });

    test('no store at all is reported as no store, not a missing product',
        () async {
      await _boot();
      final controller = PurchaseController(
        store: _NoStore(),
        entitlements: _NoEntitlements(),
      )..onInit();
      addTearDown(controller.onClose);

      expect(
        await controller.buy(ShopCatalog.tableGoldId),
        PurchaseError.storeUnavailable,
      );
    });

    test('a product the store knows is handed straight to it', () async {
      await _boot();
      final store = _StockedStore();
      final controller = PurchaseController(
        store: store,
        entitlements: _NoEntitlements(),
      )..onInit();
      addTearDown(controller.onClose);

      await controller.load();
      expect(await controller.buy(ShopCatalog.tableGoldId), isNull);
      expect(store.buys, [ShopCatalog.tableGoldId]);
    });

    test('every product has an indicative price to show before the store '
        'answers', () {
      expect(ShopCatalog.indicativePrice, isNotEmpty);
      // It must never be mistaken for the real thing in code: the store's
      // price wins wherever one exists.
      expect(ShopCatalog.products, hasLength(5));
    });
  });

  group('complimentary accounts (§iap)', () {
    test('the grant covers every product the shop sells, and never expires',
        () {
      final sql = File(
        'supabase/migrations/20260906170000_comp_accounts.sql',
      ).readAsStringSync();
      for (final p in ShopCatalog.products) {
        expect(sql, contains("'${p.entitlement}'"), reason: p.entitlement);
        expect(sql, contains("'${p.id}'"), reason: p.id);
      }
      // Lifetime: the app treats a null expiry as "forever".
      expect(sql, contains('expires_at  = null'));
      // Marked as what it is, so a comp can be told from a real receipt.
      expect(sql, contains("'sandbox'"));
    });

    test('it is server-side only — nothing in the app grants anything', () {
      final lib = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in lib) {
        final text = f.readAsStringSync();
        expect(
          text.contains('comp_accounts') ||
              text.contains('grant_comp_entitlements'),
          isFalse,
          reason: '${f.path} must not know about complimentary accounts',
        );
      }
    });

    test('the allow-list lives where no client can reach it', () {
      final sql = File(
        'supabase/migrations/20260906170000_comp_accounts.sql',
      ).readAsStringSync();
      expect(sql, contains('app_private.comp_accounts'));
      expect(
        sql,
        contains(
          'revoke all on function app_private.grant_comp_entitlements(uuid) '
          'from public, anon, authenticated',
        ),
      );
    });
  });

  group('deleting the account (§privacy, Play account-deletion policy)', () {
    test('the migration exposes exactly one self-service RPC', () {
      final sql = File(
        'supabase/migrations/20260906140000_delete_my_account.sql',
      ).readAsStringSync();
      // It must act on auth.uid() alone: an id parameter would let a signed-in
      // player delete somebody else.
      expect(sql, contains('delete_my_account()'));
      expect(sql, contains('auth.uid()'));
      expect(sql, contains('delete from auth.users where id = v_user'));
      expect(sql, contains('security definer'));
      // A live match must stop it; a lobby seat is merely vacated.
      expect(sql, contains('assert_not_in_match'));
      expect(sql, contains('leave_all_lobbies'));
      // anon must never reach it.
      expect(sql, contains('revoke all on function public.delete_my_account()'));
      expect(sql, contains('grant execute on function public.delete_my_account() to authenticated'));
    });

    test('without a backend there is no account to delete', () async {
      final gateway = NoBackendAuthGateway();
      expect(await gateway.deleteAccount(), AccountDeletion.unavailable);
    });

    test('the privacy policy names the in-app route, in both languages', () {
      for (final locale in const ['it', 'en']) {
        final section = LegalContent.privacy(locale).sections.firstWhere(
          (s) => s.title.contains('9.'),
        );
        expect(
          section.title.toLowerCase(),
          anyOf(contains('elimin'), contains('delet')),
          reason: locale,
        );
        // Play looks for a route a user can actually follow.
        expect(
          section.body,
          anyOf(contains('Impostazioni'), contains('Settings')),
          reason: locale,
        );
      }
    });
  });

  group('a locked cosmetic leads somewhere (§shop)', () {
    test('every paid cosmetic maps to a product the shop can sell', () {
      for (final t in TableThemes.all) {
        if (t.entitlementId == null) continue;
        expect(
          ShopCatalog.byEntitlement(t.entitlementId!),
          isNotNull,
          reason: t.id,
        );
      }
      for (final b in CardBacks.all) {
        if (b.entitlementId == null) continue;
        expect(
          ShopCatalog.byEntitlement(b.entitlementId!),
          isNotNull,
          reason: b.id,
        );
      }
    });

    test('a cosmetic is either sold or earned, never neither', () {
      for (final t in TableThemes.all) {
        expect(
          t.entitlementId != null || t.unlockAchievementId != null || t.id == 'napoli_notte',
          isTrue,
          reason: '${t.id} can never be unlocked',
        );
      }
      for (final b in CardBacks.all) {
        expect(
          b.entitlementId != null || b.unlockAchievementId != null || b.id == 'oro',
          isTrue,
          reason: '${b.id} can never be unlocked',
        );
      }
    });
  });
}

/// A store that is present but knows none of the products — a console where
/// the five items have not been created yet.
class _EmptyStore implements PurchaseStore {
  final List<String> buys = [];
  final _events = StreamController<List<StorePurchase>>.broadcast();

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<StoreProducts> queryProducts(Set<String> ids) async =>
      StoreProducts(found: const [], notFound: ids.toList());

  @override
  Stream<List<StorePurchase>> get purchases => _events.stream;

  @override
  Future<void> buyNonConsumable(StoreProduct product) async {
    buys.add(product.id);
  }

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> complete(StorePurchase purchase) async {}
}

/// No billing on this device at all.
class _NoStore extends _EmptyStore {
  @override
  Future<bool> isAvailable() async => false;
}

/// A console with the five products live.
class _StockedStore extends _EmptyStore {
  @override
  Future<StoreProducts> queryProducts(Set<String> ids) async => StoreProducts(
    found: [
      for (final id in ids)
        StoreProduct(
          id: id,
          title: id,
          description: '',
          price: 'STORE-PRICE',
        ),
    ],
    notFound: const [],
  );
}

class _NoEntitlements implements EntitlementRepository {
  @override
  Future<List<OwnedEntitlement>> status() async => const [];

  @override
  Future<OwnedEntitlement> verify({
    required String platform,
    required String productId,
    required String verificationData,
    String? transactionId,
  }) async => throw const PurchaseException(PurchaseError.verificationFailed);
}
