// Real end-to-end checks against a Supabase project, using the same Dart
// client the app uses. Pure Dart: no Flutter, run it with
//
//   SUPABASE_URL=... SUPABASE_PUBLISHABLE_KEY=... \
//   SMOKE_EMAIL_A=... SMOKE_PASSWORD_A=... SMOKE_EMAIL_B=... SMOKE_PASSWORD_B=... \
//   dart run tool/supabase_smoke.dart
//
// A and B must be two confirmed email accounts on the project. Every check
// prints PASS/FAIL and the process exits non-zero on any FAIL. Nothing here
// uses a privileged key: everything runs as the roles the app has.
import 'dart:io';

import 'package:supabase/supabase.dart';

int failures = 0;

void check(String name, bool ok, [Object? detail]) {
  stdout.writeln(
    '${ok ? 'PASS' : 'FAIL'}  $name${detail == null ? '' : '  ($detail)'}',
  );
  if (!ok) failures++;
}

Future<T?> expectDenied<T>(String name, Future<T> Function() call) async {
  try {
    final result = await call();
    // PostgREST returns an empty result for rows RLS filtered out; that
    // counts as denied for reads/updates that must touch nothing.
    final empty =
        result == null ||
        (result is List && result.isEmpty) ||
        (result is Map && result.isEmpty);
    check(name, empty, empty ? 'no rows' : 'UNEXPECTED SUCCESS: $result');
    return result;
  } on PostgrestException catch (e) {
    check(name, true, 'refused ${e.code}: ${e.message}');
    return null;
  }
}

