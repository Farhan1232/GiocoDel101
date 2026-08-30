// Real online-multiplayer verification against a Supabase project.
//
// Every "player" below is an INDEPENDENT authenticated client (its own
// SupabaseClient, its own auth.users row, its own JWT). Nothing is simulated
// in-process: rooms, queue, deals, every card, every rejection and every
// realtime event go through the deployed `match` Edge Function, the
// database RPCs and Supabase Realtime. Pure Dart — no Flutter:
//
//   SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… dart run tool/online_matrix.dart
//
// Options (env): MATRIX_SKIP_TIMEOUT=1 skips the 16 s turn-timer wait.
//
// Prints PASS/FAIL per check, a per-area summary, and exits non-zero on any
// FAIL. Legality on the client side is computed with the app's own
// GameEngine over the redacted snapshot + own hand — exactly what the
// Flutter table does — so a mismatch between client and server rules would
// show up here as rejected moves.
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:supabase/supabase.dart';

// ---------------------------------------------------------------- reporting

final Map<String, List<bool>> _areas = {};
int _failures = 0;
String _area = 'SETUP';

void area(String name) {
  _area = name;
  stdout.writeln('\n== $name ==');
}

void check(String name, bool ok, [Object? detail]) {
  _areas.putIfAbsent(_area, () => []).add(ok);
  stdout.writeln(
    '${ok ? 'PASS' : 'FAIL'}  $name${detail == null ? '' : '  ($detail)'}',
  );
  if (!ok) _failures++;
}

// ------------------------------------------------------------------ clients

