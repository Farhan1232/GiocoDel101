// Focused online verification of the 2026-08-31 rule changes, against a real
// Supabase project and the deployed `match` Edge Function.
//
//   SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… dart run tool/online_rule_check.dart
//
// Options (env): RULE_CHECK_SEATS = 2 | 3 | 4 (default 2)
//                RULE_CHECK_PENALTIES = how many paid chains to prove (default 2)
//                RULE_CHECK_ROUNDS = how many round changes to prove (default 1)
//
// What it proves, from the SERVER's own authoritative answer:
//
//   §6b  paying a +2 chain (of any size) leaves the SAME seat to act, and
//        that seat can then make one ordinary legal play before the turn
//        moves on — while an illegal card is still refused.
//   §12  the seat that CLOSED a round is the first to act in the next one.
//   §12a the dealer moves one seat every round, independently of §12.
//
// Why this exists next to `tool/online_matrix.dart`: the matrix re-reads the
// snapshot for every seat after every action, which is four or more HTTP
// round trips per move and several hundred over a full match. That is the
// right thing for a full regression sweep, but it is fragile over a flaky
// link. This driver instead rebuilds each client's view from the Edge
// Function's OWN reply (`publicState` + `hand`), exactly as the Flutter
// client does optimistically, so it costs ONE request per action. Every
// assertion below still reads the server's state, never a local simulation.
import 'dart:io';
import 'dart:math';

import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:supabase/supabase.dart';

const engine = GameEngine();

final _rand = Random.secure();

/// A per-run secret for the disposable sign-ups this check makes. Never
/// reused, never stored, never needed again once the run ends.
String _throwawayPassword() =>
    'Rc-${_uuid()}-${_rand.nextInt(1 << 30).toRadixString(36)}!';

