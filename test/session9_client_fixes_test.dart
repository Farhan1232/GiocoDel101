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
import 'package:gioco_del_101/features/auth/presentation/auth_landing_screen.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
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