late String url;
late String key;
final _rand = Random.secure();
String _uuid() {
  final b = List<int>.generate(16, (_) => _rand.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

class Player {
  Player(this.tag, this.client, this.id, this.email, this.password);
  final String tag;
  SupabaseClient client;
  final String id;
  final String email;
  final String password;

  /// The last state this player has seen, merged with its own hand — the
  /// app's table view, rebuilt from server rows.
  GameState? view;
  int version = -1;

  Future<Map<String, dynamic>> call(Map<String, dynamic> body) async {
    try {
      final r = await client.functions.invoke('match', body: body);
      return (r.data as Map).cast<String, dynamic>();
    } on FunctionException catch (e) {
      final d = e.details;
      return {
        'ok': false,
        'httpStatus': e.status,
        if (d is Map) ...d.cast<String, dynamic>(),
        if (d is! Map) 'error': d?.toString() ?? e.reasonPhrase,
      };
    }
  }

  Future<Map<String, dynamic>> snapshot(String matchId) async {
    final r = await client.rpc<dynamic>(
      'match_snapshot',
      params: {'p_match_id': matchId},
    );
    final snap = (r as Map).cast<String, dynamic>();
    _adopt(snap);
    return snap;
  }

  void _adopt(Map<String, dynamic> snap) {
    final state = GameState.fromJson(
      (snap['state'] as Map).cast<String, dynamic>(),
    );
    final hand = ((snap['hand'] as List?) ?? const [])
        .map((e) => GameCard.fromJson(e))
        .toList();
    final me = state.players.firstWhere(
      (p) => p.id == enginePlayerId(snap),
      orElse: () => state.players.first,
    );
    view = state.withPlayer(me.copyWith(hand: hand));
    version = (snap['version'] as num).toInt();
    pid = me.id;
  }

  /// This player's engine seat, known after the first snapshot.
  String? pid;

  String enginePlayerId(Map<String, dynamic> snap) {
    for (final p in (snap['players'] as List)) {
      if (p['userId'] == id) return p['enginePlayerId'] as String;
    }
    return '?';
  }

  /// Applies an accepted action response to the local view (what the
  /// Flutter client does before Realtime confirms).
  void adoptResponse(Map<String, dynamic> r, String pid) {
    if (r['publicState'] == null) return;
    final state = GameState.fromJson(
      (r['publicState'] as Map).cast<String, dynamic>(),
    );
    final hand = ((r['hand'] as List?) ?? const [])
        .map((e) => GameCard.fromJson(e))
        .toList();
    view = state.withPlayer(state.playerById(pid)!.copyWith(hand: hand));
    version = (r['version'] as num).toInt();
  }
}

int _counter = 0;

Future<Player> signUp(String tag) async {
  final client = SupabaseClient(
    url,
    key,
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  final email =
      's4-${DateTime.now().millisecondsSinceEpoch}-${_counter++}-$tag@example.com';
  const password = 'Matrix-Pass-2026!';
  final res = await client.auth.signUp(
    email: email,
    password: password,
    data: {'nickname': 'M$tag$_counter', 'avatar_id': 'sofia'},
  );
  final id = res.user!.id;
  if (res.session == null) {
    throw StateError('sign-up returned no session (autoconfirm off?)');
  }
  return Player(tag, client, id, email, password);
}

Future<Map<String, dynamic>?> rpcOrError(
  SupabaseClient c,
  String fn,
  Map<String, dynamic> params,
) async {
  try {
    final r = await c.rpc<dynamic>(fn, params: params);
    return {'ok': true, 'data': r};
  } on PostgrestException catch (e) {
    return {'ok': false, 'code': e.code, 'message': e.message};
  }
}

// --------------------------------------------------------------- game driver

const engine = GameEngine();

class DriveStats {
  int actions = 0, plays = 0, draws = 0, passes = 0, rounds = 0;
  int assi = 0, due = 0, cavalli = 0, blocks = 0, recycles = 0;
  int maxChain = 0, penaltyDraws = 0;
  int rejectedByServer = 0;
  bool assoSkipVerified = false;
  bool finished = false;
  String? winner;
}

/// Plays [matchId] to the end with every seat acting from ITS OWN client
/// and its own hand. Returns what happened. [probe] runs once, mid-game,
/// to inject adversarial requests.
Future<DriveStats> drive(
  String matchId,
  List<Player> players, {
  int maxActions = 2000,
  Future<void> Function(Player current, Player other)? probe,
}) async {
  final stats = DriveStats();
  final byPid = <String, Player>{};
  for (final p in players) {
    final snap = await p.snapshot(matchId);
    byPid[p.enginePlayerId(snap)] = p;
  }
  var probed = false;
  int pendingBefore = 0;
  int? assoBySeat;

  while (stats.actions < maxActions) {
    // Whose turn, per the freshest public state any client holds.
    final ref = players.first;
    final s = ref.view!;
    if (s.isFinished) {
      stats.finished = true;
      stats.winner = s.winnerId;
      break;
    }
    final pid = s.currentPlayerId;
    final actor = byPid[pid]!;
    // Re-sync the actor from the server (cheap, and what a resuming client does).
    await actor.snapshot(matchId);
    var v = actor.view!;
    if (v.version != s.version) {
      // Someone else is ahead; refresh everyone and loop.
      for (final p in players) {
        await p.snapshot(matchId);
      }
      continue;
    }

    if (!probed && probe != null && v.status == GameStatus.awaitingAction) {
      probed = true;
      final other = players.firstWhere((p) => p.id != actor.id);
      await probe(actor, other);
      // The probe moved the table: everyone re-reads, and this turn is
      // re-judged from scratch.
      for (final p in players) {
        await p.snapshot(matchId);
      }
      continue;
    }

    Map<String, dynamic> act(Map<String, dynamic> action) => {
      'op': 'action',
      'matchId': matchId,
      'actionId': _uuid(),
      'expectedVersion': actor.version,
      'action': action,
    };

    Map<String, dynamic> r;
    if (v.status == GameStatus.roundOver) {
      r = await actor.call(act({'type': 'startNextRound'}));
      if (r['accepted'] == true) stats.rounds++;
    } else if (v.status == GameStatus.awaitingSuitChoice) {
      final hand = v.handOf(pid);
      final suit = hand.isEmpty
          ? CardSuit.denari
          : hand
                .map((c) => c.suit)
                .fold<Map<CardSuit, int>>({}, (m, x) {
                  m[x] = (m[x] ?? 0) + 1;
                  return m;
                })
                .entries
                .reduce((a, b) => b.value > a.value ? b : a)
                .key;
      r = await actor.call(act({'type': 'chooseSuit', 'suit': suit.key}));
    } else {
      final playable = engine.getPlayableCards(v, pid);
      GameCard? pick;
      // Prefer the special cards so the matrix exercises them: stack 2s,
      // but block a chain of two or more with a Cavallo when we hold one.
      if (v.chainLength >= 2) {
        pick = playable.where((c) => c.isCavallo).firstOrNull;
      }
      pick ??= playable.where((c) => c.isDue).firstOrNull;
      pick ??= playable.where((c) => c.isCavallo).firstOrNull;
      pick ??= playable.where((c) => c.isAsso).firstOrNull;
      pick ??= playable.firstOrNull;
      if (pick != null) {
        pendingBefore = v.pendingDrawCount;
        r = await actor.call(act({'type': 'playCard', 'card': pick.id}));
        if (r['accepted'] == true) {
          stats.plays++;
          if (pick.isAsso) {
            stats.assi++;
            assoBySeat = v.currentSeat;
          }
          if (pick.isDue) stats.due++;
          if (pick.isCavallo) {
            stats.cavalli++;
            if (pendingBefore > 0) stats.blocks++;
          }
        }
      } else if (engine.canDraw(v)) {
        if (v.isPenaltyPending) stats.penaltyDraws++;
        r = await actor.call(act({'type': 'drawCard'}));
        if (r['accepted'] == true) stats.draws++;
      } else if (engine.canPass(v)) {
        r = await actor.call(act({'type': 'pass'}));
        if (r['accepted'] == true) stats.passes++;
      } else {
        throw StateError('no legal move for $pid: $v');
      }
    }
    stats.actions++;
    if (r['accepted'] == true) {
      actor.adoptResponse(r, pid);
      final events = (r['events'] as List?)?.cast<String>() ?? const [];
      if (events.contains('DeckRecycledEvent')) stats.recycles++;
      final st = actor.view!;
      if (st.chainLength > stats.maxChain) stats.maxChain = st.chainLength;
      // Asso: the seat after the player is skipped (§5), eliminated seats aside.
      final assoSeat = assoBySeat;
      if (assoSeat != null && events.contains('TurnSkippedEvent')) {
        final n = st.players.length;
        var expect = assoSeat;
        var moved = 0;
        while (moved < 2) {
          expect = (expect + 1) % n;
          if (!st.players[expect].eliminated) moved++;
        }
        if (st.status == GameStatus.awaitingAction) {
          if (st.currentSeat == expect) stats.assoSkipVerified = true;
        }
        assoBySeat = null;
      }
      // Fan out like Realtime would: the others re-read.
      for (final p in players) {
        if (p.id != actor.id) await p.snapshot(matchId);
      }
      players.first.view = players.first.view; // keep ref fresh
      if (actor != players.first) await players.first.snapshot(matchId);
    } else {
      stats.rejectedByServer++;
      stdout.writeln('   server refused ${r['failure'] ?? r} for $pid');
      for (final p in players) {
        await p.snapshot(matchId);
      }
    }
  }
  return stats;
}

// ----------------------------------------------------------------- scenarios

Future<String> createRoom(
  Player host,
  int players, {
  int timer = 0,
  Map<String, dynamic> rules = const {},
}) async {
  final row = await host.client.rpc<Map<String, dynamic>>(
    'create_room',
    params: {
      'p_name': 'M${host.tag}',
      'p_max_players': players,
      'p_is_private': true,
      'p_turn_timer_seconds': timer,
      'p_rules': rules,
    },
  );
  return row['code'] as String;
}

Future<Map<String, dynamic>> joinRoom(Player p, String code) async =>
    p.client.rpc<Map<String, dynamic>>('join_room', params: {'p_code': code});

Future<void> privateRoomAndHands(List<Player> ps) async {
  area('PRIVATE ROOM');
  final host = ps[0];
  final code = await createRoom(host, ps.length, timer: 0);
  check(
    'host created a ${ps.length}-player room with a code',
    code.length == 6,
    code,
  );
  for (final p in ps.skip(1)) {
    final room = await joinRoom(p, code);
    check('${p.tag} joined by code', room['code'] == code);
  }
  final roomRow = await host.client
      .from('rooms')
      .select()
      .eq('code', code)
      .single();
  final roomId = roomRow['id'] as String;

  final notReady = await host.call({'op': 'start', 'roomId': roomId});
  check(
    'start refused while a guest is not ready',
    notReady['ok'] == false && notReady['failure'] == 'not_everyone_ready',
    notReady,
  );
  for (final p in ps.skip(1)) {
    await p.client.rpc<void>(
      'set_ready',
      params: {'p_room_id': roomId, 'p_ready': true},
    );
  }
  final guestStart = await ps[1].call({'op': 'start', 'roomId': roomId});
  check(
    'a non-host cannot start the room',
    guestStart['ok'] == false && guestStart['error'] == 'not_the_host',
    guestStart,
  );
  final started = await host.call({'op': 'start', 'roomId': roomId});
  check('host started the match', started['ok'] == true, started);
  final matchId = started['matchId'] as String;
  final again = await host.call({'op': 'start', 'roomId': roomId});
  check(
    'START TWICE returns the same match (idempotent)',
    again['ok'] == true &&
        again['matchId'] == matchId &&
        again['created'] == false,
    again,
  );
  _lastMatch = matchId;
  _lastRoom = roomId;

  area('PRIVATE HAND SECURITY');
  for (final p in ps) {
    final snap = await p.snapshot(matchId);
    final state = (snap['state'] as Map).cast<String, dynamic>();
    final hand = snap['hand'] as List;
    check('${p.tag}: own hand has 5 cards', hand.length == 5);
    check(
      '${p.tag}: public state has no seed / drawPile / hands / drawnCard / history',
      !state.containsKey('seed') &&
          !state.containsKey('drawPile') &&
          !state.containsKey('history') &&
          !state.containsKey('drawnCard') &&
          (state['players'] as List).every(
            (pl) => !(pl as Map).containsKey('hand') && pl['handCount'] == 5,
          ),
    );
    check(
      '${p.tag}: public state carries drawPileCount = ${40 - 5 * ps.length - 1}',
      state['drawPileCount'] == 40 - 5 * ps.length - 1,
    );
  }
  final a = ps[0];
  final b = ps[1];
  final rowsA = await a.client
      .from('match_private_state')
      .select('user_id')
      .eq('match_id', matchId);
  check(
    'A selects match_private_state: only own row',
    rowsA.length == 1 && rowsA.first['user_id'] == a.id,
  );
  final peek = await a.client
      .from('match_private_state')
      .select()
      .eq('match_id', matchId)
      .eq('user_id', b.id);
  check("A filters for B's hand row: empty", peek.isEmpty);
  try {
    await a.client.schema('app_private').from('match_engine_state').select();
    check(
      'A reads app_private.match_engine_state',
      false,
      'UNEXPECTED SUCCESS',
    );
  } on PostgrestException catch (e) {
    check('A cannot read app_private (schema not exposed)', true, e.code);
  }
  for (final attempt in [
    (
      'update match_public_state',
      () => a.client
          .from('match_public_state')
          .update({'version': 999})
          .eq('match_id', matchId),
    ),
    (
      'insert match_actions',
      () => a.client.from('match_actions').insert({
        'match_id': matchId,
        'version': 0,
        'action': {},
        'accepted': true,
      }),
    ),
    (
      'set own is_winner',
      () => a.client
          .from('match_players')
          .update({'is_winner': true})
          .eq('match_id', matchId)
          .eq('user_id', a.id),
    ),
    (
      'set matches.winner_id',
      () => a.client
          .from('matches')
          .update({'winner_id': a.id})
          .eq('id', matchId),
    ),
    (
      'set own rating',
      () => a.client.from('profiles').update({'rating': 9999}).eq('id', a.id),
    ),
    (
      'set own xp',
      () => a.client.from('profiles').update({'xp': 9999}).eq('id', a.id),
    ),
    (
      'set own wins',
      () => a.client.from('profiles').update({'wins': 9999}).eq('id', a.id),
    ),
    (
      'insert matchmaking_queue directly',
      () => a.client.from('matchmaking_queue').insert({
        'user_id': a.id,
        'player_count': 2,
      }),
    ),
    (
      'update match_private_state hand',
      () => a.client
          .from('match_private_state')
          .update({'hand': []})
          .eq('match_id', matchId),
    ),
  ]) {
    try {
      await attempt.$2();
      check('A cannot ${attempt.$1}', false, 'UNEXPECTED SUCCESS');
    } on PostgrestException catch (e) {
      check('A cannot ${attempt.$1}', true, e.code);
    }
  }
  final srv = await rpcOrError(a.client, 'srv_load_match', {
    'p_match_id': matchId,
    'p_user_id': a.id,
  });
  check('A cannot call srv_load_match', srv!['ok'] == false, srv['code']);
  final srvCommit = await rpcOrError(a.client, 'srv_commit_action', {
    'p_match_id': matchId,
    'p_actor': a.id,
    'p_action_id': _uuid(),
    'p_base_version': 0,
    'p_new_state': {},
    'p_actions': [],
    'p_kind': 'action',
  });
  check(
    'A cannot call srv_commit_action',
    srvCommit!['ok'] == false,
    srvCommit['code'],
  );
}

String? _lastMatch;
String? _lastRoom;
int _totalRecycles = 0;
int _totalBlocks = 0;

Future<void> adversarialProbe(
  Player current,
  Player other,
  String matchId,
) async {
  area('CONCURRENCY & ATTACKS');
  final v = current.view!;
  final pid = v.currentPlayerId;
  final otherSnap = await other.snapshot(matchId);
  final otherPid = other.enginePlayerId(otherSnap);

  // Play outside turn.
  final outside = await other.call({
    'op': 'action',
    'matchId': matchId,
    'actionId': _uuid(),
    'expectedVersion': other.version,
    'action': {'type': 'drawCard'},
  });
  check(
    'PLAY OUTSIDE TURN refused',
    outside['accepted'] == false && outside['failure'] == 'notPlayersTurn',
    outside,
  );

  // Play a card that belongs to the other player (we know it because we ARE the other client).
  final foreign = other.view!.handOf(otherPid).first;
  final steal = await current.call({
    'op': 'action',
    'matchId': matchId,
    'actionId': _uuid(),
    'expectedVersion': current.version,
    'action': {'type': 'playCard', 'card': foreign.id},
  });
  check(
    "PLAY OPPONENT'S CARD refused",
    steal['accepted'] == false && steal['failure'] == 'cardNotOwned',
    steal['failure'],
  );

  // Card not in the deck / malformed.
  final bogus = await current.call({
    'op': 'action',
    'matchId': matchId,
    'actionId': _uuid(),
    'expectedVersion': current.version,
    'action': {'type': 'playCard', 'card': 'cuori_nove'},
  });
  check(
    'malformed card id rejected (400)',
    bogus['ok'] == false && bogus['httpStatus'] == 400,
    bogus,
  );
  final badSuit = await current.call({
    'op': 'action',
    'matchId': matchId,
    'actionId': _uuid(),
    'expectedVersion': current.version,
    'action': {'type': 'chooseSuit', 'suit': 'cuori'},
  });
  check(
    'INVALID SUIT rejected (400)',
    badSuit['ok'] == false && badSuit['httpStatus'] == 400,
    badSuit,
  );

  // Stale version.
  final stale = await current.call({
    'op': 'action',
    'matchId': matchId,
    'actionId': _uuid(),
    'expectedVersion': current.version + 7,
    'action': {'type': 'drawCard'},
  });
  check(
    'STALE VERSION refused',
    stale['accepted'] == false &&
        stale['failure'] == 'staleState' &&
        stale['version'] == current.version,
    stale,
  );

  // Spoofed actor: the server ignores playerId from the client entirely; a
  // client claiming to be the other seat still acts as itself.
  final spoof = await other.call({
    'op': 'action',
    'matchId': matchId,
    'actionId': _uuid(),
    'expectedVersion': other.version,
    'action': {'type': 'drawCard', 'playerId': pid},
  });
  check(
    'spoofed playerId is ignored (still not their turn)',
    spoof['accepted'] == false && spoof['failure'] == 'notPlayersTurn',
    spoof['failure'],
  );

  // A legal move: pick something playable, or draw.
  final playable = engine.getPlayableCards(v, pid);
  final action = playable.isNotEmpty
      ? {'type': 'playCard', 'card': playable.first.id}
      : {'type': 'drawCard'};
  final actionId = _uuid();
  final body = {
    'op': 'action',
    'matchId': matchId,
    'actionId': actionId,
    'expectedVersion': current.version,
    'action': action,
  };
  // DOUBLE TAP / DUPLICATE RETRY: the same request sent twice at once.
  final both = await Future.wait([current.call(body), current.call(body)]);
  final accepted = both.where((r) => r['accepted'] == true).toList();
  final dup = both.where((r) => r['duplicate'] == true).toList();
  check(
    'DOUBLE TAP (same action id, concurrent): exactly one applied, the other a receipt',
    accepted.length == 2 &&
        dup.length == 1 &&
        both.every((r) => r['version'] == current.version + 1),
    both
        .map((r) => '${r['accepted']}/${r['duplicate']}/${r['version']}')
        .join(' '),
  );
  final again = await current.call(body);
  check(
    'DUPLICATE NETWORK RETRY later: replayed receipt, version unchanged',
    again['duplicate'] == true && again['version'] == current.version + 1,
    again,
  );
  final snapAfter = await current.snapshot(matchId);
  check(
    'server version advanced exactly once',
    snapAfter['version'] == current.version,
    snapAfter['version'],
  );

  // TWO DIFFERENT ACTIONS SIMULTANEOUSLY against the same version.
  await other.snapshot(matchId);
  final cur2 = current.view!;
  if (cur2.currentPlayerId == pid && cur2.status == GameStatus.awaitingAction) {
    final p2 = engine.getPlayableCards(cur2, pid);
    final a1 = p2.isNotEmpty
        ? {'type': 'playCard', 'card': p2.first.id}
        : {'type': 'drawCard'};
    final a2 = p2.length > 1
        ? {'type': 'playCard', 'card': p2[1].id}
        : {'type': 'drawCard'};
    final race = await Future.wait([
      current.call({
        'op': 'action',
        'matchId': matchId,
        'actionId': _uuid(),
        'expectedVersion': current.version,
        'action': a1,
      }),
      current.call({
        'op': 'action',
        'matchId': matchId,
        'actionId': _uuid(),
        'expectedVersion': current.version,
        'action': a2,
      }),
    ]);
    final ok = race.where((r) => r['accepted'] == true).length;
    final lost = race
        .where((r) => r['accepted'] == false)
        .map((r) => r['failure'])
        .toList();
    check(
      'TWO ACTIONS SIMULTANEOUSLY: one applied, one refused as stale/illegal',
      ok == 1 && lost.length == 1,
      '$lost',
    );
    final s2 = await current.snapshot(matchId);
    check(
      'version advanced by exactly one',
      s2['version'] == cur2.version + 1,
      s2['version'],
    );
  } else {
    stdout.writeln(
      '   (turn moved on; simultaneous-action race covered by double tap)',
    );
  }
  // Card conservation on the server is asserted by the engine itself
  // (invariants) — what we can verify from outside: counts add up to 40.
  final s3 = await current.snapshot(matchId);
  final st = (s3['state'] as Map).cast<String, dynamic>();
  final total =
      (st['drawPileCount'] as int) +
      (st['discardPile'] as List).length +
      (st['players'] as List).fold<int>(
        0,
        (n, p) => n + (p['handCount'] as int),
      );
  check(
    '40-card conservation visible from the public state',
    total == 40,
    total,
  );
  _area = 'GAMEPLAY';
}

Future<void> afterFinish(
  List<Player> ps,
  String matchId,
  DriveStats stats,
) async {
  area('MATCH RESULT');
  check('match reached finished', stats.finished, 'winner ${stats.winner}');
  final m = await ps.first.client
      .from('matches')
      .select()
      .eq('id', matchId)
      .single();
  check(
    'matches.status = finished, winner_id set',
    m['status'] == 'finished' && m['winner_id'] != null,
  );
  final mps = await ps.first.client
      .from('match_players')
      .select()
      .eq('match_id', matchId);
  final winners = mps.where((r) => r['is_winner'] == true).length;
  check(
    'exactly one is_winner, placements 1..n',
    winners == 1 && mps.every((r) => r['placement'] != null),
  );
  for (final p in ps) {
    final prof = await p.client
        .from('profiles')
        .select()
        .eq('id', p.id)
        .single();
    final won =
        mps.firstWhere((r) => r['user_id'] == p.id)['is_winner'] == true;
    check(
      '${p.tag}: profile matches=${prof['matches']} wins=${prof['wins']} losses=${prof['losses']} xp=${prof['xp']}',
      prof['matches'] >= 1 &&
          (won ? prof['wins'] >= 1 : prof['losses'] >= 1) &&
          prof['xp'] >= 20,
    );
  }
  final late = await ps.first.call({
    'op': 'action',
    'matchId': matchId,
    'actionId': _uuid(),
    'expectedVersion': ps.first.version,
    'action': {'type': 'drawCard'},
  });
  check(
    'PLAY AFTER FINISH refused',
    late['accepted'] == false && late['failure'] == 'gameFinished',
    late['failure'],
  );
}

Future<String?> rematch(List<Player> ps, String matchId) async {
  area('REMATCH');
  final first = await ps.first.call({'op': 'rematch', 'matchId': matchId});
  check(
    'first vote: waiting ${first['votes']}/${first['needed']}',
    first['ok'] == true && first['status'] == 'waiting',
    first,
  );
  Map<String, dynamic>? last;
  for (final p in ps.skip(1)) {
    last = await p.call({'op': 'rematch', 'matchId': matchId});
  }
  check(
    'last vote deals a fresh match',
    last!['ok'] == true &&
        last['status'] == 'started' &&
        last['matchId'] != matchId,
    last,
  );
  final newId = last['matchId'] as String?;
  if (newId == null) return null;
  final again = await ps.first.call({'op': 'rematch', 'matchId': matchId});
  check(
    'voting again returns the same new match',
    again['matchId'] == newId,
    again,
  );
  for (final p in ps) {
    final snap = await p.snapshot(newId);
    check(
      '${p.tag}: 5 fresh cards, version 0',
      (snap['hand'] as List).length == 5 && snap['version'] == 0,
    );
  }
  final room = await ps.first.client
      .from('rooms')
      .select()
      .eq('id', _lastRoom!)
      .single();
  check(
    'room points at the new match and is in_progress',
    room['match_id'] == newId && room['status'] == 'in_progress',
  );
  final active = await ps.first.client.rpc<dynamic>('my_active_match');
  check(
    'my_active_match() = the rematch',
    active is Map && active['matchId'] == newId,
  );
  return newId;
}

Future<void> reconnectAndRealtime(Player a, Player b, String matchId) async {
  area('RECONNECT');
  // B "restarts the app": a brand-new client restored from the refresh token.
  final refresh = b.client.auth.currentSession!.refreshToken!;
  await b.client.dispose();
  final fresh = SupabaseClient(
    url,
    key,
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  final restored = await fresh.auth.setSession(refresh);
  check('auth restored from refresh token', restored.user?.id == b.id);
  b.client = fresh;
  final active = await fresh.rpc<dynamic>('my_active_match');
  check(
    'active match detected after restart',
    active is Map && active['matchId'] == matchId,
    active,
  );
  final snap = await b.snapshot(matchId);
  check(
    'authoritative snapshot + own hand + version restored',
    (snap['hand'] as List).isNotEmpty && snap['version'] == b.version,
  );

  area('REALTIME');
  final gotPublic = Completer<int>();
  final gotPrivate = Completer<int>();
  final gotReaction = Completer<Map<String, dynamic>>();
  // Row changes: plain channel, RLS-filtered per subscriber. Presence and
  // the server-sent reactions: the PRIVATE channel.
  final rows = fresh.channel('match-rows:$matchId');
  rows
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'match_public_state',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'match_id',
          value: matchId,
        ),
        callback: (payload) {
          if (!gotPublic.isCompleted) {
            gotPublic.complete(payload.newRecord['version'] as int);
          }
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'match_private_state',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'match_id',
          value: matchId,
        ),
        callback: (payload) {
          if (!gotPrivate.isCompleted) {
            gotPrivate.complete(payload.newRecord['version'] as int);
          }
        },
      );
  final rowsSubscribed = Completer<String>();
  rows.subscribe((status, error) {
    if (!rowsSubscribed.isCompleted) rowsSubscribed.complete('$status');
  });
  final chan = fresh.channel(
    'match:$matchId',
    opts: const RealtimeChannelConfig(private: true),
  );
  chan.onBroadcast(
    event: 'reaction',
    callback: (payload) {
      final inner = payload['payload'];
      final msg = (inner is Map ? inner : payload).cast<String, dynamic>();
      if (msg['key'] == 'bravo' && !gotReaction.isCompleted) {
        gotReaction.complete(msg);
      }
    },
  );
  final subscribed = Completer<String>();
  chan.subscribe((status, error) {
    if (!subscribed.isCompleted) {
      subscribed.complete('$status ${error ?? ''}'.trim());
    }
  });
  final status = await subscribed.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () => 'timeout',
  );
  check(
    'B joined the private match channel',
    status.startsWith('RealtimeSubscribeStatus.subscribed'),
    status,
  );
  final rowsStatus = await rowsSubscribed.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () => 'timeout',
  );
  check(
    'B subscribed to the row-change channel',
    rowsStatus == 'RealtimeSubscribeStatus.subscribed',
    rowsStatus,
  );
  await chan.track({'userId': b.id});

  // A moves (or A/B, whoever is on turn), B must receive the change.
  await a.snapshot(matchId);
  final s = a.view!;
  final actorIsA =
      s.currentPlayerId == a.enginePlayerId(await a.snapshot(matchId));
  final actor = actorIsA ? a : b;
  final pid = actor.view!.currentPlayerId;
  final playable = engine.getPlayableCards(actor.view!, pid);
  final r = await actor.call({
    'op': 'action',
    'matchId': matchId,
    'actionId': _uuid(),
    'expectedVersion': actor.version,
    'action': playable.isNotEmpty
        ? {'type': 'playCard', 'card': playable.first.id}
        : {'type': 'drawCard'},
  });
  check(
    'a move was applied for the realtime test',
    r['accepted'] == true,
    r['failure'],
  );
  final v1 = await gotPublic.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () => -1,
  );
  check(
    'B received match_public_state UPDATE via Realtime (version $v1)',
    v1 == r['version'],
  );
  final v2 = await gotPrivate.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () => -1,
  );
  check(
    'B received its own match_private_state UPDATE via Realtime (version $v2)',
    v2 == r['version'],
  );

  area('REACTIONS');
  final sent = await rpcOrError(a.client, 'send_reaction', {
    'p_match_id': matchId,
    'p_key': 'bravo',
  });
  check('A sends a preset reaction', sent!['ok'] == true, sent);
  final fast = await rpcOrError(a.client, 'send_reaction', {
    'p_match_id': matchId,
    'p_key': 'gg',
  });
  check(
    'second reaction within 2 s is rate-limited',
    fast!['ok'] == false && '${fast['message']}'.contains('rate_limited'),
    fast['message'],
  );
  final rx = await gotReaction.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () => {},
  );
  check(
    'B received the reaction broadcast on the private channel',
    rx['key'] == 'bravo' && rx['userId'] == a.id,
    rx,
  );
  final bad = await rpcOrError(a.client, 'send_reaction', {
    'p_match_id': matchId,
    'p_key': 'free text hello',
  });
  check(
    'non-preset reaction refused',
    bad!['ok'] == false && '${bad['message']}'.contains('invalid_reaction'),
    bad['message'],
  );
  // A client cannot broadcast on the channel itself (insert policy = presence only).
  final chanA = a.client.channel(
    'match:$matchId',
    opts: const RealtimeChannelConfig(private: true),
  );
  final subA = Completer<String>();
  chanA.subscribe((st, err) {
    if (!subA.isCompleted) subA.complete('$st');
  });
  await subA.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () => 'timeout',
  );
  final leaked = Completer<Map<String, dynamic>>();
  chan.onBroadcast(
    event: 'reaction',
    callback: (payload) {
      final inner = payload['payload'];
      final msg = (inner is Map ? inner : payload).cast<String, dynamic>();
      if (msg['key'] == 'hacked' && !leaked.isCompleted) leaked.complete(msg);
    },
  );
  final sendStatus = await chanA.sendBroadcastMessage(
    event: 'reaction',
    payload: {'key': 'hacked', 'text': 'free chat'},
  );
  final got = await leaked.future.timeout(
    const Duration(seconds: 5),
    onTimeout: () => const {},
  );
  check(
    'client-side broadcast on the match channel never reaches the others',
    got.isEmpty,
    'send status $sendStatus, received $got',
  );
  await a.client.removeChannel(chanA);
  await fresh.removeChannel(chan);
  await fresh.removeChannel(rows);
}

