// Progression smoke test against a Supabase project (S5 migration
// 20260830120000_progression_missions.sql): leaderboard paging, per-round
// facts, achievements, daily missions and claims — all judged by the server
// after a REAL 2-player match played by two independent authenticated
// clients through the deployed `match` Edge Function.
//
//   SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… dart run tool/progression_smoke.dart
//
// Same conventions as tool/online_matrix.dart: every player is its own
// SupabaseClient / auth user / JWT, legality on the client side is computed
// with the app's GameEngine over the redacted snapshot + own hand, and the
// tool prints PASS/FAIL per check and exits non-zero on any FAIL. What the
// clients observed (Assi, Due, Cavalli, blocks, round results) is compared
// against what the server recorded.
import 'dart:io';
import 'dart:math';

import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:supabase/supabase.dart';

// ---------------------------------------------------------------- reporting

int _checks = 0;
int _failures = 0;

void area(String name) => stdout.writeln('\n== $name ==');

void check(String name, bool ok, [Object? detail]) {
  _checks++;
  stdout.writeln(
    '${ok ? 'PASS' : 'FAIL'}  $name${detail == null ? '' : '  ($detail)'}',
  );
  if (!ok) _failures++;
}

void note(String text) => stdout.writeln('   $text');

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

String _randomTag() {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(
    8,
    (_) => alphabet[_rand.nextInt(alphabet.length)],
  ).join();
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

  // What THIS client observed itself doing during the match.
  int assi = 0, due = 0, cavalli = 0, blocks = 0;

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
  }

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

  Future<Map<String, dynamic>> profile() async =>
      client.from('profiles').select().eq('id', id).single();

  Future<List<Map<String, dynamic>>> missions() async {
    final r = await client.rpc<dynamic>('my_daily_missions');
    return (r as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }
}

