import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gioco_del_101/app/localization/app_strings.dart';
import 'package:gioco_del_101/core/widgets/network_banner.dart';
import 'package:gioco_del_101/features/auth/domain/auth_validators.dart';
import 'package:gioco_del_101/features/game/domain/table_session_status.dart';
import 'package:gioco_del_101/features/leaderboard/domain/leaderboard_models.dart';
import 'package:gioco_del_101/features/online/domain/online_status.dart';
import 'package:gioco_del_101/features/profile/domain/level_ladder.dart';
import 'package:gioco_del_101/features/profile/domain/profile_summary.dart';
import 'package:gioco_del_101/features/profile/domain/statistics_model.dart';
import 'package:gioco_del_101/features/rewards/domain/daily_reward.dart';
import 'package:gioco_del_101/features/rooms/domain/room_models.dart';
import 'package:gioco_del_101/features/settings/domain/settings_model.dart';

void main() {
  group('Auth validation (§D, §E, §F)', () {
    test('accepts ordinary addresses and rejects malformed ones', () {
      for (final good in const [
        'a@b.co',
        'farhan.test@example.com',
        'nome+tag@dominio.it',
      ]) {
        expect(AuthValidators.isEmailValid(good), isTrue, reason: good);
      }
      for (final bad in const [
        '',
        'plain',
        'no@domain',
        'no@@double.com',
        'spaces in@mail.com',
        '@leading.com',
      ]) {
        expect(AuthValidators.isEmailValid(bad), isFalse, reason: bad);
      }
    });

    test('trims before judging an address', () {
      expect(AuthValidators.isEmailValid('  a@b.co  '), isTrue);
    });

    test('password floor is eight characters', () {
      expect(AuthValidators.isPasswordValid('1234567'), isFalse);
      expect(AuthValidators.isPasswordValid('12345678'), isTrue);
    });

    test('nickname is bounded at both ends', () {
      expect(AuthValidators.isNicknameValid('ab'), isFalse);
      expect(AuthValidators.isNicknameValid('abc'), isTrue);
      expect(AuthValidators.isNicknameValid('a' * 16), isTrue);
      expect(AuthValidators.isNicknameValid('a' * 17), isFalse);
      expect(AuthValidators.isNicknameValid('   ab   '), isFalse);
    });
  });

  group('Room codes (§J)', () {
    test('normalises case and drops look-alike characters', () {
      // O, I, 0 and 1 are not in the alphabet, so they are stripped.
      expect(RoomCode.normalise('abc-def'), 'ABCDEF');
      expect(RoomCode.normalise('a b c d e f'), 'ABCDEF');
      expect(RoomCode.normalise('OI01ABCDEF'), 'ABCDEF');
    });

    test('never returns more than six characters', () {
      expect(RoomCode.normalise('ABCDEFGHJK').length, RoomCode.length);
    });

    test('validity requires exactly six alphabet characters', () {
      expect(RoomCode.isValid('ABCDEF'), isTrue);
      expect(RoomCode.isValid('ABCDE'), isFalse);
      expect(RoomCode.isValid('ABCDE0'), isFalse);
      expect(RoomCode.isValid(''), isFalse);
    });

    test('the alphabet excludes every look-alike', () {
      for (final banned in const ['O', 'I', '0', '1']) {
        expect(RoomCode.alphabet.contains(banned), isFalse, reason: banned);
      }
    });
  });

  group('Room configuration (§I)', () {
    test('carries the house rules through copyWith and JSON', () {
      const base = RoomConfig();
      final config = base.copyWith(
        playerCount: 3,
        isPrivate: false,
        turnTimer: TurnTimer.sixty,
        rules: base.rules.copyWith(stackDrawTwos: false),
      );
      expect(config.playerCount, 3);
      expect(config.rules.stackDrawTwos, isFalse);

      final json = config.toJson();
      expect(json['turnTimer'], 'sixty');
      expect((json['rules'] as Map)['stackDrawTwos'], isFalse);
    });

    test('a pending lobby seats only the host', () {
      final lobby = RoomLobbyState.pending(
        config: const RoomConfig(playerCount: 4),
        hostNickname: 'Farhan',
        hostAvatarId: 'lucia',
      );
      expect(lobby.seats, hasLength(4));
      expect(lobby.filledSeats, 1);
      expect(lobby.seats.first.isHost, isTrue);
      // Nothing invents an opponent.
      expect(lobby.seats.skip(1).every((s) => s.isEmpty), isTrue);
    });
  });

  group('Profile summary (§P)', () {
    test('derives losses and win rate from the local counters', () {
      const settings = SettingsModel(playerName: 'Farhan', avatarId: 'lucia');
      const stats = StatisticsModel(matchesPlayed: 10, matchesWon: 4);
      final profile = ProfileSummary.fromLocal(settings, stats);

      expect(profile.nickname, 'Farhan');
      expect(profile.matchesLost, 6);
      expect(profile.winPercentage, 40);
    });

    test('a fresh player is level 1 with an empty bar', () {
      final profile = ProfileSummary.fromLocal(
        const SettingsModel(),
        const StatisticsModel(),
      );
      expect(profile.level, 1);
      expect(profile.xpIntoLevel, 0);
      expect(profile.levelProgress, 0);
      expect(profile.matchesLost, 0);
      expect(profile.winPercentage, 0);
    });

    test('levels rise and progress always stays in range', () {
      for (final played in const [0, 1, 5, 25, 100, 1000]) {
        // Session 5: offline XP is an explicit counter on the record.
        final profile = ProfileSummary.fromLocal(
          const SettingsModel(),
          StatisticsModel(
            matchesPlayed: played,
            matchesWon: played ~/ 2,
            xp: played * LevelLadder.xpPerMatch,
          ),
        );
        expect(profile.level, greaterThanOrEqualTo(1));
        expect(profile.levelProgress, inInclusiveRange(0.0, 1.0));
        expect(profile.xpIntoLevel, lessThan(profile.xpForLevel));
      }
      final novice = ProfileSummary.fromLocal(
        const SettingsModel(),
        const StatisticsModel(matchesPlayed: 1, xp: LevelLadder.xpPerMatch),
      );
      final veteran = ProfileSummary.fromLocal(
        const SettingsModel(),
        const StatisticsModel(
          matchesPlayed: 200,
          xp: 200 * LevelLadder.xpPerMatch,
        ),
      );
      expect(veteran.level, greaterThan(novice.level));
    });

    test('progression is still flagged as a placeholder', () {
      final profile = ProfileSummary.fromLocal(
        const SettingsModel(),
        const StatisticsModel(),
      );
      expect(profile.isPlaceholderProgression, isTrue);
    });
  });

  group('Daily reward (§T)', () {
    test('the ladder is seven days and ends on the biggest prize', () {
      expect(DailyRewardCalendar.ladder, hasLength(7));
      expect(
        DailyRewardCalendar.ladder.last,
        greaterThan(DailyRewardCalendar.ladder.first),
      );
    });

    test('a new player has day one claimable and nothing claimed', () {
      final calendar = DailyRewardCalendar.forStreak(0);
      expect(calendar.days, hasLength(7));
      expect(calendar.days.first.isToday, isTrue);
      expect(calendar.days.every((d) => !d.isClaimed), isTrue);
      expect(calendar.canClaimToday, isTrue);
    });

    test('a streak marks exactly that many days claimed', () {
      final calendar = DailyRewardCalendar.forStreak(3);
      expect(calendar.days.where((d) => d.isClaimed), hasLength(3));
      expect(calendar.days[3].isToday, isTrue);
    });

    test('an out-of-range streak cannot break the calendar', () {
      final calendar = DailyRewardCalendar.forStreak(99);
      expect(calendar.days.where((d) => d.isClaimed), hasLength(7));
      expect(calendar.canClaimToday, isFalse);
    });
  });

  group('Table session status (§M)', () {
    test('an offline match draws neither timer nor connection dot', () {
      const status = TableSessionStatus.offlineLocal;
      expect(status.isOnline, isFalse);
      expect(status.hasTimer, isFalse);
      expect(status.showsConnection, isFalse);
    });

    test('the timer fraction is derived and clamped', () {
      const status = TableSessionStatus(
        isOnline: true,
        turnSecondsRemaining: 15,
        turnSecondsTotal: 30,
      );
      expect(status.hasTimer, isTrue);
      expect(status.timerProgress, 0.5);

      const overrun = TableSessionStatus(
        isOnline: true,
        turnSecondsRemaining: 40,
        turnSecondsTotal: 30,
      );
      expect(overrun.timerProgress, 1.0);
    });

    test('the connection dot only shows for an unhealthy online match', () {
      const healthy = TableSessionStatus(isOnline: true);
      const dropped = TableSessionStatus(
        isOnline: true,
        connection: NetworkStatus.offline,
      );
      const offlineGame = TableSessionStatus(
        isOnline: false,
        connection: NetworkStatus.offline,
      );
      expect(healthy.showsConnection, isFalse);
      expect(dropped.showsConnection, isTrue);
      expect(offlineGame.showsConnection, isFalse);
    });
  });

  group('Online availability', () {
    test('Session 1 ships with no backend, and says so', () {
      expect(OnlineStatus.availability, BackendAvailability.notConfigured);
      expect(OnlineStatus.isConfigured, isFalse);
    });

    test('both leaderboards are empty and unavailable', () {
      for (final scope in LeaderboardScope.values) {
        final board = LeaderboardBoard(scope: scope);
        expect(board.isEmpty, isTrue);
        expect(board.isAvailable, isFalse);
      }
    });
  });

  group('Localization (§9)', () {
    test('Italian is the primary language and the fallback', () {
      expect(Strings.supported.first.languageCode, 'it');
      expect(Strings.fallback.languageCode, 'it');
    });

    test('regional locales narrow to a shipped one', () {
      expect(Strings.resolve(const Locale('en', 'GB')).languageCode, 'en');
      expect(Strings.resolve(const Locale('it', 'CH')).languageCode, 'it');
      // Anything unsupported lands on Italian, not English.
      expect(Strings.resolve(const Locale('fr')).languageCode, 'it');
      expect(Strings.resolve(null).languageCode, 'it');
    });

    test('switching locale swaps the resolved bundle', () {
      Strings.use(const Locale('en'));
      expect(Strings.s.commonNext, 'Next');
      Strings.use(const Locale('it'));
      expect(Strings.s.commonNext, 'Avanti');
      expect(Strings.s.reactions8, hasLength(8));
    });

    test('the two ARB files define exactly the same keys', () {
      Map<String, dynamic> load(String name) =>
          jsonDecode(File('lib/l10n/$name').readAsStringSync())
              as Map<String, dynamic>;

      Set<String> keys(Map<String, dynamic> arb) =>
          arb.keys.where((k) => !k.startsWith('@')).toSet();

      final it = load('app_it.arb');
      final en = load('app_en.arb');
      expect(
        keys(en).difference(keys(it)),
        isEmpty,
        reason: 'English has keys Italian does not',
      );
      expect(
        keys(it).difference(keys(en)),
        isEmpty,
        reason: 'Italian has keys English does not',
      );
    });

    test('no string is left untranslated by accident', () {
      Map<String, dynamic> load(String name) =>
          jsonDecode(File('lib/l10n/$name').readAsStringSync())
              as Map<String, dynamic>;
      final it = load('app_it.arb');
      final en = load('app_en.arb');

      // A handful legitimately match across languages (proper nouns, symbols).
      // Words that are genuinely the same in both languages: proper nouns,
      // loanwords ("round", "nickname") and symbol-only strings.
      const identicalIsFine = {
        'appName',
        'fieldEmail',
        'fieldPassword',
        'fieldNickname',
        'lobbyHost',
        'reaction4',
        // Session 4 — the preset reactions are Italian interjections the
        // English UI keeps on purpose, and "{seconds}s" is a unit.
        'reactionCiao',
        'reactionBravo',
        'reactionMammaMia',
        'reactionAhahaha',
        'reactionGg',
        'onlineTurnSeconds',
        'settingsAccount',
        'profileXpProgress',
        'suitSpade',
        'rankRe',
        'dailyReward',
        'commonLoading',
        'achVendettaTitle',
        'home',
        'modeVsComputer',
        'round',
        // Session 5 — the signature word and a unit string.
        'centounoTitle',
        'missionsReward',
        // Session 7 — a loanword used as-is in Italian.
        'premiumTitle',
      };
      final suspicious = <String>[];
      for (final key in it.keys.where((k) => !k.startsWith('@'))) {
        if (identicalIsFine.contains(key)) continue;
        if (it[key] == en[key]) suspicious.add(key);
      }
      expect(
        suspicious,
        isEmpty,
        reason: 'these keys are identical in both languages: $suspicious',
      );
    });
  });
}