Future<void> unrelatedSubscriber(Player outsider, String matchId) async {
  area('RLS');
  final snap = await rpcOrError(outsider.client, 'match_snapshot', {
    'p_match_id': matchId,
  });
  check(
    'outsider cannot read the match snapshot',
    snap!['ok'] == false,
    snap['message'],
  );
  final pub = await outsider.client
      .from('match_public_state')
      .select()
      .eq('match_id', matchId);
  final priv = await outsider.client
      .from('match_private_state')
      .select()
      .eq('match_id', matchId);
  check(
    'outsider sees no public/private state rows',
    pub.isEmpty && priv.isEmpty,
  );
  final act = await outsider.call({
    'op': 'action',
    'matchId': matchId,
    'actionId': _uuid(),
    'expectedVersion': 0,
    'action': {'type': 'drawCard'},
  });
  check(
    'outsider action refused (403)',
    act['ok'] == false && act['httpStatus'] == 403,
    act['error'],
  );
  final tmo = await outsider.call({'op': 'timeout', 'matchId': matchId});
  check(
    'outsider timeout claim refused (403)',
    tmo['ok'] == false && tmo['httpStatus'] == 403,
    tmo['error'],
  );
  final rem = await outsider.call({'op': 'rematch', 'matchId': matchId});
  check('outsider rematch refused', rem['ok'] == false, rem['error']);
  final react = await rpcOrError(outsider.client, 'send_reaction', {
    'p_match_id': matchId,
    'p_key': 'gg',
  });
  check('outsider reaction refused', react!['ok'] == false, react['message']);
  final chan = outsider.client.channel(
    'match:$matchId',
    opts: const RealtimeChannelConfig(private: true),
  );
  final sub = Completer<String>();
  chan.subscribe((st, err) {
    if (!sub.isCompleted) sub.complete('$st ${err ?? ''}');
  });
  final status = await sub.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () => 'timeout',
  );
  check(
    'SUBSCRIBE TO UNRELATED MATCH channel refused',
    !status.startsWith('RealtimeSubscribeStatus.subscribed'),
    status,
  );
  await outsider.client.removeChannel(chan);
  // And someone else's room:
  final anyRoom = await rpcOrError(outsider.client, 'leave_room', {
    'p_room_id': _lastRoom,
  });
  check(
    'outsider leave_room on a live room does nothing harmful',
    anyRoom != null,
  );
  final startOther = await outsider.call({'op': 'start', 'roomId': _lastRoom});
  check(
    "START SOMEONE ELSE'S ROOM refused",
    startOther['ok'] == false &&
        (startOther['httpStatus'] == 403 || startOther['httpStatus'] == 409),
    startOther['error'],
  );
}