Future<Player> signUp(String tag) async {
  final client = SupabaseClient(
    url,
    key,
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  final email = 's5-prog-${_randomTag()}@example.com';
  const password = 'S5-Prog-2026!';
  final res = await client.auth.signUp(
    email: email,
    password: password,
    data: {
      'nickname': 'P$tag${_randomTag().substring(0, 4)}',
      'avatar_id': 'sofia',
    },
  );
  final id = res.user!.id;
  if (res.session == null) {
    throw StateError('sign-up returned no session (autoconfirm off?)');
  }
  return Player(tag, client, id, email, password);
}

Future<Map<String, dynamic>> rpcOrError(
  SupabaseClient c,
  String fn,
  Map<String, dynamic> params, {
  String? schema,
}) async {
  try {
    final r = schema == null
        ? await c.rpc<dynamic>(fn, params: params)
        : await c.schema(schema).rpc<dynamic>(fn, params: params);
    return {'ok': true, 'data': r};
  } on PostgrestException catch (e) {
    return {'ok': false, 'code': e.code, 'message': e.message};
  }
}

Future<List<Map<String, dynamic>>> rpcRows(
  SupabaseClient c,
  String fn,
  Map<String, dynamic> params,
) async {
  final r = await c.rpc<dynamic>(fn, params: params);
  return (r as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
}

// ------------------------------------------------------------ server mirrors

/// app_private.level_for_xp: level cost 120 + 40/level.
int levelForXp(int xp) {
  var x = xp;
  var level = 1;
  var cost = 120;
  while (x >= cost) {
    x -= cost;
    level++;
    cost += 40;
  }
  return level;
}

/// app_private.mission_rotation(isodow): (key, target, reward_xp) in
/// sort order. MUST match the migration.
const Map<int, List<(String, int, int)>> rotation = {
  1: [('play_matches', 2, 30), ('play_aces', 3, 25), ('use_nine', 1, 20)],
  2: [('win_match', 1, 40), ('play_twos', 3, 25), ('online_match', 1, 30)],
  3: [('play_matches', 3, 35), ('block_two', 1, 30), ('use_nine', 2, 25)],
  4: [('win_match', 1, 40), ('play_aces', 4, 30), ('play_matches', 2, 30)],
  5: [('play_twos', 4, 30), ('use_nine', 2, 25), ('online_match', 1, 30)],
  6: [('play_matches', 3, 35), ('win_match', 2, 50), ('block_two', 1, 30)],
  7: [('play_aces', 3, 25), ('use_nine', 3, 30), ('online_match', 2, 45)],
};

// --------------------------------------------------------------- game driver

const engine = GameEngine();

class ObservedRound {
  ObservedRound(this.roundNumber, this.winnerId, this.hitExact101);
  final int roundNumber;
  final String winnerId;
  final Map<String, bool> hitExact101; // engine player id -> flag
}

class DriveStats {
  int actions = 0, plays = 0, draws = 0, passes = 0, rounds = 0;
  int maxChain = 0, rejectedByServer = 0;
  bool finished = false;
  String? winner;
  GameState? finalState;
  final Map<int, ObservedRound> observedRounds = {};
}

/// Plays [matchId] to the end with every seat acting from ITS OWN client
/// and its own hand. Mirrors tool/online_matrix.dart's driver, plus
/// per-player counters of the special cards each client played.
Future<DriveStats> drive(
  String matchId,
  List<Player> players, {
  int maxActions = 3000,
}) async {
  final stats = DriveStats();
  final byPid = <String, Player>{};
  for (final p in players) {
    final snap = await p.snapshot(matchId);
    byPid[p.enginePlayerId(snap)] = p;
  }

  void observeRound(GameState st) {
    final rr = st.lastRoundResult;
    if (rr == null) return;
    stats.observedRounds.putIfAbsent(
      rr.roundNumber,
      () => ObservedRound(rr.roundNumber, rr.winnerId, {
        for (final row in rr.rows) row.playerId: row.hitExact101,
      }),
    );
  }

  while (stats.actions < maxActions) {
    final ref = players.first;
    final s = ref.view!;
    if (s.isFinished) {
      stats.finished = true;
      stats.winner = s.winnerId;
      stats.finalState = s;
      observeRound(s);
      break;
    }
    final pid = s.currentPlayerId;
    final actor = byPid[pid]!;
    await actor.snapshot(matchId);
    var v = actor.view!;
    if (v.version != s.version) {
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
      observeRound(v);
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
      // Prefer the special cards so the missions get exercised: stack 2s,
      // but block a chain of two or more with a Cavallo when we hold one.
      if (v.chainLength >= 2) {
        pick = playable.where((c) => c.isCavallo).firstOrNull;
      }
      pick ??= playable.where((c) => c.isDue).firstOrNull;
      pick ??= playable.where((c) => c.isCavallo).firstOrNull;
      pick ??= playable.where((c) => c.isAsso).firstOrNull;
      pick ??= playable.firstOrNull;
      if (pick != null) {
        final pendingBefore = v.pendingDrawCount;
        // §16 — the announcement the ULTIMA CARTA button sends, made through
        // the server like every other move. Without it the server refuses the
        // play that would leave this seat one card.
        if (engine.canDeclareLastCard(v, pid)) {
          final d = await actor.call(act({'type': 'declareLastCard'}));
          stats.actions++;
          if (d['accepted'] == true) actor.adoptResponse(d, pid);
        }
        r = await actor.call(act({'type': 'playCard', 'card': pick.id}));
        if (r['accepted'] == true) {
          stats.plays++;
          if (pick.isAsso) actor.assi++;
          if (pick.isDue) actor.due++;
          if (pick.isCavallo) {
            actor.cavalli++;
            if (pendingBefore > 0) actor.blocks++;
          }
        }
      } else if (engine.canDraw(v)) {
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
      final st = actor.view!;
      if (st.chainLength > stats.maxChain) stats.maxChain = st.chainLength;
      if (st.status == GameStatus.roundOver || st.isFinished) observeRound(st);
      for (final p in players) {
        if (p.id != actor.id) await p.snapshot(matchId);
      }
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

// ------------------------------------------------------------------- phases

Future<String> createRoom(Player host, int players) async {
  final row = await host.client.rpc<Map<String, dynamic>>(
    'create_room',
    params: {
      'p_name': 'P${host.tag}',
      'p_max_players': players,
      'p_is_private': true,
      'p_turn_timer_seconds': 0,
      'p_rules': <String, dynamic>{},
    },
  );
  return row['code'] as String;
}

Future<String> roomAndStart(Player a, Player b) async {
  area('ROOM');
  final code = await createRoom(a, 2);
  check('A created a private 2-player room', code.length == 6, code);
  final joined = await b.client.rpc<Map<String, dynamic>>(
    'join_room',
    params: {'p_code': code},
  );
  check('B joined by code', joined['code'] == code);
  final room = await a.client.from('rooms').select().eq('code', code).single();
  final roomId = room['id'] as String;
  await b.client.rpc<void>(
    'set_ready',
    params: {'p_room_id': roomId, 'p_ready': true},
  );
  final started = await a.call({'op': 'start', 'roomId': roomId});
  check('A started the match via the function', started['ok'] == true, started);
  return started['matchId'] as String;
}

String describe(List<Map<String, dynamic>> rows) => rows
    .map(
      (m) =>
          '${m['mission_key']}:${m['progress']}/${m['target']}'
          '${m['claimed_at'] != null ? '(claimed)' : ''}',
    )
    .join(' ');

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
  final a = await signUp('A');
  final b = await signUp('B');
  check('two independent authenticated users', a.id != b.id);
  note('A = ${a.email}');
  note('B = ${b.email}');
  final profA0 = await a.profile();
  final profB0 = await b.profile();
  check(
    'fresh profiles: matches 0, xp 0, level 1',
    profA0['matches'] == 0 &&
        profA0['xp'] == 0 &&
        profA0['level'] == 1 &&
        profB0['matches'] == 0 &&
        profB0['xp'] == 0,
  );

  // ---- missions before the match ---------------------------------------
  area('MISSIONS BEFORE');
  final approxRome = DateTime.now().toUtc().add(const Duration(hours: 2));
  final approxDate =
      '${approxRome.year}-${approxRome.month.toString().padLeft(2, '0')}-'
      '${approxRome.day.toString().padLeft(2, '0')}';
  note(
    'approximate Europe/Rome date $approxDate (UTC+2 approximation), '
    'ISO weekday ${approxRome.weekday}',
  );
  final missionsA0 = await a.missions();
  final missionsB0 = await b.missions();
  note('A before: ${describe(missionsA0)}');
  check(
    'my_daily_missions() returns 3 missions for today',
    missionsA0.length == 3,
    missionsA0.length,
  );
  check(
    'all progress 0 and unclaimed for a fresh user',
    missionsA0.every((m) => m['progress'] == 0 && m['claimed_at'] == null) &&
        missionsB0.every((m) => m['progress'] == 0),
  );
  final missionDate = missionsA0.isEmpty
      ? approxDate
      : missionsA0.first['mission_date'] as String;
  check(
    'mission_date == approximate Rome date',
    missionDate == approxDate,
    'server $missionDate vs approx $approxDate',
  );
  final serverDow = DateTime.parse(missionDate).weekday;
  final expectedRotation = rotation[serverDow]!;
  check(
    'mission keys/targets/rewards match app_private.mission_rotation for ISO weekday $serverDow (in sort order)',
    missionsA0.length == expectedRotation.length &&
        [
          for (var i = 0; i < missionsA0.length; i++)
            missionsA0[i]['mission_key'] == expectedRotation[i].$1 &&
                missionsA0[i]['target'] == expectedRotation[i].$2 &&
                missionsA0[i]['reward_xp'] == expectedRotation[i].$3,
        ].every((x) => x),
    'server ${missionsA0.map((m) => m['mission_key']).join(',')} vs '
        'expected ${expectedRotation.map((r) => r.$1).join(',')}',
  );
  check(
    'A and B see the same mission ids',
    missionsA0
        .map((m) => m['mission_id'])
        .toSet()
        .containsAll(missionsB0.map((m) => m['mission_id'])),
  );

  // ---- the match --------------------------------------------------------
  final matchId = await roomAndStart(a, b);
  area('2-PLAYER MATCH TO 101');
  final sw = Stopwatch()..start();
  final stats = await drive(matchId, [a, b]);
  note(
    '${stats.actions} actions in ${sw.elapsed.inSeconds}s: plays ${stats.plays}, '
    'draws ${stats.draws}, passes ${stats.passes}, rounds ${stats.rounds + 1}, '
    'max chain ${stats.maxChain}, refused ${stats.rejectedByServer}',
  );
  for (final p in [a, b]) {
    note(
      '${p.tag} played Assi ${p.assi}, Due ${p.due}, Cavalli ${p.cavalli} '
      '(blocks ${p.blocks})',
    );
  }
  check(
    'match played to finished by two independent clients',
    stats.finished,
    'winner ${stats.winner}',
  );
  check(
    'no app-engine move refused by the server',
    stats.rejectedByServer == 0,
    stats.rejectedByServer,
  );
  if (!stats.finished) {
    stdout.writeln('\nRESULT: $_checks checks, $_failures failures');
    exit(1);
  }
  final finalState = stats.finalState!;
  final winnerPid = finalState.winnerId!;
  final snapA = await a.snapshot(matchId);
  final pidA = a.enginePlayerId(snapA);
  final winner = winnerPid == pidA ? a : b;
  final loser = winner == a ? b : a;
  note(
    'winner is ${winner.tag} ($winnerPid), longestChain ${finalState.stats.longestChain}',
  );

  // ---- profiles ----------------------------------------------------------
  area('PROFILES');
  final profA1 = await a.profile();
  final profB1 = await b.profile();
  final prof1 = {a.id: profA1, b.id: profB1};
  for (final p in [a, b]) {
    final pr = prof1[p.id]!;
    final won = p == winner;
    check('${p.tag}: matches 0 -> 1', pr['matches'] == 1, pr['matches']);
    check(
      '${p.tag}: xp 0 -> ${won ? 65 : 20} (${won ? 'winner' : 'other'})',
      pr['xp'] == (won ? 65 : 20),
      pr['xp'],
    );
    check(
      '${p.tag}: level consistent with xp',
      pr['level'] == levelForXp(pr['xp'] as int),
      'level ${pr['level']} for xp ${pr['xp']}',
    );
    check(
      '${p.tag}: wins/current_streak',
      won
          ? pr['wins'] == 1 && pr['current_streak'] == 1
          : pr['wins'] == 0 && pr['current_streak'] == 0,
      'wins ${pr['wins']} streak ${pr['current_streak']}',
    );
  }

  // ---- match_round_results ----------------------------------------------
  area('MATCH ROUND RESULTS');
  final roundRows = await a.client
      .from('match_round_results')
      .select()
      .eq('match_id', matchId)
      .order('round')
      .order('user_id');
  final roundNumbers = roundRows.map((r) => r['round'] as int).toSet().toList()
    ..sort();
  final playedRounds = stats.rounds + 1;
  note(
    'rows ${roundRows.length}, rounds ${roundNumbers.join(',')}, '
    'client observed $playedRounds rounds '
    '(${stats.observedRounds.keys.toList()..sort()})',
  );
  check(
    'participants can select match_round_results (rows exist)',
    roundRows.isNotEmpty,
    roundRows.length,
  );
  check(
    'one row per seat per round (2 x $playedRounds)',
    roundRows.length == 2 * playedRounds &&
        roundNumbers.length == playedRounds &&
        roundNumbers.every(
          (r) => roundRows.where((x) => x['round'] == r).length == 2,
        ),
    '${roundRows.length} rows, rounds $roundNumbers',
  );
  check(
    'round numbers are 1..$playedRounds',
    roundNumbers.length == playedRounds &&
        [for (var i = 0; i < roundNumbers.length; i++) roundNumbers[i] == i + 1]
            .every((x) => x),
  );
  check(
    'every row belongs to A or B',
    roundRows.every((r) => r['user_id'] == a.id || r['user_id'] == b.id),
  );
  check(
    'exactly one won_round per round',
    roundNumbers.every(
      (r) =>
          roundRows
              .where((x) => x['round'] == r && x['won_round'] == true)
              .length ==
          1,
    ),
  );
  // Compare with what the clients saw in lastRoundResult.
  final pidOf = {a.id: pidA, b.id: pidA == 'p0' ? 'p1' : 'p0'};
  var roundsAgree = true;
  final disagreements = <String>[];
  for (final r in roundRows) {
    final obs = stats.observedRounds[r['round'] as int];
    if (obs == null) {
      roundsAgree = false;
      disagreements.add('round ${r['round']} not observed by client');
      continue;
    }
    final pid = pidOf[r['user_id']]!;
    final expectWon = obs.winnerId == pid;
    final expect101 = obs.hitExact101[pid] ?? false;
    if (r['won_round'] != expectWon || r['hit_exact_101'] != expect101) {
      roundsAgree = false;
      disagreements.add(
        'round ${r['round']} $pid: server won=${r['won_round']} 101=${r['hit_exact_101']} '
        'vs client won=$expectWon 101=$expect101',
      );
    }
  }
  check(
    'won_round / hit_exact_101 agree with the lastRoundResult the clients saw',
    roundsAgree,
    disagreements.isEmpty ? null : disagreements.join('; '),
  );
  final lastRound = roundRows.where((r) => r['round'] == roundNumbers.last);
  check(
    'final round won by the match winner',
    lastRound.any((r) => r['user_id'] == winner.id && r['won_round'] == true),
  );
  final outsider = await signUp('X');
  final peek = await outsider.client
      .from('match_round_results')
      .select()
      .eq('match_id', matchId);
  check('an outsider sees no match_round_results rows', peek.isEmpty);
  try {
    await a.client.from('match_round_results').insert({
      'match_id': matchId,
      'round': 99,
      'user_id': a.id,
      'won_round': true,
    });
    check('A cannot insert match_round_results', false, 'UNEXPECTED SUCCESS');
  } on PostgrestException catch (e) {
    check('A cannot insert match_round_results', true, e.code);
  }

  // ---- achievements --------------------------------------------------------
  area('ACHIEVEMENTS');
  final ach = await a.client.from('user_achievements').select().inFilter(
    'user_id',
    [a.id, b.id],
  );
  Set<String> unlocked(Player p) => ach
      .where((r) => r['user_id'] == p.id)
      .map((r) => r['achievement_id'] as String)
      .toSet();
  note('${a.tag}: ${unlocked(a)}  ${b.tag}: ${unlocked(b)}');
  check(
    'prima_vittoria unlocked for the winner (${winner.tag})',
    unlocked(winner).contains('prima_vittoria'),
  );
  check(
    'prima_vittoria NOT unlocked for the loser (${loser.tag})',
    !unlocked(loser).contains('prima_vittoria'),
  );
  for (final p in [a, b]) {
    final hit101 = roundRows.any(
      (r) => r['user_id'] == p.id && r['hit_exact_101'] == true,
    );
    check(
      '${p.tag}: rinascita ${hit101 ? 'unlocked' : 'absent'} '
      '(hit_exact_101 ${hit101 ? 'seen' : 'never'})',
      unlocked(p).contains('rinascita') == hit101,
    );
    final perfect = roundRows.any(
      (r) => r['user_id'] == p.id && r['perfect_hand'] == true,
    );
    check(
      '${p.tag}: mano_perfetta ${perfect ? 'unlocked' : 'absent'} '
      '(perfect_hand ${perfect ? 'seen' : 'never'})',
      unlocked(p).contains('mano_perfetta') == perfect,
    );
    final chain3 = finalState.stats.longestChain >= 3;
    check(
      '${p.tag}: catena ${chain3 ? 'unlocked' : 'absent'} '
      '(longestChain ${finalState.stats.longestChain})',
      unlocked(p).contains('catena') == chain3,
    );
  }
  check(
    'no vendetta / imbattibile / veterano on a first match',
    [a, b].every(
      (p) => unlocked(
        p,
      ).intersection({'vendetta', 'imbattibile', 'veterano'}).isEmpty,
    ),
  );

  // ---- missions after the match ------------------------------------------
  area('MISSIONS AFTER');
  final missionsA1 = await a.missions();
  final missionsB1 = await b.missions();
  note('A after: ${describe(missionsA1)}');
  note('B after: ${describe(missionsB1)}');
  check(
    'same mission ids before/after',
    missionsA1
            .map((m) => m['mission_id'])
            .toSet()
            .containsAll(missionsA0.map((m) => m['mission_id'])) &&
        missionsA1.length == missionsA0.length,
  );
  int expectedProgress(Player p, String keyName, int target) {
    final raw = switch (keyName) {
      'play_matches' || 'online_match' => 1,
      'win_match' => p == winner ? 1 : 0,
      'play_aces' => p.assi,
      'play_twos' => p.due,
      'use_nine' => p.cavalli,
      'block_two' => p.blocks,
      _ => -1,
    };
    return raw < 0 ? -1 : min(raw, target);
  }

  for (final (p, rows) in [(a, missionsA1), (b, missionsB1)]) {
    for (final m in rows) {
      final k = m['mission_key'] as String;
      final target = m['target'] as int;
      final expect = expectedProgress(p, k, target);
      check(
        '${p.tag}: $k progress ${m['progress']}/$target == client-observed ${expect < 0 ? '?' : expect}',
        expect >= 0 && m['progress'] == expect,
      );
      check(
        '${p.tag}: $k completed_at ${m['completed_at'] == null ? 'unset' : 'set'} consistent with progress',
        (m['completed_at'] != null) == ((m['progress'] as int) >= target),
      );
    }
  }

  // ---- claims --------------------------------------------------------------
  area('CLAIM');
  Player claimer = a;
  var claimable = missionsA1
      .where(
        (m) =>
            (m['progress'] as int) >= (m['target'] as int) &&
            m['claimed_at'] == null,
      )
      .toList();
  if (claimable.isEmpty) {
    claimer = b;
    claimable = missionsB1
        .where(
          (m) =>
              (m['progress'] as int) >= (m['target'] as int) &&
              m['claimed_at'] == null,
        )
        .toList();
  }
  if (claimable.isEmpty) {
    note('no mission completed today by either user: claim path not exercised');
  } else {
    final m = claimable.first;
    final before = await claimer.profile();
    final res = await rpcOrError(claimer.client, 'claim_mission_reward', {
      'p_mission_id': m['mission_id'],
    });
    final rows = res['ok'] == true
        ? (res['data'] as List)
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList()
        : const <Map<String, dynamic>>[];
    check(
      '${claimer.tag} claims ${m['mission_key']} (+${m['reward_xp']} xp)',
      res['ok'] == true && rows.length == 1 && rows.first['claimed_at'] != null,
      res['ok'] == true ? rows : res['message'],
    );
    final after = await claimer.profile();
    check(
      'profiles.xp grew by reward_xp (${before['xp']} -> ${after['xp']})',
      after['xp'] == (before['xp'] as int) + (m['reward_xp'] as int),
    );
    check(
      'level still consistent after the claim',
      after['level'] == levelForXp(after['xp'] as int),
      'level ${after['level']} xp ${after['xp']}',
    );
    final again = await rpcOrError(claimer.client, 'claim_mission_reward', {
      'p_mission_id': m['mission_id'],
    });
    check(
      'claiming again -> already_claimed',
      again['ok'] == false && '${again['message']}'.contains('already_claimed'),
      again['message'] ?? again['data'],
    );
    final reread = await claimer.missions();
    final claimedRow = reread.firstWhere(
      (x) => x['mission_id'] == m['mission_id'],
    );
    check(
      'my_daily_missions() shows claimed_at set',
      claimedRow['claimed_at'] != null,
    );
    final after2 = await claimer.profile();
    check(
      'xp unchanged by the refused second claim',
      after2['xp'] == after['xp'],
    );
    // A claim by the OTHER user for the same mission id must not succeed
    // unless they completed it too.
    final other = claimer == a ? b : a;
    final otherRows = other == a ? missionsA1 : missionsB1;
    final otherRow = otherRows.firstWhere(
      (x) => x['mission_id'] == m['mission_id'],
    );
    final otherDone =
        (otherRow['progress'] as int) >= (otherRow['target'] as int);
    if (!otherDone) {
      final cross = await rpcOrError(other.client, 'claim_mission_reward', {
        'p_mission_id': m['mission_id'],
      });
      check(
        '${other.tag} (not complete) claiming the same mission -> not_completed',
        cross['ok'] == false && '${cross['message']}'.contains('not_completed'),
        cross['message'] ?? cross['data'],
      );
    }
  }
  final incompleteA = missionsA1
      .where((m) => (m['progress'] as int) < (m['target'] as int))
      .toList();
  if (incompleteA.isEmpty) {
    note(
      'A completed every mission today: not_completed path checked via the other user (if any)',
    );
  } else {
    final m = incompleteA.first;
    final res = await rpcOrError(a.client, 'claim_mission_reward', {
      'p_mission_id': m['mission_id'],
    });
    check(
      'A claims incomplete ${m['mission_key']} (${m['progress']}/${m['target']}) -> not_completed',
      res['ok'] == false && '${res['message']}'.contains('not_completed'),
      res['message'] ?? res['data'],
    );
  }
  final bogus = await rpcOrError(a.client, 'claim_mission_reward', {
    'p_mission_id': _uuid(),
  });
  check(
    'claim with a random uuid -> mission_expired',
    bogus['ok'] == false && '${bogus['message']}'.contains('mission_expired'),
    bogus['message'] ?? bogus['data'],
  );

  area('MISSION WRITE PROTECTION');
  final anyMission = missionsA1.first['mission_id'];
  try {
    await a.client.from('user_daily_missions').insert({
      'user_id': a.id,
      'mission_id': anyMission,
      'progress': 99,
    });
    check('A cannot insert user_daily_missions', false, 'UNEXPECTED SUCCESS');
  } on PostgrestException catch (e) {
    check('A cannot insert user_daily_missions', true, e.code);
  }
  try {
    final r = await a.client
        .from('user_daily_missions')
        .update({'progress': 99})
        .eq('user_id', a.id)
        .select();
    check(
      'A cannot update user_daily_missions',
      false,
      'UNEXPECTED SUCCESS ${r.length} rows',
    );
  } on PostgrestException catch (e) {
    check('A cannot update user_daily_missions', true, e.code);
  }
  final ownRows = await a.client
      .from('user_daily_missions')
      .select()
      .eq('user_id', a.id);
  check(
    'progress rows untouched by the refused writes',
    ownRows.every((r) => r['progress'] != 99),
  );
  final track1 = await rpcOrError(a.client, 'track_mission', {
    'p_user': a.id,
    'p_key': 'play_aces',
    'p_inc': 50,
  }, schema: 'app_private');
  check(
    'A cannot call app_private.track_mission (schema not exposed)',
    track1['ok'] == false,
    track1['code'],
  );
  final track2 = await rpcOrError(a.client, 'track_mission', {
    'p_user': a.id,
    'p_key': 'play_aces',
    'p_inc': 50,
  });
  check(
    'no public track_mission either',
    track2['ok'] == false,
    track2['code'],
  );
  final recheck = await a.missions();
  check(
    'mission progress unchanged after the attempts',
    recheck.every((m) {
      final prev = missionsA1.firstWhere(
        (x) => x['mission_id'] == m['mission_id'],
      );
      return m['progress'] == prev['progress'];
    }),
    describe(recheck),
  );
  try {
    await a.client
        .from('daily_missions')
        .update({'reward_xp': 9999})
        .eq('id', anyMission);
    check('A cannot update daily_missions', false, 'UNEXPECTED SUCCESS');
  } on PostgrestException catch (e) {
    check('A cannot update daily_missions', true, e.code);
  }

  // ---- leaderboard --------------------------------------------------------
  area('LEADERBOARD');
  final page1 = await rpcRows(a.client, 'leaderboard', {
    'p_scope': 'all_time',
    'p_limit': 25,
    'p_offset': 0,
  });
  check(
    "leaderboard('all_time', 25, 0): <= 25 rows, ranks 1..n",
    page1.isNotEmpty &&
        page1.length <= 25 &&
        [
          for (var i = 0; i < page1.length; i++) page1[i]['rank'] == i + 1,
        ].every((x) => x),
    '${page1.length} rows, first ${page1.firstOrNull?['rank']} last ${page1.lastOrNull?['rank']}',
  );
  check(
    'page 1 sorted by points desc',
    [
      for (var i = 1; i < page1.length; i++)
        (page1[i]['points'] as int) <= (page1[i - 1]['points'] as int),
    ].every((x) => x),
  );
  final page2 = await rpcRows(a.client, 'leaderboard', {
    'p_scope': 'all_time',
    'p_limit': 25,
    'p_offset': 25,
  });
  check(
    "leaderboard('all_time', 25, 25): next ranks (first == 26) or empty",
    page2.isEmpty ||
        (page2.first['rank'] == 26 &&
            page2.length <= 25 &&
            [
              for (var i = 0; i < page2.length; i++) page2[i]['rank'] == 26 + i,
            ].every((x) => x)),
    '${page2.length} rows, first ${page2.firstOrNull?['rank']}',
  );
  check(
    'page 2 has no overlap with page 1',
    page2
        .map((r) => r['user_id'])
        .toSet()
        .intersection(page1.map((r) => r['user_id']).toSet())
        .isEmpty,
  );
  final mine = await rpcRows(a.client, 'my_leaderboard_rank', {
    'p_scope': 'all_time',
  });
  check(
    "my_leaderboard_rank('all_time'): exactly A's row, is_self true",
    mine.length == 1 &&
        mine.first['user_id'] == a.id &&
        mine.first['is_self'] == true,
    mine,
  );
  // Rank consistent with paging: walk the board until A shows up.
  int? pagedRank;
  int? pagedPoints;
  var offset = 0;
  var scanned = 0;
  var selfFlagsOk = true;
  while (pagedRank == null && offset < 5000) {
    final page = await rpcRows(a.client, 'leaderboard', {
      'p_scope': 'all_time',
      'p_limit': 200,
      'p_offset': offset,
    });
    if (page.isEmpty) break;
    scanned += page.length;
    for (final r in page) {
      if ((r['is_self'] == true) != (r['user_id'] == a.id)) selfFlagsOk = false;
      if (r['user_id'] == a.id) {
        pagedRank = r['rank'] as int;
        pagedPoints = r['points'] as int;
      }
    }
    offset += 200;
  }
  check(
    'A found by paging at rank $pagedRank (scanned $scanned rows)',
    pagedRank != null,
  );
  check(
    'my_leaderboard_rank rank/points == the paged row',
    mine.isNotEmpty &&
        mine.first['rank'] == pagedRank &&
        mine.first['points'] == pagedPoints,
    'own ${mine.firstOrNull?['rank']}/${mine.firstOrNull?['points']} vs paged $pagedRank/$pagedPoints',
  );
  check('is_self true only on A\'s own row across the pages', selfFlagsOk);
  final profA2 = await a.profile();
  check(
    'all_time points == profiles.rating',
    mine.isNotEmpty && mine.first['points'] == profA2['rating'],
    '${mine.firstOrNull?['points']} vs ${profA2['rating']}',
  );
  final weeklyMine = await rpcRows(a.client, 'my_leaderboard_rank', {
    'p_scope': 'weekly',
  });
  final weeklyRows = await a.client
      .from('weekly_points')
      .select()
      .eq('user_id', a.id)
      .order('week_start', ascending: false);
  final weeklyPoints = weeklyRows.isEmpty ? null : weeklyRows.first['points'];
  check(
    "my_leaderboard_rank('weekly'): A's row with points == weekly_points ($weeklyPoints)",
    weeklyMine.length == 1 &&
        weeklyMine.first['user_id'] == a.id &&
        weeklyMine.first['is_self'] == true &&
        weeklyMine.first['points'] == weeklyPoints,
    weeklyMine,
  );
  check(
    'weekly points == xp earned this match (${a == winner ? 65 : 20})',
    weeklyPoints == (a == winner ? 65 : 20),
    weeklyPoints,
  );
  final weeklyBoard = await rpcRows(a.client, 'leaderboard', {
    'p_scope': 'weekly',
    'p_limit': 200,
    'p_offset': 0,
  });
  final weeklySelf = weeklyBoard.where((r) => r['user_id'] == a.id).toList();
  check(
    "leaderboard('weekly') contains A with the same rank (page 1 of 200)",
    weeklySelf.length == 1 &&
        weeklyMine.isNotEmpty &&
        weeklySelf.first['rank'] == weeklyMine.first['rank'],
    'board ${weeklySelf.firstOrNull?['rank']} vs own ${weeklyMine.firstOrNull?['rank']}',
  );
  final outsiderWeekly = await rpcRows(outsider.client, 'my_leaderboard_rank', {
    'p_scope': 'weekly',
  });
  check(
    'a user with no weekly points gets an empty weekly rank',
    outsiderWeekly.isEmpty,
    outsiderWeekly,
  );
  final legacy = await rpcOrError(a.client, 'leaderboard', {
    'p_scope': 'all_time',
    'p_limit': 10,
  });
  final legacyRows = legacy['ok'] == true ? (legacy['data'] as List) : const [];
  check(
    "legacy 2-arg leaderboard('all_time', 10) still works (default offset)",
    legacy['ok'] == true &&
        legacyRows.isNotEmpty &&
        legacyRows.length <= 10 &&
        legacyRows.first['rank'] == 1,
    legacy['ok'] == true ? '${legacyRows.length} rows' : legacy['message'],
  );
  final bogusScope = await rpcRows(a.client, 'leaderboard', {
    'p_scope': 'nope',
    'p_limit': 10,
    'p_offset': 0,
  });
  check('unknown scope returns no rows', bogusScope.isEmpty);

  // ---- summary --------------------------------------------------------------
  stdout.writeln(
    '\n================ SUMMARY (${total.elapsed.inSeconds}s) ================',
  );
  stdout.writeln('match $matchId, winner ${winner.tag}');
  stdout.writeln(
    'A ${a.email}  xp ${profA2['xp']} level ${profA2['level']} matches ${profA2['matches']}',
  );
  final profB2 = await b.profile();
  stdout.writeln(
    'B ${b.email}  xp ${profB2['xp']} level ${profB2['level']} matches ${profB2['matches']}',
  );
  stdout.writeln('X ${outsider.email}  (outsider)');
  stdout.writeln('missions A: ${describe(await a.missions())}');
  stdout.writeln('missions B: ${describe(await b.missions())}');
  stdout.writeln('RESULT: $_checks checks, $_failures failures');
  for (final p in [a, b, outsider]) {
    await p.client.dispose();
  }
  exit(_failures == 0 ? 0 : 1);
}
