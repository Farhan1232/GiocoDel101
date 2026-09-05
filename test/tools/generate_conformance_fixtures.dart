// A tool, not a test. Regenerates `test/fixtures/game_conformance/*.json`
// from the scenario catalogue in `test/support/conformance_scenarios.dart`.
//
//   GENERATE_FIXTURES=1 flutter test test/tools/generate_conformance_fixtures.dart
//
// Without the environment variable it does nothing, so a plain `flutter
// test` never rewrites fixtures. The `expectedState` block in each file is
// produced by the engine; the `assertions` block is copied verbatim from the
// hand-written scenario and is what keeps the fixtures honest.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_event.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';

import '../support/conformance_scenarios.dart';

const fixtureDir = 'test/fixtures/game_conformance';

void main() {
  test('generate conformance fixtures', () {
    if (Platform.environment['GENERATE_FIXTURES'] != '1') {
      return;
    }
    const engine = GameEngine();
    final dir = Directory(fixtureDir)..createSync(recursive: true);
    for (final f in dir.listSync().whereType<File>()) {
      if (f.path.endsWith('.json')) f.deleteSync();
    }
    const encoder = JsonEncoder.withIndent('  ');
    var written = 0;
    for (final sc in conformanceScenarios()) {
      final result = engine.applyAction(sc.state, sc.action);
      final json = <String, dynamic>{
        'name': sc.name,
        'description': sc.description,
        if (sc.rulesNote != null) 'rulesNote': sc.rulesNote,
        'actor': sc.action.playerId,
        'action': sc.action.toJson(),
        'initialState': sc.state.toJson(),
        'expectedFailure': switch (result) {
          ActionRejected(:final failure) => failure.key,
          ActionAccepted() => null,
        },
        'expectedState': switch (result) {
          ActionAccepted(:final state) => state.toJson(),
          ActionRejected() => sc.state.toJson(),
        },
        'expectedEvents': switch (result) {
          ActionAccepted(:final events) => events.map((e) => e.name).toList(),
          ActionRejected() => const <String>[],
        },
        'assertions': sc.assertions,
      };
      File(
        '$fixtureDir/${sc.name}.json',
      ).writeAsStringSync('${encoder.convert(json)}\n');
      written++;
    }
    // ignore: avoid_print
    print('wrote $written fixtures to $fixtureDir');
  });
}