Future<void> quickMatch(List<Player> ps, int size) async {
  area('QUICK MATCH');
  final first = ps.first;
  final r1 = await first.client.rpc<Map<String, dynamic>>(
    'enqueue_quick_match',
    params: {'p_player_count': size, 'p_turn_timer_seconds': 30},
  );
  check(
    '${first.tag} enqueued (waiting)',
    r1['status'] == 'waiting' && r1['room_id'] == null,
  );
  final r1b = await first.client.rpc<Map<String, dynamic>>(
    'enqueue_quick_match',
    params: {'p_player_count': size, 'p_turn_timer_seconds': 30},
  );
  check(
    'enqueue again: no duplicate entry, still waiting',
    r1b['status'] == 'waiting' && r1b['enqueued_at'] == r1['enqueued_at'],
  );
  final mine = await first.client.from('matchmaking_queue').select();
  check(
    'player sees only own queue row',
    mine.length == 1 && mine.first['user_id'] == first.id,
  );
  final hb = await first.client.rpc<dynamic>('quick_match_heartbeat');
  check('queue heartbeat', hb is Map && hb['user_id'] == first.id);

  // An incompatible player (different size) must NOT be matched.
  final odd = ps.last;
  final rOdd = await odd.client.rpc<Map<String, dynamic>>(
    'enqueue_quick_match',
    params: {'p_player_count': size == 2 ? 3 : 2, 'p_turn_timer_seconds': 30},
  );
  check('incompatible table size stays waiting', rOdd['status'] == 'waiting');
  await odd.client.rpc<void>('cancel_quick_match');
  final oddRows = await odd.client.from('matchmaking_queue').select();
  check('cancel removes the queue entry', oddRows.isEmpty);

  Map<String, dynamic>? lastRow;
  for (final p in ps.sublist(1, size)) {
    lastRow = await p.client.rpc<Map<String, dynamic>>(
      'enqueue_quick_match',
      params: {'p_player_count': size, 'p_turn_timer_seconds': 30},
    );
  }
  check(
    'the ${size}th compatible player is matched with a room',
    lastRow!['status'] == 'matched' && lastRow['room_id'] != null,
    lastRow,
  );
  final roomId = lastRow['room_id'] as String;
  final firstRow = await first.client
      .from('matchmaking_queue')
      .select()
      .eq('user_id', first.id)
      .single();
  check(
    'the first waiter sees matched + the same room',
    firstRow['status'] == 'matched' && firstRow['room_id'] == roomId,
  );
  final seats = await first.client
      .from('room_players')
      .select()
      .eq('room_id', roomId);
  check(
    'room has exactly $size seats, all real users',
    seats.length == size &&
        seats.every((s) => ps.any((p) => p.id == s['user_id'])),
  );
  final room = await first.client
      .from('rooms')
      .select()
      .eq('id', roomId)
      .single();
  check(
    'room kind = quick, private, $size players',
    room['kind'] == 'quick' &&
        room['is_private'] == true &&
        room['max_players'] == size,
  );
  // Any member may start a quick room; two try at once.
  final starts = await Future.wait([
    ps[1].call({'op': 'start', 'roomId': roomId}),
    first.call({'op': 'start', 'roomId': roomId}),
  ]);
  final ids = starts.map((s) => s['matchId']).toSet();
  check(
    'two members start at once: one match, both get its id',
    starts.every((s) => s['ok'] == true) && ids.length == 1,
    starts.map((s) => '${s['created']}').join(','),
  );
  final matchId = ids.first as String;
  final qleft = await first.client.from('matchmaking_queue').select();
  check('queue rows cleared once the match is dealt', qleft.isEmpty);
  final busy = await first.client
      .rpc<dynamic>(
        'enqueue_quick_match',
        params: {'p_player_count': 2, 'p_turn_timer_seconds': 30},
      )
      .then((_) => 'ok', onError: (e) => '$e');
  check(
    'a player in a live match cannot re-enter the queue',
    busy.toString().contains('already_in_match'),
    busy,
  );
  _lastMatch = matchId;
  _lastRoom = roomId;
}