Future<void> main() async {
  final env = Platform.environment;
  final url = env['SUPABASE_URL'] ?? '';
  final key = env['SUPABASE_PUBLISHABLE_KEY'] ?? '';
  if (url.isEmpty || key.isEmpty) {
    stderr.writeln('SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY are required');
    exit(2);
  }
  final a = SupabaseClient(url, key);
  final b = SupabaseClient(url, key);
  final anon = SupabaseClient(url, key);

  // --- anon key without a session ------------------------------------------
  await expectDenied(
    'anon cannot read profiles',
    () => anon.from('profiles').select(),
  );
  await expectDenied(
    'anon cannot call leaderboard',
    () => anon.rpc<dynamic>('leaderboard', params: {'p_scope': 'all_time'}),
  );

  // --- anonymous (guest) sign-in --------------------------------------------
  String? guestId;
  try {
    final res = await anon.auth.signInAnonymously();
    guestId = res.user?.id;
    check(
      'guest sign-in creates an anonymous user',
      res.user?.isAnonymous == true,
      guestId,
    );
  } on AuthException catch (e) {
    check(
      'guest sign-in creates an anonymous user',
      false,
      '${e.code}: ${e.message}',
    );
  }
  if (guestId != null) {
    final row = await anon
        .from('profiles')
        .select()
        .eq('id', guestId)
        .maybeSingle();
    check(
      'guest profile was created by the trigger',
      row != null && row['is_guest'] == true,
      row?['nickname'],
    );
    await expectDenied(
      'guest cannot claim the daily reward',
      () => anon.rpc<dynamic>('claim_daily_reward'),
    );
    await anon.auth.signOut();
  }

  // --- two permanent users --------------------------------------------------
  final emailA = env['SMOKE_EMAIL_A'] ?? '';
  final emailB = env['SMOKE_EMAIL_B'] ?? '';
  if (emailA.isEmpty || emailB.isEmpty) {
    stdout.writeln('SKIP  two-user RLS matrix (SMOKE_EMAIL_A/B not set)');
    exit(failures == 0 ? 0 : 1);
  }
  final sessA = await a.auth.signInWithPassword(
    email: emailA,
    password: env['SMOKE_PASSWORD_A'] ?? '',
  );
  final sessB = await b.auth.signInWithPassword(
    email: emailB,
    password: env['SMOKE_PASSWORD_B'] ?? '',
  );
  final idA = sessA.user!.id;
  final idB = sessB.user!.id;
  check('A and B signed in', idA != idB);

  final profileA = await a.from('profiles').select().eq('id', idA).single();
  check('A reads own profile', profileA['id'] == idA, profileA['nickname']);
  final profileB = await a
      .from('profiles')
      .select('nickname, avatar_id, rating, wins')
      .eq('id', idB)
      .single();
  check(
    'A reads B public fields (nickname, avatar, rating)',
    profileB['nickname'] != null,
  );

  // Edits
  final newNick = 'Smoke-${DateTime.now().millisecondsSinceEpoch % 100000}';
  final updated = await a
      .from('profiles')
      .update({'nickname': newNick, 'avatar_id': 'marco'})
      .eq('id', idA)
      .select()
      .single();
  check(
    'A edits own nickname/avatar',
    updated['nickname'] == newNick && updated['avatar_id'] == 'marco',
  );
  await expectDenied(
    'A cannot edit B profile',
    () => a
        .from('profiles')
        .update({'nickname': 'Hacked'})
        .eq('id', idB)
        .select(),
  );
  await expectDenied(
    'A cannot write own rating',
    () => a.from('profiles').update({'rating': 9999}).eq('id', idA).select(),
  );
  await expectDenied(
    'A cannot grant self XP',
    () => a.from('profiles').update({'xp': 9999}).eq('id', idA).select(),
  );
  await expectDenied(
    'A cannot mark self winner (wins)',
    () => a.from('profiles').update({'wins': 99}).eq('id', idA).select(),
  );
  await expectDenied(
    'A cannot pick a non-whitelisted avatar',
    () => a
        .from('profiles')
        .update({'avatar_id': 'not-an-avatar'})
        .eq('id', idA)
        .select(),
  );
  await expectDenied(
    'A cannot insert a profile',
    () => a.from('profiles').insert({'id': idA, 'nickname': 'X'}).select(),
  );
  await expectDenied(
    'A cannot write player_stats',
    () => a
        .from('player_stats')
        .update({'coins': 1000})
        .eq('user_id', idA)
        .select(),
  );
  await expectDenied(
    'A cannot grant self an achievement',
    () => a.from('user_achievements').insert({
      'user_id': idA,
      'achievement_id': 'prima_vittoria',
    }).select(),
  );
  await expectDenied(
    'A cannot insert a match result',
    () => a.from('matches').insert({
      'rules': {},
      'player_count': 2,
      'status': 'finished',
      'winner_id': idA,
    }).select(),
  );
  await expectDenied(
    'A cannot insert weekly points',
    () => a.from('weekly_points').insert({
      'user_id': idA,
      'week_start': '2026-08-24',
      'points': 999,
    }).select(),
  );

  // Rooms
  final roomRow = await a.rpc<Map<String, dynamic>>(
    'create_room',
    params: {
      'p_name': 'Smoke',
      'p_max_players': 2,
      'p_is_private': true,
      'p_turn_timer_seconds': 30,
      'p_rules': {},
    },
  );
  final roomId = roomRow['id'] as String;
  final code = roomRow['code'] as String;
  check('A creates a private room', code.length == 6, code);
  await expectDenied(
    'B cannot see the private room before joining',
    () => b.from('rooms').select().eq('id', roomId),
  );
  await expectDenied(
    'B cannot see its seats before joining',
    () => b.from('room_players').select().eq('room_id', roomId),
  );
  final joined = await b.rpc<Map<String, dynamic>>(
    'join_room',
    params: {'p_code': code},
  );
  check('B joins by code', joined['id'] == roomId);
  final seats = await b.from('room_players').select().eq('room_id', roomId);
  check('B now sees both seats', seats.length == 2, seats.length);
  try {
    await b.rpc<dynamic>('join_room', params: {'p_code': 'ZZZZZZ'});
    check('joining a missing code is refused', false);
  } on PostgrestException catch (e) {
    check(
      'joining a missing code is refused',
      e.message.contains('room_not_found'),
      e.message,
    );
  }
  await expectDenied(
    'B cannot mutate room_players directly',
    () => b
        .from('room_players')
        .update({'is_host': true})
        .eq('room_id', roomId)
        .eq('user_id', idB)
        .select(),
  );
  await expectDenied(
    'B cannot mutate rooms directly',
    () => b
        .from('rooms')
        .update({'status': 'in_progress'})
        .eq('id', roomId)
        .select(),
  );
  await b.rpc<void>('leave_room', params: {'p_room_id': roomId});
  await expectDenied(
    'after leaving, B no longer sees the room',
    () => b.from('rooms').select().eq('id', roomId),
  );
  await a.rpc<void>('leave_room', params: {'p_room_id': roomId});

  // Private match state: only your own row is ever visible.
  final privA = await a.from('match_private_state').select();
  check(
    'A sees no private hands it does not own',
    privA.every((r) => r['user_id'] == idA),
    privA.length,
  );
  await expectDenied(
    'A cannot write private state',
    () => a.from('match_private_state').insert({
      'match_id': '00000000-0000-0000-0000-000000000000',
      'user_id': idA,
      'hand': [],
    }).select(),
  );

  // Rewards + leaderboard
  final status = await a.rpc<List<dynamic>>('my_daily_reward_status');
  check('A reads daily reward status', status.length == 1, status.first);
  final board = await a.rpc<List<dynamic>>(
    'leaderboard',
    params: {'p_scope': 'all_time', 'p_limit': 10},
  );
  check(
    'leaderboard all_time answers',
    board.isNotEmpty,
    '${board.length} rows',
  );
  final weekly = await a.rpc<List<dynamic>>(
    'leaderboard',
    params: {'p_scope': 'weekly', 'p_limit': 10},
  );
  check(
    'leaderboard weekly answers (may be empty)',
    true,
    '${weekly.length} rows',
  );

  await a.auth.signOut();
  await b.auth.signOut();
  stdout.writeln(failures == 0 ? '\nALL PASS' : '\n$failures FAILED');
  exit(failures == 0 ? 0 : 1);
}