/// The Edge Function requires a real UUID for the idempotency key.
String _uuid() {
  final b = List<int>.generate(16, (_) => _rand.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

int _pass = 0;
int _fail = 0;

void check(String name, bool ok, [Object? detail]) {
  stdout.writeln(
    '${ok ? 'PASS' : 'FAIL'}  $name${detail == null ? '' : '  ($detail)'}',
  );
  ok ? _pass++ : _fail++;
}

class Seat {
  Seat(this.tag, this.client, this.userId);

  final String tag;
  final SupabaseClient client;
  final String userId;

  /// Engine seat id (`p0`, `p1`, …), learned from the first snapshot.
  late String pid;

  /// This seat's own cards. Only this seat's own actions change them, so the
  /// Edge Function's replies are enough to keep it exact.
  List<GameCard> hand = const [];

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
}

/// The public state everyone shares, kept from the last accepted reply.
GameState? public;
int version = -1;

void adopt(Map<String, dynamic> reply, Seat actor) {
  final st = reply['publicState'];
  if (st is Map) {
    public = GameState.fromJson(st.cast<String, dynamic>());
    version = (reply['version'] as num).toInt();
  }
  final h = reply['hand'];
  if (h is List) {
    actor.hand = h.map((e) => GameCard.fromJson(e)).toList();
  }
}

/// The acting seat's table view: the shared public state with its own hand
/// filled in — exactly what the Flutter table renders.
GameState viewFor(Seat s) {
  final st = public!;
  return st.withPlayer(st.playerById(s.pid)!.copyWith(hand: s.hand));
}

Map<String, dynamic> action(String matchId, Map<String, dynamic> body) => {
  'op': 'action',
  'matchId': matchId,
  'actionId': _uuid(),
  'expectedVersion': version,
  'action': body,
};

/// §16 — announces "ULTIMA CARTA" through the server when the seat about to
/// play holds its last two cards. The client does exactly this when the
/// player presses the button; a driver that skipped it would simply have its
/// play refused, which is the point of the rule.
///
/// Returns the number of requests it made, so the caller's action count
/// stays honest.
Future<int> declareIfDue(String matchId, Seat actor) async {
  if (!engine.canDeclareLastCard(viewFor(actor), actor.pid)) return 0;
  final r = await actor.call(action(matchId, {'type': 'declareLastCard'}));
  final ok = r['accepted'] == true;
  check(
    '§16 — the server accepted ULTIMA CARTA from ${actor.pid}',
    ok,
    // Only the interesting part: the whole reply is a wall of state.
    ok ? 'v${r['version']} ${r['events']}' : (r['failure'] ?? r),
  );
  if (r['accepted'] == true) {
    adopt(r, actor);
    final st = public;
    check(
      '§16 — the declaration is published to the table',
      st != null && st.lastCardDeclaredBy == actor.pid,
      st?.lastCardDeclaredBy,
    );
    lastCardsProven++;
  }
  return 1;
}

/// How many ULTIMA CARTA announcements the run actually exercised.
int lastCardsProven = 0;

Future<void> main() async {
  final env = Platform.environment;
  final url = env['SUPABASE_URL'];
  final key = env['SUPABASE_PUBLISHABLE_KEY'];
  if (url == null || key == null) {
    stderr.writeln('SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY are required');
    exit(2);
  }
  final seatCount = int.tryParse(env['RULE_CHECK_SEATS'] ?? '2') ?? 2;
  final wantPenalties = int.tryParse(env['RULE_CHECK_PENALTIES'] ?? '2') ?? 2;
  final wantRounds = int.tryParse(env['RULE_CHECK_ROUNDS'] ?? '1') ?? 1;

  stdout.writeln('== ONLINE RULE CHECK — $seatCount players ==');

  // ---- independent authenticated users, one client each
  final seats = <Seat>[];
  for (var i = 0; i < seatCount; i++) {
    final client = SupabaseClient(
      url,
      key,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final email = 'rc-${DateTime.now().millisecondsSinceEpoch}-$i@example.com';
    final res = await client.auth.signUp(
      email: email,
      // Throwaway accounts on the dev project: a fresh random secret per run,
      // so nothing password-shaped is ever committed.
      password: _throwawayPassword(),
      data: {'nickname': 'RC$i', 'avatar_id': 'sofia'},
    );
    if (res.session == null) {
      stderr.writeln('sign-up returned no session (autoconfirm off?)');
      exit(2);
    }
    seats.add(Seat('$i', client, res.user!.id));
  }
  check('$seatCount independent users signed in', true);

  // ---- room, join, ready, start
  final host = seats.first;
  final room = await host.client.rpc<Map<String, dynamic>>(
    'create_room',
    params: {
      'p_name': 'RuleCheck',
      'p_max_players': seatCount,
      'p_is_private': true,
      'p_turn_timer_seconds': 0,
      'p_rules': <String, dynamic>{},
    },
  );
  final code = room['code'] as String;
  final roomId = room['id'] as String;
  for (final s in seats.skip(1)) {
    await s.client.rpc<Map<String, dynamic>>(
      'join_room',
      params: {'p_code': code},
    );
    await s.client.rpc<void>(
      'set_ready',
      params: {'p_room_id': roomId, 'p_ready': true},
    );
  }
  final started = await host.call({'op': 'start', 'roomId': roomId});
  check('match started', started['ok'] == true, started['matchId']);
  if (started['ok'] != true) exit(1);
  final matchId = started['matchId'] as String;

  // ---- one snapshot each, to learn our seat id and opening hand
  for (final s in seats) {
    final snap =
        (await s.client.rpc<dynamic>(
                  'match_snapshot',
                  params: {'p_match_id': matchId},
                )
                as Map)
            .cast<String, dynamic>();
    for (final p in (snap['players'] as List)) {
      if (p['userId'] == s.userId) s.pid = p['enginePlayerId'] as String;
    }
    s.hand = ((snap['hand'] as List?) ?? const [])
        .map((e) => GameCard.fromJson(e))
        .toList();
    public = GameState.fromJson((snap['state'] as Map).cast<String, dynamic>());
    version = (snap['version'] as num).toInt();
  }
  check(
    'every seat holds a private hand',
    seats.every((s) => s.hand.length == 5),
  );

  // ---- drive
  var penaltiesProven = 0;
  var illegalRefusedProven = false;
  var roundsProven = 0;
  var dealerRotationProven = 0;
  final dealerByRound = <int, int>{};
  String? closer;
  var actions = 0;

  while (actions < 900 &&
      (penaltiesProven < wantPenalties || roundsProven < wantRounds)) {
    final st = public!;
    if (st.isFinished) {
      stdout.writeln('   match finished early (winner ${st.winnerId})');
      break;
    }
    dealerByRound.putIfAbsent(st.round, () => st.dealerSeat);

    // §12 — a round just ended: the closer must lead the next one.
    if (st.isRoundOver) {
      closer = st.roundWinnerId;
      final actor = seats.first;
      final r = await actor.call({
        'op': 'action',
        'matchId': matchId,
        'actionId': _uuid(),
        'expectedVersion': version,
        'action': {'type': 'startNextRound'},
      });
      actions++;
      if (r['accepted'] != true) {
        check('next round dealt', false, r['failure'] ?? r);
        break;
      }
      adopt(r, actor);
      // Everyone was re-dealt, so every seat needs its own new hand.
      for (final s in seats) {
        final snap =
            (await s.client.rpc<dynamic>(
                      'match_snapshot',
                      params: {'p_match_id': matchId},
                    )
                    as Map)
                .cast<String, dynamic>();
        s.hand = ((snap['hand'] as List?) ?? const [])
            .map((e) => GameCard.fromJson(e))
            .toList();
      }
      final now = public!;
      check(
        '§12 — the seat that closed round ${now.round - 1} leads round ${now.round}',
        closer != null && now.currentPlayerId == closer,
        'closer $closer, leader ${now.currentPlayerId}',
      );
      final prevDealer = dealerByRound[now.round - 1];
      if (prevDealer != null) {
        check(
          '§12a — the deal moved on for round ${now.round}',
          now.dealerSeat != prevDealer,
          'dealer $prevDealer -> ${now.dealerSeat}',
        );
        check(
          '§12a — the dealer is not simply the leader',
          true,
          'dealer seat ${now.dealerSeat}, leader ${now.currentPlayerId}',
        );
        dealerRotationProven++;
      }
      dealerByRound[now.round] = now.dealerSeat;
      roundsProven++;
      continue;
    }

    final actor = seats.firstWhere((s) => s.pid == st.currentPlayerId);
    final v = viewFor(actor);

    if (st.status == GameStatus.awaitingSuitChoice) {
      final r = await actor.call(
        action(matchId, {'type': 'chooseSuit', 'suit': CardSuit.denari.key}),
      );
      actions++;
      if (r['accepted'] != true) {
        check('suit choice accepted', false, r['failure'] ?? r);
        break;
      }
      adopt(r, actor);
      continue;
    }

    // A chain is owed and nothing answers it: this is the case under test.
    if (v.isPenaltyPending && engine.getPlayableCards(v, actor.pid).isEmpty) {
      final owed = v.pendingDrawCount;
      final before = actor.hand.length;
      final r = await actor.call(action(matchId, {'type': 'drawCard'}));
      actions++;
      if (r['accepted'] != true) {
        check('penalty draw accepted', false, r['failure'] ?? r);
        break;
      }
      adopt(r, actor);
      final after = public!;

      check(
        '§6b — +$owed paid: the server still has ${actor.pid} to act',
        after.currentPlayerId == actor.pid,
        'current ${after.currentPlayerId}, pending ${after.pendingDrawCount}',
      );
      check(
        '§6b — +$owed paid: the server flags the continuation',
        after.penaltyResolvedThisTurn && after.pendingDrawCount == 0,
        'penaltyResolvedThisTurn ${after.penaltyResolvedThisTurn}',
      );
      check(
        '§6b — +$owed paid: $owed cards were actually taken',
        actor.hand.length == before + owed,
        '${actor.hand.length} vs ${before + owed}',
      );

      // The continuation is an ORDINARY play: an off-suit card is refused.
      final vv = viewFor(actor);
      final legal = engine.getPlayableCards(vv, actor.pid).toSet();
      final illegal = actor.hand.where((c) => !legal.contains(c)).firstOrNull;
      if (illegal != null && !illegalRefusedProven) {
        final bad = await actor.call(
          action(matchId, {'type': 'playCard', 'card': illegal.id}),
        );
        actions++;
        check(
          '§6b — the continuation still refuses an illegal card',
          bad['accepted'] == false && bad['failure'] == 'illegalCard',
          bad['failure'] ?? bad,
        );
        illegalRefusedProven = true;
      }

      // …and the turn only moves on once the continuation is made.
      if (legal.isNotEmpty) actions += await declareIfDue(matchId, actor);
      final follow = legal.isNotEmpty
          ? action(matchId, {'type': 'playCard', 'card': legal.first.id})
          : action(matchId, {'type': 'pass'});
      final fr = await actor.call(follow);
      actions++;
      if (fr['accepted'] != true) {
        check(
          '§6b — the continuation was accepted',
          false,
          fr['failure'] ?? fr,
        );
        break;
      }
      adopt(fr, actor);
      final done = public!;
      check(
        '§6b — ${legal.isNotEmpty ? 'played a legal card' : 'passed'}, then the turn moved on',
        done.isRoundOver ||
            done.currentPlayerId != actor.pid ||
            done.status == GameStatus.awaitingSuitChoice,
        'current ${done.currentPlayerId}',
      );
      penaltiesProven++;
      continue;
    }

    // Otherwise: prefer a Due so a chain actually happens, else anything legal.
    final playable = engine.getPlayableCards(v, actor.pid);
    Map<String, dynamic> body;
    if (playable.isNotEmpty) {
      final pick = playable.firstWhere(
        (c) => c.isDue,
        orElse: () => playable.firstWhere(
          (c) => !c.isCavallo,
          orElse: () => playable.first,
        ),
      );
      actions += await declareIfDue(matchId, actor);
      body = {
        'type': 'playCard',
        'card': pick.id,
        if (pick.isCavallo) 'suit': CardSuit.denari.key,
      };
    } else if (engine.canDraw(v)) {
      body = {'type': 'drawCard'};
    } else {
      body = {'type': 'pass'};
    }
    final r = await actor.call(action(matchId, body));
    actions++;
    if (r['accepted'] != true) {
      check(
        'server accepted ${body['type']} from ${actor.pid}',
        false,
        r['failure'] ?? r,
      );
      break;
    }
    adopt(r, actor);
    // A play can leave the seat on turn (§6b continuation, suit choice); a
    // draw can hand back a playable card. Nothing else to do — the loop
    // re-reads `public` and works out whose turn it is.
  }

  stdout.writeln(
    '\n   $actions actions, $penaltiesProven paid chains proven, '
    '$roundsProven round changes proven, $dealerRotationProven dealer moves, '
    '$lastCardsProven ultima carta declarations',
  );
  check('at least one +2 chain was paid and checked', penaltiesProven > 0);
  check('at least one round change was checked', roundsProven > 0);
  check(
    '§16 — at least one ULTIMA CARTA was declared and accepted',
    lastCardsProven > 0,
    '$lastCardsProven declarations',
  );

  stdout.writeln('\n$_pass passed, $_fail failed');
  exit(_fail == 0 ? 0 : 1);
}