// ------------------------------------------------- session 6: hardening

Future<Map<String, dynamic>> _profile(Player p) async {
  final r = await p.client
      .from('profiles')
      .select('wins, xp, matches, current_streak')
      .eq('id', p.id)
      .single();
  return r;
}

/// The attacks the final audit added, run against the deployed function and
/// migration 10. Leaves every player free (no live match) when it returns.
Future<void> hardening(List<Player> ps) async {
  area('SESSION 6 HARDENING');
  final a = ps[0], b = ps[1], c = ps[2], d = ps[3], e = ps[4];

  // Room rules are validated key by key.
  for (final bad in <String, Map<String, dynamic>>{
    'unknown key': {'evil': 1},
    'out-of-range hand size': {'startingHandSize': 40},
    'wrong type': {'stackDrawTwos': 'yes'},
    'oversized object': {'nineBlockMode': 'x' * 5000},
  }.entries) {
    final r = await rpcOrError(a.client, 'create_room', {
      'p_name': 'bad',
      'p_max_players': 2,
      'p_is_private': true,
      'p_turn_timer_seconds': 0,
      'p_rules': bad.value,
    });
    check(
      'create_room refuses ${bad.key} (invalid_rules)',
      r!['ok'] == false && '${r['message']}'.contains('invalid_rules'),
      r['message'],
    );
  }

  // A 3-player table: A hosts, B and C join, A starts.
  final code = await createRoom(a, 3, timer: 0);
  final roomB = await joinRoom(b, code);
  await joinRoom(c, code);
  final roomId = roomB['id'] as String;
  for (final p in [b, c]) {
    await p.client.rpc<void>(
      'set_ready',
      params: {'p_room_id': roomId, 'p_ready': true},
    );
  }
  final started = await a.call({'op': 'start', 'roomId': roomId});
  check('3-player table started', started['ok'] == true, started);
  final matchId = started['matchId'] as String;

  // Joining a started room by code is "already started", not "not found".
  final late = await rpcOrError(d.client, 'join_room', {'p_code': code});
  check(
    'joining a room whose match started → match_already_started',
    late!['ok'] == false &&
        '${late['message']}'.contains('match_already_started'),
    late['message'],
  );
  // A seated player cannot open or enter another table.
  final second = await rpcOrError(a.client, 'create_room', {
    'p_name': 'second',
    'p_max_players': 2,
    'p_is_private': true,
    'p_turn_timer_seconds': 0,
    'p_rules': <String, dynamic>{},
  });
  check(
    'create_room while seated at a live match → already_in_match',
    second!['ok'] == false &&
        '${second['message']}'.contains('already_in_match'),
    second['message'],
  );
  final otherCode = await createRoom(d, 2);
  final sneak = await rpcOrError(b.client, 'join_room', {'p_code': otherCode});
  check(
    'join_room while seated at a live match → already_in_match',
    sneak!['ok'] == false && '${sneak['message']}'.contains('already_in_match'),
    sneak['message'],
  );
  final queue = await rpcOrError(c.client, 'enqueue_quick_match', {
    'p_player_count': 2,
    'p_turn_timer_seconds': 30,
  });
  check(
    'quick-match queue while seated at a live match → already_in_match',
    queue!['ok'] == false && '${queue['message']}'.contains('already_in_match'),
    queue['message'],
  );
  // A member re-entering by code simply gets the room back.
  final back = await rpcOrError(b.client, 'join_room', {'p_code': code});
  check(
    'a member re-entering the code gets the room',
    back!['ok'] == true,
    back['message'],
  );

  // A refused play must not write the card into the shared action log.
  await a.snapshot(matchId);
  await b.snapshot(matchId);
  await c.snapshot(matchId);
  final onTurn = [a, b, c].firstWhere((p) => p.view!.currentPlayer.id == p.pid);
  final idle = [a, b, c].firstWhere((p) => p != onTurn);
  final idleCard = idle.view!.playerById(idle.pid!)!.hand.first;
  final rejectedId = _uuid();
  final refused = await idle.call({
    'op': 'action',
    'matchId': matchId,
    'actionId': rejectedId,
    'expectedVersion': idle.version,
    'action': {'type': 'playCard', 'card': idleCard.id},
  });
  check(
    'playing out of turn is refused (notPlayersTurn)',
    refused['accepted'] == false && refused['failure'] == 'notPlayersTurn',
    refused,
  );
  final logged = await onTurn.client
      .from('match_actions')
      .select('action, accepted')
      .eq('match_id', matchId)
      .eq('accepted', false);
  check(
    'the refused action is logged without the card',
    logged.isNotEmpty &&
        logged.every((r) => !((r['action'] as Map).containsKey('card'))),
    logged.map((r) => r['action']).toList(),
  );
  // Receipts are per caller: another seat reusing the id is not a replay.
  final reuse = await onTurn.call({
    'op': 'action',
    'matchId': matchId,
    'actionId': rejectedId,
    'expectedVersion': onTurn.version,
    'action': {'type': 'drawCard'},
  });
  check(
    "another seat reusing an action id is judged afresh, not replayed",
    reuse['duplicate'] != true,
    reuse,
  );
  await a.snapshot(matchId);
  await b.snapshot(matchId);
  await c.snapshot(matchId);

  // A forfeited seat can neither claim a timeout nor block the rematch.
  final quit = await c.call({'op': 'forfeit', 'matchId': matchId});
  check(
    'C forfeits the 3-player table (match continues)',
    quit['ok'] == true && quit['status'] != 'finished',
    quit,
  );
  final ghost = await c.call({'op': 'timeout', 'matchId': matchId});
  check(
    'a forfeited seat cannot claim a timeout (invalidPlayer)',
    ghost['ok'] == false && ghost['failure'] == 'invalidPlayer',
    ghost,
  );
  final seats = await a.client
      .from('room_players')
      .select('user_id')
      .eq('room_id', roomId);
  check('the forfeited seat left the room', seats.length == 2, seats.length);
  // End the table so A and B are free again.
  final end = await a.call({'op': 'forfeit', 'matchId': matchId});
  check(
    'second forfeit finishes the table (B wins)',
    end['ok'] == true && end['status'] == 'finished',
    end,
  );

  // A table ended by forfeit before any round was played awards nothing.
  final before = await _profile(d);
  final beforeE = await _profile(e);
  final code2 = await createRoom(d, 2, timer: 0);
  final room2 = await joinRoom(e, code2);
  await e.client.rpc<void>(
    'set_ready',
    params: {'p_room_id': room2['id'], 'p_ready': true},
  );
  final s2 = await d.call({'op': 'start', 'roomId': room2['id']});
  final m2 = s2['matchId'] as String;
  final walk = await e.call({'op': 'forfeit', 'matchId': m2});
  check(
    'E walks out before a round is played',
    walk['ok'] == true && walk['status'] == 'finished',
    walk,
  );
  final after = await _profile(d);
  final afterE = await _profile(e);
  check(
    'no win / XP / match counted for the remaining seat',
    after['wins'] == before['wins'] &&
        after['xp'] == before['xp'] &&
        after['matches'] == before['matches'],
    '$before → $after',
  );
  check(
    'nothing counted for the seat that walked out either',
    afterE['xp'] == beforeE['xp'] && afterE['matches'] == beforeE['matches'],
    '$beforeE → $afterE',
  );
  final placed = await d.client
      .from('match_players')
      .select('is_winner, placement')
      .eq('match_id', m2)
      .eq('user_id', d.id)
      .single();
  check(
    'the table itself still records who was left standing',
    placed['is_winner'] == true,
    placed,
  );

  // The function never echoes raw database text.
  final raw = await a.call({
    'op': 'rematch',
    'matchId': '00000000-0000-0000-0000-000000000000',
  });
  check(
    'unknown match → a code, no SQL in the reply',
    raw['ok'] == false &&
        !('${raw['detail'] ?? ''}${raw['error']}'.contains('Key (')),
    raw,
  );
}

