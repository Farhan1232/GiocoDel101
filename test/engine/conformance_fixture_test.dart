import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_event.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';

import '../support/conformance_scenarios.dart';

const fixtureDir = 'test/fixtures/game_conformance';
const engine = GameEngine();

/// Reads one assertion key off a state. Mirrors the key list documented on
/// [ConformanceScenario.assertions].
Object? readAssertion(GameState s, String key) {
  final parts = key.split('.');
  switch (parts.first) {
    case 'currentPlayerId':
      return s.currentPlayerId;
    case 'status':
      return s.status.key;
    case 'pendingDrawCount':
      return s.pendingDrawCount;
    case 'chainLength':
      return s.chainLength;
    case 'activeSuit':
      return s.activeSuit.key;
    case 'topCard':
      return s.topCard.id;
    case 'version':
      return s.version;
    case 'winnerId':
      return s.winnerId;
    case 'roundWinnerId':
      return s.roundWinnerId;
    case 'round':
      return s.round;
    case 'drawPileSize':
      return s.drawPile.length;
    case 'discardPileSize':
      return s.discardPile.length;
    case 'hasDrawnThisTurn':
      return s.hasDrawnThisTurn;
    case 'penaltyResolvedThisTurn':
      return s.penaltyResolvedThisTurn;
    case 'lastCardDeclaredBy':
      return s.lastCardDeclaredBy;
    case 'dealerSeat':
      return s.dealerSeat;
    case 'dealerId':
      return s.players[s.dealerSeat].id;
    case 'currentSeat':
      return s.currentSeat;
    case 'drawnCard':
      return s.drawnCard?.id;
    case 'handSize':
      return s.handOf(parts[1]).length;
    case 'score':
      return s.playerById(parts[1])!.score;
    case 'eliminated':
      return s.playerById(parts[1])!.eliminated;
  }
  throw ArgumentError('unknown assertion key $key');
}

void checkAssertions(
  GameState s,
  Map<String, Object?> assertions,
  String label,
) {
  for (final e in assertions.entries) {
    expect(readAssertion(s, e.key), e.value, reason: '$label: ${e.key}');
  }
}

void main() {
  final files =
      Directory(fixtureDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('fixtures exist for every scenario and nothing else', () {
    final onDisk = files
        .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
        .toSet();
    final declared = conformanceScenarios().map((s) => s.name).toSet();
    expect(
      onDisk,
      declared,
      reason:
          'run GENERATE_FIXTURES=1 flutter test test/tools/generate_conformance_fixtures.dart',
    );
    expect(
      declared.length,
      conformanceScenarios().length,
      reason: 'duplicate scenario name',
    );
  });

  group('Conformance fixtures replay against the engine', () {
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      test(name, () {
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final initial = GameState.fromJson(
          (json['initialState'] as Map).cast<String, dynamic>(),
        );
        final action = GameAction.fromJson(
          (json['action'] as Map).cast<String, dynamic>(),
        );
        final expected = GameState.fromJson(
          (json['expectedState'] as Map).cast<String, dynamic>(),
        );
        final expectedFailure = json['expectedFailure'] as String?;
        final assertions = (json['assertions'] as Map).cast<String, Object?>();
        expect(action.playerId, json['actor']);

        final result = engine.applyAction(initial, action);

        if (expectedFailure != null) {
          expect(
            result,
            isA<ActionRejected>(),
            reason: 'expected $expectedFailure',
          );
          expect((result as ActionRejected).failure.key, expectedFailure);
          expect(
            expected.toJson(),
            equals(initial.toJson()),
            reason: 'a rejected action must not change the state',
          );
          return;
        }

        expect(result, isA<ActionAccepted>(), reason: '$result');
        final accepted = result as ActionAccepted;
        expect(
          accepted.state.toJson(),
          equals(expected.toJson()),
          reason: 'state diverged from fixture',
        );
        expect(
          accepted.events.map((e) => e.name).toList(),
          (json['expectedEvents'] as List).cast<String>(),
        );
        // The hand-written facts must hold for both the fixture and the run.
        checkAssertions(expected, assertions, 'fixture');
        checkAssertions(accepted.state, assertions, 'engine');
        expect(accepted.state.version, initial.version + 1);
        expect(accepted.state.totalCards, initial.totalCards);
      });
    }
  });

  group('Scenario catalogue self-check (independent of the files)', () {
    for (final sc in conformanceScenarios()) {
      test(sc.name, () {
        final result = engine.applyAction(sc.state, sc.action);
        if (sc.expectedFailure != null) {
          expect(result.failure, sc.expectedFailure);
          return;
        }
        expect(result, isA<ActionAccepted>(), reason: '$result');
        final accepted = result as ActionAccepted;
        checkAssertions(accepted.state, sc.assertions, sc.name);
        if (sc.expectedEvents != null) {
          expect(
            accepted.events.map((e) => e.name).toList(),
            sc.expectedEvents,
          );
        }
      });
    }
  });
}
