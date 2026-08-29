// The authoritative server runs THIS engine — not a port of it.
//
// `tool/build_engine_js.sh` compiles this file with dart2js into
// `supabase/functions/_shared/engine.js`, which the `match` Edge Function
// loads. Every function below takes and returns JSON strings so the JS side
// never touches Dart objects. Nothing here has I/O, a clock or randomness:
// seeds and timestamps come from the caller, exactly as in the app.
//
// Exports (all attached to globalThis):
//   gioco101CreateGame(paramsJson)                -> {ok, state} | {ok:false, failure, message}
//   gioco101ApplyAction(stateJson, actionJson, now|null)
//                                                 -> {ok, state, events} | {ok:false, failure}
//   gioco101Validate(stateJson, actionJson)       -> {failure: name|null}
//   gioco101Playable(stateJson, playerId)         -> {cards:[ids], canDraw, canPass, mustTakePenalty}
//   gioco101EngineVersion()                       -> a string identifying this build
import 'dart:convert';
import 'dart:js_interop';

import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_event.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';

const _engine = GameEngine();

Map<String, dynamic> _decode(String json) =>
    jsonDecode(json) as Map<String, dynamic>;

String _createGame(String paramsJson) {
  try {
    final p = _decode(paramsJson);
    final players = [
      for (final raw in p['players'] as List)
        GamePlayer.fromJson((raw as Map).cast<String, dynamic>()),
    ];
    final rules = GameRules.fromJson(
      ((p['rules'] as Map?) ?? const {}).cast<String, dynamic>(),
    );
    final state = _engine.createGame(
      gameId: p['gameId'] as String,
      players: players,
      mode: GameMode.fromKey(p['mode'] as String? ?? 'passAndPlay'),
      seed: (p['seed'] as num).toInt(),
      rules: rules,
      startingSeat: (p['startingSeat'] as num?)?.toInt() ?? 0,
      now: (p['now'] as num?)?.toInt(),
    );
    return jsonEncode({'ok': true, 'state': state.toJson()});
  } on GameSetupException catch (e) {
    return jsonEncode({
      'ok': false,
      'failure': e.failure.name,
      'message': e.message,
    });
  } on FormatException catch (e) {
    return jsonEncode({
      'ok': false,
      'failure': 'invalidState',
      'message': e.message,
    });
  }
}

String _applyAction(String stateJson, String actionJson, int? now) {
  final GameState state;
  final GameAction action;
  try {
    state = GameState.fromJson(_decode(stateJson));
    action = GameAction.fromJson(_decode(actionJson));
  } on FormatException catch (e) {
    return jsonEncode({
      'ok': false,
      'failure': 'invalidState',
      'message': e.message,
    });
  }
  final result = _engine.applyAction(state, action, now: now);
  return switch (result) {
    ActionAccepted(:final state, :final events) => jsonEncode({
      'ok': true,
      'state': state.toJson(),
      'events': [for (final e in events) e.name],
    }),
    ActionRejected(:final failure) => jsonEncode({
      'ok': false,
      'failure': failure.name,
    }),
  };
}

String _validate(String stateJson, String actionJson) {
  try {
    final state = GameState.fromJson(_decode(stateJson));
    final action = GameAction.fromJson(_decode(actionJson));
    return jsonEncode({'failure': _engine.validateAction(state, action)?.name});
  } on FormatException catch (e) {
    return jsonEncode({'failure': 'invalidState', 'message': e.message});
  }
}

String _playable(String stateJson, String playerId) {
  try {
    final state = GameState.fromJson(_decode(stateJson));
    final isCurrent =
        state.status != GameStatus.finished &&
        state.currentPlayerId == playerId;
    return jsonEncode({
      'cards': [
        for (final c in _engine.getPlayableCards(state, playerId)) c.id,
      ],
      'canDraw': isCurrent && _engine.canDraw(state),
      'canPass': isCurrent && _engine.canPass(state),
      'mustTakePenalty': isCurrent && _engine.mustTakePenalty(state),
    });
  } on FormatException catch (e) {
    return jsonEncode({'failure': 'invalidState', 'message': e.message});
  }
}

@JS('gioco101CreateGame')
external set _createGameExport(JSFunction f);
@JS('gioco101ApplyAction')
external set _applyActionExport(JSFunction f);
@JS('gioco101Validate')
external set _validateExport(JSFunction f);
@JS('gioco101Playable')
external set _playableExport(JSFunction f);
@JS('gioco101EngineVersion')
external set _versionExport(JSFunction f);

void main() {
  _createGameExport = ((JSString p) => _createGame(p.toDart).toJS).toJS;
  _applyActionExport = ((JSString s, JSString a, JSNumber? now) => _applyAction(
    s.toDart,
    a.toDart,
    now?.toDartInt,
  ).toJS).toJS;
  _validateExport = ((JSString s, JSString a) => _validate(
    s.toDart,
    a.toDart,
  ).toJS).toJS;
  _playableExport = ((JSString s, JSString p) => _playable(
    s.toDart,
    p.toDart,
  ).toJS).toJS;
  _versionExport =
      (() => 'gioco101-engine/schema${GameState.schemaVersion}'.toJS).toJS;
}