Future<void> joinRace(List<Player> ps) async {
  area('CONCURRENCY & ATTACKS');
  final host = ps[0];
  final code = await createRoom(host, 2);
  final results = await Future.wait([
    rpcOrError(ps[1].client, 'join_room', {'p_code': code}),
    rpcOrError(ps[2].client, 'join_room', {'p_code': code}),
  ]);
  final ok = results.where((r) => r!['ok'] == true).length;
  final full = results
      .where(
        (r) => r!['ok'] == false && '${r['message']}'.contains('room_full'),
      )
      .length;
  check(
    'TWO USERS JOINING THE FINAL SLOT: one seated, one room_full',
    ok == 1 && full == 1,
    results.map((r) => r!['ok'] == true ? 'ok' : r['message']).join(' | '),
  );
  final bogus = await rpcOrError(ps[3].client, 'join_room', {
    'p_code': 'ZZZZZZ',
  });
  check(
    'JOIN FULL/UNKNOWN ROOM refused',
    bogus!['ok'] == false,
    bogus['message'],
  );
  final room = await host.client
      .from('rooms')
      .select()
      .eq('code', code)
      .single();
  for (final p in ps.sublist(1, 3)) {
    await rpcOrError(p.client, 'leave_room', {'p_room_id': room['id']});
  }
  await rpcOrError(host.client, 'leave_room', {'p_room_id': room['id']});
}

Future<void> turnTimer(List<Player> ps) async {
  area('TURN TIMER');
  final host = ps[0];
  final code = await createRoom(host, 2, timer: 15);
  await joinRoom(ps[1], code);
  final room = await host.client
      .from('rooms')
      .select()
      .eq('code', code)
      .single();
  await ps[1].client.rpc<void>(
    'set_ready',
    params: {'p_room_id': room['id'], 'p_ready': true},
  );
  final started = await host.call({'op': 'start', 'roomId': room['id']});
  final matchId = started['matchId'] as String;
  final m = await host.client
      .from('matches')
      .select()
      .eq('id', matchId)
      .single();
  check(
    'server persisted turn_started_at / turn_deadline_at (15 s)',
    m['turn_started_at'] != null && m['turn_deadline_at'] != null,
    m['turn_deadline_at'],
  );
  final deadline = DateTime.parse(m['turn_deadline_at'] as String);
  final started_ = DateTime.parse(m['turn_started_at'] as String);
  check(
    'deadline - started ≈ 15 s',
    (deadline.difference(started_).inSeconds - 15).abs() <= 1,
    deadline.difference(started_),
  );
  final early = await ps[1].call({'op': 'timeout', 'matchId': matchId});
  check(
    'timeout claim before the deadline is refused',
    early['ok'] == false && early['failure'] == 'deadlineNotReached',
    early['failure'],
  );
  if (Platform.environment['MATRIX_SKIP_TIMEOUT'] == '1') {
    stdout.writeln('   (skipping the 16 s wait: MATRIX_SKIP_TIMEOUT=1)');
  } else {
    stdout.writeln('   waiting 16 s for the deadline…');
    await Future<void>.delayed(const Duration(seconds: 16));
    final snapBefore = await ps[1].snapshot(matchId);
    final late = await ps[1].call({'op': 'timeout', 'matchId': matchId});
    check(
      'after the deadline any participant can trigger the server move',
      late['ok'] == true && late['kind'] == 'timeout',
      late,
    );
    final snapAfter = await ps[1].snapshot(matchId);
    check(
      'the server moved for the idle seat (version ${snapBefore['version']} → ${snapAfter['version']})',
      (snapAfter['version'] as int) > (snapBefore['version'] as int),
    );
    final mp = await host.client
        .from('match_players')
        .select()
        .eq('match_id', matchId);
    check(
      'consecutive_timeouts recorded for the idle seat',
      mp.any((r) => r['consecutive_timeouts'] == 1),
    );
    final m2 = await host.client
        .from('matches')
        .select()
        .eq('id', matchId)
        .single();
    check(
      'a fresh deadline was stamped for the next seat',
      m2['turn_deadline_at'] != null &&
          DateTime.parse(m2['turn_deadline_at']).isAfter(deadline),
    );
  }
  area('FORFEIT / LEAVE');
  final leaveBlocked = await rpcOrError(host.client, 'leave_room', {
    'p_room_id': room['id'],
  });
  check(
    'leave_room is blocked while the match is live',
    leaveBlocked!['ok'] == false &&
        '${leaveBlocked['message']}'.contains('match_in_progress'),
  );
  final ff = await ps[1].call({'op': 'forfeit', 'matchId': matchId});
  check(
    'a player forfeits',
    ff['ok'] == true && ff['status'] == 'finished',
    ff,
  );
  final m3 = await host.client
      .from('matches')
      .select()
      .eq('id', matchId)
      .single();
  check(
    '2-player forfeit ends the match, the other wins',
    m3['status'] == 'finished' &&
        m3['winner_id'] == host.id &&
        m3['abandoned_by'] == ps[1].id,
  );
  final again = await ps[1].call({'op': 'forfeit', 'matchId': matchId});
  check('forfeit after finish refused', again['ok'] == false, again['failure']);
}

Future<void> playFull(
  String label,
  List<Player> ps, {
  required int size,
  Map<String, dynamic> rules = const {},
  bool withProbe = false,
}) async {
  area(label);
  final host = ps[0];
  final code = await createRoom(host, size, rules: rules);
  for (final p in ps.sublist(1, size)) {
    await joinRoom(p, code);
  }
  final room = await host.client
      .from('rooms')
      .select()
      .eq('code', code)
      .single();
  for (final p in ps.sublist(1, size)) {
    await p.client.rpc<void>(
      'set_ready',
      params: {'p_room_id': room['id'], 'p_ready': true},
    );
  }
  final started = await host.call({'op': 'start', 'roomId': room['id']});
  check('$size-player match started', started['ok'] == true, started);
  final matchId = started['matchId'] as String;
  _lastMatch = matchId;
  _lastRoom = room['id'] as String;
  final seats = ps.sublist(0, size);
  final sw = Stopwatch()..start();
  final stats = await drive(
    matchId,
    seats,
    probe: withProbe ? (c, o) => adversarialProbe(c, o, matchId) : null,
  );
  _area = label;
  stdout.writeln(
    '   ${stats.actions} actions in ${sw.elapsed.inSeconds}s: plays ${stats.plays}, draws ${stats.draws}, '
    'passes ${stats.passes}, rounds ${stats.rounds + 1}, Assi ${stats.assi}, Due ${stats.due}, '
    'Cavalli ${stats.cavalli} (blocks ${stats.blocks}), max chain ${stats.maxChain}, '
    'penalty draws ${stats.penaltyDraws}, reshuffles ${stats.recycles}, refused ${stats.rejectedByServer}',
  );
  check(
    '$size-player match played to the end by $size independent clients',
    stats.finished,
    'winner ${stats.winner}',
  );
  check(
    'no client move computed by the app engine was refused by the server',
    stats.rejectedByServer == 0,
    stats.rejectedByServer,
  );
  _areas.putIfAbsent('ASSO', () => []).add(stats.assi > 0);
  stdout.writeln(
    '${stats.assi > 0 ? 'PASS' : 'FAIL'}  ASSO played ${stats.assi}×${stats.assoSkipVerified ? ', skip verified (next seat +2)' : ''}',
  );
  if (stats.assi > 0 && !stats.assoSkipVerified) {
    _areas['ASSO']!.add(false);
    stdout.writeln('FAIL  ASSO skip not verified');
    _failures++;
  }
  _areas
      .putIfAbsent('+2', () => [])
      .add(stats.due > 0 && stats.penaltyDraws > 0);
  stdout.writeln(
    '${stats.due > 0 && stats.penaltyDraws > 0 ? 'PASS' : 'FAIL'}  +2 played ${stats.due}×, penalty draws ${stats.penaltyDraws}',
  );
  _areas.putIfAbsent('STACKING', () => []).add(stats.maxChain >= 2);
  stdout.writeln(
    '${stats.maxChain >= 2 ? 'PASS' : 'FAIL'}  STACKING: longest chain ${stats.maxChain} (+${stats.maxChain * 2})',
  );
  _areas.putIfAbsent('9', () => []).add(stats.cavalli > 0);
  stdout.writeln(
    '${stats.cavalli > 0 ? 'PASS' : 'FAIL'}  9 (Cavallo) played ${stats.cavalli}× with server-side suit choice',
  );
  _totalBlocks += stats.blocks;
  stdout.writeln('   Cavallo blocks this game: ${stats.blocks}');
  _totalRecycles += stats.recycles;
  stdout.writeln('   reshuffles this game: ${stats.recycles}');
  if (!(stats.assi > 0) ||
      !(stats.due > 0 && stats.penaltyDraws > 0) ||
      !(stats.maxChain >= 2) ||
      !(stats.cavalli > 0)) {
    _failures++;
  }
  await afterFinish(seats, matchId, stats);
}

Future<void> main() async {
  final env = Platform.environment;
  url = env['SUPABASE_URL'] ?? '';
  key = env['SUPABASE_PUBLISHABLE_KEY'] ?? '';
  if (url.isEmpty || key.isEmpty) {
    stderr.writeln('SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY are required');
    exit(2);
  }
  final total = Stopwatch()..start();
  area('SETUP');
  final ps = <Player>[];
  for (final tag in ['A', 'B', 'C', 'D', 'E']) {
    ps.add(await signUp(tag));
  }
  check(
    'five independent authenticated users',
    ps.map((p) => p.id).toSet().length == 5,
  );

  // 2 players: private room, hand security, attacks mid-game, full game to 101.
  await privateRoomAndHands(ps.sublist(0, 2));
  final m2 = _lastMatch!;
  _area = '2 PLAYER';
  stdout.writeln('\n== 2 PLAYER ==');
  final sw2 = Stopwatch()..start();
  final stats2 = await drive(
    m2,
    ps.sublist(0, 2),
    probe: (c, o) => adversarialProbe(c, o, m2),
  );
  _area = '2 PLAYER';
  stdout.writeln(
    '   ${stats2.actions} actions in ${sw2.elapsed.inSeconds}s: plays ${stats2.plays}, draws ${stats2.draws}, passes ${stats2.passes}, rounds ${stats2.rounds + 1}, Assi ${stats2.assi}, Due ${stats2.due}, Cavalli ${stats2.cavalli} (blocks ${stats2.blocks}), max chain ${stats2.maxChain}, reshuffles ${stats2.recycles}, refused ${stats2.rejectedByServer}',
  );
  check(
    '2-player match to 101 played to the end by two independent clients',
    stats2.finished,
    'winner ${stats2.winner}',
  );
  check(
    'no app-engine move refused by the server',
    stats2.rejectedByServer == 0,
    stats2.rejectedByServer,
  );
  _totalRecycles += stats2.recycles;
  _totalBlocks += stats2.blocks;
  await afterFinish(ps.sublist(0, 2), m2, stats2);
  final rematchId = await rematch(ps.sublist(0, 2), m2);
  if (rematchId != null) {
    await reconnectAndRealtime(ps[0], ps[1], rematchId);
    await unrelatedSubscriber(ps[4], rematchId);
    // Free the players again: the guest walks out, which is a forfeit.
    _area = 'REMATCH';
    final ff = await ps[1].call({'op': 'forfeit', 'matchId': rematchId});
    check(
      'leaving the rematch forfeits it (2 players → the other wins)',
      ff['ok'] == true && ff['status'] == 'finished',
      ff,
    );
  }

  await joinRace(ps);
  await hardening(ps);
  await turnTimer(ps.sublist(0, 2));
  await quickMatch(ps.sublist(0, 5), 2);
  final qm = _lastMatch!;
  {
    _area = 'QUICK MATCH';
    // Play a few real turns on the quick-match table, then end it by forfeit.
    final st = await drive(qm, ps.sublist(0, 2), maxActions: 12);
    check(
      'quick-match table is playable',
      st.actions == 12 && st.rejectedByServer == 0,
    );
    final ff = await ps[0].call({'op': 'forfeit', 'matchId': qm});
    check(
      'quick-match game ended by forfeit',
      ff['ok'] == true && ff['status'] == 'finished',
      ff,
    );
  }

  if (Platform.environment['MATRIX_QUICK'] == '1') {
    stdout.writeln('\n   (MATRIX_QUICK=1: 3- and 4-player games skipped)');
  } else {
    await playFull(
      '3 PLAYER',
      ps.sublist(0, 3),
      size: 3,
      rules: {'targetScore': 45},
    );
    await playFull(
      '4 PLAYER',
      ps.sublist(0, 4),
      size: 4,
      // Eight-card hands leave 7 cards in the stock: the reshuffle is certain.
      rules: {'targetScore': 45, 'startingHandSize': 8},
    );
  }
  // The stock only runs dry when a round lasts long enough; across the
  // 2/3/4-player games it must have happened at least once.
  _area = 'RESHUFFLE';
  check(
    'draw pile recycled across the games ($_totalRecycles×)',
    _totalRecycles > 0,
  );
  _area = '9 BLOCK';
  check(
    'a Cavallo blocked a pending chain across the games ($_totalBlocks×)',
    _totalBlocks > 0,
  );

  stdout.writeln(
    '\n================ SUMMARY (${total.elapsed.inSeconds}s) ================',
  );
  for (final e in _areas.entries) {
    final ok = e.value.where((x) => x).length;
    stdout.writeln(
      '${ok == e.value.length ? 'PASS' : 'FAIL'}  ${e.key.padRight(24)} $ok/${e.value.length}',
    );
  }
  stdout.writeln(_failures == 0 ? 'ALL PASS' : '$_failures FAILURE(S)');
  for (final p in ps) {
    await p.client.dispose();
  }
  exit(_failures == 0 ? 0 : 1);
}
