-- Session 6 (2026-08-30) — release hardening.
--
-- Findings from the final audit, each fixed here:
--
--  1. create_room / join_room accepted a caller still seated at a live match
--     (only enqueue_quick_match refused). Observed on the dev project: one
--     user seated at four stalled tables at once. Both now raise
--     already_in_match; join_room also tells "match_already_started" apart
--     from "room_not_found".
--  2. rooms.rules was any JSON object of any size and reached the engine
--     untouched. It is now validated key by key (type, range, ≤ 4 KB).
--  3. A refused action was logged with the card the actor tried to play,
--     and every seat may read match_actions — a hand card leaked through a
--     legitimate race. The card is no longer stored; refusals per seat are
--     capped so a hostile client cannot grow the log without bound.
--  4. srv_find_receipt is scoped to the caller.
--  5. A match ended by forfeit before a single round was completed awards
--     nothing (no win, XP, weekly points, streak or badge) — otherwise a
--     throw-away guest could hand out wins for three requests each.
--     Provisional policy; see docs/SECURITY.md.
--  6. handle_new_user could build a nickname ending in a space
--     (left(…,16)), which the trimmed-nickname check refused — and with it
--     the whole sign-up. Invisible/bidi characters are refused too.
--  7. enqueue_quick_match treated an old "matched" row as current even after
--     the caller had left that lobby by another door.
--  8. Cleanup: a match nobody has touched or looked at for an hour is
--     abandoned (was: 24 h), idempotency receipts of matches finished more
--     than 7 days ago are pruned, room names are cleaned of control chars.
--  9. Defence in depth: app_private functions are executable only by the
--     roles that need them (the schema already refused USAGE to clients).

-- ---------------------------------------------------------------- 1 + 2

create or replace function app_private.assert_not_in_match(p_user uuid)
returns void
language plpgsql
set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.match_players mp
    join public.matches m on m.id = mp.match_id
    where mp.user_id = p_user
      and m.status = 'in_progress'
      and mp.forfeited_at is null
  ) then
    raise exception 'already_in_match' using errcode = 'P0031';
  end if;
end;
$$;

-- Accepts exactly the keys GameRules.toJson() writes, with the types and
-- ranges the offline setup screen can express. The room's own timer wins
-- over any turnTimeLimitSeconds in the object.
create or replace function app_private.sanitize_room_rules(p_rules jsonb)
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  v_key   text;
  v_type  text;
  v_num   numeric;
  v_types constant jsonb := '{
    "minPlayers": "number", "maxPlayers": "number",
    "startingHandSize": "number", "allowVoluntaryDraw": "boolean",
    "playDrawnCardImmediately": "boolean", "restrictPlayToDrawnCard": "boolean",
    "stackDrawTwos": "boolean", "wildNineCanAlwaysPlay": "boolean",
    "nineBlockMode": "string", "nineBlockChangesSuit": "boolean",
    "exact101ResetsToZero": "boolean", "eliminateAbove101": "boolean",
    "targetScore": "number", "mustDrawBeforePassing": "boolean",
    "drawTwoPenalty": "number", "pendingPenaltyAppliesAfterWin": "boolean",
    "starterCardPolicy": "string", "roundStarterPolicy": "string",
    "initialDirection": "string", "turnTimeLimitSeconds": "any",
    "scoreValues": "object"
  }'::jsonb;
begin
  if p_rules is null or jsonb_typeof(p_rules) <> 'object' then
    raise exception 'invalid_rules' using errcode = '22023';
  end if;
  if pg_column_size(p_rules) > 4096 then
    raise exception 'invalid_rules' using errcode = '22023';
  end if;

  for v_key, v_type in
    select e.key, jsonb_typeof(e.value) from jsonb_each(p_rules) e
  loop
    if not (v_types ? v_key) then
      raise exception 'invalid_rules' using errcode = '22023';
    end if;
    if v_key = 'turnTimeLimitSeconds' then
      continue;
    end if;
    if v_type <> (v_types ->> v_key) then
      raise exception 'invalid_rules' using errcode = '22023';
    end if;
    if v_type = 'string' and char_length(p_rules ->> v_key) > 32 then
      raise exception 'invalid_rules' using errcode = '22023';
    end if;
    if v_type = 'number' then
      v_num := (p_rules ->> v_key)::numeric;
      if v_num <> trunc(v_num)
         or (v_key in ('minPlayers', 'maxPlayers') and v_num not between 2 and 4)
         or (v_key = 'startingHandSize' and v_num not between 3 and 10)
         or (v_key = 'targetScore' and v_num not between 11 and 999)
         or (v_key = 'drawTwoPenalty' and v_num not between 1 and 4) then
        raise exception 'invalid_rules' using errcode = '22023';
      end if;
    end if;
    if v_key = 'scoreValues' then
      if (select count(*) from jsonb_each(p_rules -> 'scoreValues')) > 10
         or exists (
           select 1 from jsonb_each(p_rules -> 'scoreValues') s
           where jsonb_typeof(s.value) <> 'number'
              or char_length(s.key) > 16
              or (s.value #>> '{}')::numeric not between 0 and 100
         ) then
        raise exception 'invalid_rules' using errcode = '22023';
      end if;
    end if;
  end loop;

  return p_rules - 'turnTimeLimitSeconds';
end;
$$;

create or replace function public.create_room(
  p_name               text,
  p_max_players        integer,
  p_is_private         boolean,
  p_turn_timer_seconds integer,
  p_rules              jsonb
)
returns public.rooms
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user  uuid := auth.uid();
  v_room  public.rooms;
  v_rules jsonb;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  if p_max_players is null or p_max_players not between 2 and 4 then
    raise exception 'invalid_player_count' using errcode = '22023';
  end if;
  if p_turn_timer_seconds is null or p_turn_timer_seconds not in (0, 15, 30, 60) then
    raise exception 'invalid_turn_timer' using errcode = '22023';
  end if;
  v_rules := app_private.sanitize_room_rules(p_rules);

  perform app_private.assert_not_in_match(v_user);
  perform app_private.leave_all_lobbies(v_user);

  insert into public.rooms
    (code, host_id, name, max_players, is_private, turn_timer_seconds, rules)
  values
    (app_private.generate_room_code(), v_user,
     left(btrim(regexp_replace(coalesce(p_name, ''), '[[:cntrl:]]', '', 'g')), 24),
     p_max_players, coalesce(p_is_private, true), p_turn_timer_seconds, v_rules)
  returning * into v_room;

  insert into public.room_players (room_id, user_id, seat, is_host, is_ready)
  values (v_room.id, v_user, 0, true, true);

  return v_room;
end;
$$;

create or replace function public.join_room(p_code text)
returns public.rooms
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_code text;
  v_room public.rooms;
  v_seat smallint;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  v_code := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  if v_code !~ '^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$' then
    raise exception 'invalid_code' using errcode = '22023';
  end if;

  select * into v_room from public.rooms where code = v_code for update;
  if not found or v_room.status in ('finished', 'cancelled') then
    raise exception 'room_not_found' using errcode = 'P0002';
  end if;

  if exists (select 1 from public.room_players
             where room_id = v_room.id and user_id = v_user) then
    return v_room;  -- already seated (a member re-entering a live table too)
  end if;

  if v_room.status <> 'lobby' then
    raise exception 'match_already_started' using errcode = 'P0004';
  end if;

  perform app_private.assert_not_in_match(v_user);
  perform app_private.leave_all_lobbies(v_user);

  select min(s) into v_seat
  from generate_series(0, v_room.max_players - 1) as s
  where s not in (select seat from public.room_players where room_id = v_room.id);

  if v_seat is null then
    raise exception 'room_full' using errcode = 'P0003';
  end if;

  insert into public.room_players (room_id, user_id, seat)
  values (v_room.id, v_user, v_seat);

  update public.rooms set last_activity_at = now() where id = v_room.id
  returning * into v_room;

  return v_room;
end;
$$;

-- ---------------------------------------------------------------- 3 + 4

create or replace function public.srv_record_rejection(
  p_match_id  uuid,
  p_user_id   uuid,
  p_action_id uuid,
  p_version   integer,
  p_action    jsonb,
  p_failure   text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_refusals integer;
begin
  -- The receipt is what makes a retry idempotent; keep it always.
  insert into public.match_action_receipts (match_id, action_id, user_id, accepted, failure, version)
  values (p_match_id, p_action_id, p_user_id, false, p_failure, p_version)
  on conflict (match_id, action_id) do nothing;

  -- The log line is for diagnostics: never the card (a refused card is
  -- still in the actor's hand, and every seat may read the log), and at
  -- most 100 refusals per seat per match.
  select count(*) into v_refusals
  from public.match_actions
  where match_id = p_match_id and actor_id = p_user_id and not accepted;
  if v_refusals >= 100 then
    return;
  end if;
  insert into public.match_actions (match_id, version, actor_id, action, accepted, failure)
  values (p_match_id, p_version, p_user_id, p_action - 'card' - 'chosenSuit' - 'suit', false, p_failure);
end;
$$;

drop function if exists public.srv_find_receipt(uuid, uuid);

create or replace function public.srv_find_receipt(p_match_id uuid, p_action_id uuid, p_user_id uuid)
returns jsonb
language sql
security definer
set search_path = ''
as $$
  select to_jsonb(r) from public.match_action_receipts r
  where r.match_id = p_match_id and r.action_id = p_action_id and r.user_id = p_user_id;
$$;

revoke all on function public.srv_find_receipt(uuid, uuid, uuid) from public, anon, authenticated;
grant execute on function public.srv_find_receipt(uuid, uuid, uuid) to service_role;

-- ---------------------------------------------------------------- 5

create or replace function app_private.settle_match(p_match_id uuid, p_state jsonb)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_winner_engine text := p_state ->> 'winnerId';
  v_winner_user   uuid;
  v_forfeited     boolean;
  v_rounds_played boolean;
begin
  with seats as (
    select mp.user_id, mp.engine_player_id,
           (pl ->> 'score')::integer as score,
           (pl ->> 'eliminated')::boolean as eliminated
    from public.match_players mp
    join jsonb_array_elements(p_state -> 'players') pl
      on pl ->> 'id' = mp.engine_player_id
    where mp.match_id = p_match_id
  ), ranked as (
    select user_id, score,
           row_number() over (
             order by (engine_player_id = v_winner_engine) desc, eliminated asc, score asc
           ) as placement
    from seats
  )
  update public.match_players mp
     set final_score = r.score,
         placement   = r.placement,
         is_winner   = (mp.engine_player_id = v_winner_engine)
    from ranked r
   where mp.match_id = p_match_id and mp.user_id = r.user_id;

  select user_id into v_winner_user
  from public.match_players
  where match_id = p_match_id and engine_player_id = v_winner_engine;

  update public.matches
     set status = 'finished',
         finished_at = coalesce(finished_at, now()),
         winner_id = v_winner_user,
         current_user_id = null,
         turn_deadline_at = null
   where id = p_match_id;

  update public.rooms r
     set status = 'finished', last_activity_at = now()
    from public.matches m
   where m.id = p_match_id and r.id = m.room_id and r.status = 'in_progress';

  perform app_private.record_round_result(p_match_id, p_state);

  -- A table that ended because somebody left before a single round was
  -- played is not a result: nothing is recorded for anybody. Otherwise a
  -- throw-away account could hand out wins on demand.
  select exists (select 1 from public.match_players
                 where match_id = p_match_id and forfeited_at is not null)
    into v_forfeited;
  select exists (select 1 from public.match_round_results
                 where match_id = p_match_id)
    into v_rounds_played;
  if v_forfeited and not v_rounds_played then
    return;
  end if;

  perform app_private.record_match_result(p_match_id, app_private.rating_deltas(p_match_id));
  perform app_private.evaluate_achievements(p_match_id, p_state);
end;
$$;

-- ---------------------------------------------------------------- 6

create or replace function app_private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_guest     boolean := coalesce(new.is_anonymous, false);
  v_base      text;
  v_avatar    text;
  v_candidate text;
  v_n         integer := 0;
begin
  v_base := nullif(btrim(regexp_replace(
              coalesce(new.raw_user_meta_data ->> 'nickname', ''),
              '[[:cntrl:]\u200B-\u200F\u202A-\u202E\u2060-\u206F\uFEFF]', '', 'g')), '');
  if v_base is null or char_length(v_base) < 3 then
    v_base := case when v_guest then 'Ospite' else 'Giocatore' end;
  end if;
  -- Cutting at 16 may leave a trailing space; the nickname check refuses it.
  v_base := btrim(left(v_base, 16));
  if char_length(v_base) < 3 then
    v_base := case when v_guest then 'Ospite' else 'Giocatore' end;
  end if;

  v_avatar := new.raw_user_meta_data ->> 'avatar_id';
  if v_avatar is null
     or not exists (select 1 from public.avatars a where a.id = v_avatar) then
    v_avatar := 'lucia';
  end if;

  if v_guest then
    -- Guests always carry a discriminator so two 'Ospite' never look alike.
    v_candidate := btrim(left(v_base, 11)) || '-'
                || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4));
  else
    v_candidate := v_base;
  end if;

  while exists (select 1 from public.profiles p
                where lower(p.nickname) = lower(v_candidate)) loop
    v_n := v_n + 1;
    if v_guest then
      v_candidate := btrim(left(v_base, 11)) || '-'
                  || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4));
    else
      v_candidate := btrim(left(v_base, 16 - char_length(v_n::text) - 1)) || '-' || v_n;
    end if;
  end loop;

  insert into public.profiles (id, nickname, avatar_id, is_guest, last_seen_at)
  values (new.id, v_candidate, v_avatar, v_guest, now());
  insert into public.player_stats (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

alter table public.profiles
  add constraint profiles_nickname_visible
  check (nickname !~ '[\u200B-\u200F\u202A-\u202E\u2060-\u206F\uFEFF]');

-- ---------------------------------------------------------------- 7

create or replace function public.enqueue_quick_match(p_player_count integer, p_turn_timer_seconds integer default 30)
returns public.matchmaking_queue
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user  uuid := auth.uid();
  v_row   public.matchmaking_queue;
  v_ids   uuid[];
  v_room  public.rooms;
  v_i     integer;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  if p_player_count is null or p_player_count not between 2 and 4 then
    raise exception 'invalid_player_count' using errcode = '22023';
  end if;
  if p_turn_timer_seconds is null or p_turn_timer_seconds not in (0, 15, 30, 60) then
    raise exception 'invalid_turn_timer' using errcode = '22023';
  end if;
  perform app_private.assert_not_in_match(v_user);

  perform pg_advisory_xact_lock(hashtext('gioco101.matchmaking'));

  select * into v_row from public.matchmaking_queue where user_id = v_user;
  if found and v_row.status = 'matched' and v_row.room_id is not null
     and exists (select 1 from public.rooms where id = v_row.room_id and status in ('lobby', 'in_progress'))
     and exists (select 1 from public.room_players where room_id = v_row.room_id and user_id = v_user) then
    return v_row;  -- already matched and still seated there: idempotent
  end if;

  insert into public.matchmaking_queue (user_id, player_count, turn_timer_seconds)
  values (v_user, p_player_count, p_turn_timer_seconds)
  on conflict (user_id) do update
    set player_count = excluded.player_count,
        turn_timer_seconds = excluded.turn_timer_seconds,
        status = 'waiting', room_id = null, last_seen_at = now(),
        enqueued_at = case when public.matchmaking_queue.status = 'waiting'
                           then public.matchmaking_queue.enqueued_at else now() end;

  -- Compatible = same table size and timer, seen in the last 90 s.
  select array_agg(user_id order by enqueued_at) into v_ids
  from (
    select user_id, enqueued_at from public.matchmaking_queue
    where status = 'waiting' and player_count = p_player_count
      and turn_timer_seconds = p_turn_timer_seconds
      and last_seen_at > now() - interval '90 seconds'
    order by enqueued_at
    limit p_player_count
  ) q;

  if coalesce(array_length(v_ids, 1), 0) < p_player_count then
    select * into v_row from public.matchmaking_queue where user_id = v_user;
    return v_row;
  end if;

  -- Enough players: build the room. The earliest waiter is host at seat 0.
  for v_i in 1..array_length(v_ids, 1) loop
    perform app_private.leave_all_lobbies(v_ids[v_i]);
  end loop;
  insert into public.rooms (code, host_id, name, max_players, is_private, turn_timer_seconds, rules, kind)
  values (app_private.generate_room_code(), v_ids[1], '', p_player_count, true,
          p_turn_timer_seconds, '{}'::jsonb, 'quick')
  returning * into v_room;
  for v_i in 1..array_length(v_ids, 1) loop
    insert into public.room_players (room_id, user_id, seat, is_host, is_ready)
    values (v_room.id, v_ids[v_i], v_i - 1, v_i = 1, true);
  end loop;
  update public.matchmaking_queue
     set status = 'matched', room_id = v_room.id, last_seen_at = now()
   where user_id = any (v_ids);

  select * into v_row from public.matchmaking_queue where user_id = v_user;
  return v_row;
end;
$$;

-- ---------------------------------------------------------------- 8

create or replace function app_private.expire_stale_matches(p_idle interval default interval '24 hours')
returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_count integer;
begin
  -- A table is abandoned when nothing has happened for p_idle, or when no
  -- seat has sent a heartbeat or an action for an hour: nobody is looking
  -- at it. Nothing is awarded; the room is closed so its members can play
  -- again.
  with expired as (
    update public.matches m
       set status = 'abandoned', finished_at = now(), current_user_id = null, turn_deadline_at = null
     where m.status = 'in_progress'
       and (
         m.last_action_at < now() - p_idle
         or (
           m.last_action_at < now() - interval '1 hour'
           and not exists (
             select 1 from public.match_players mp
             where mp.match_id = m.id and mp.last_seen_at > now() - interval '1 hour'
           )
         )
       )
    returning id, room_id
  ), rooms_done as (
    update public.rooms r set status = 'finished', last_activity_at = now()
      from expired e where r.id = e.room_id and r.status = 'in_progress'
    returning r.id
  )
  select count(*) into v_count from expired;

  delete from public.matchmaking_queue where last_seen_at < now() - interval '10 minutes';

  -- Receipts only matter while a retry is still possible.
  delete from public.match_action_receipts r
   using public.matches m
   where m.id = r.match_id
     and m.status in ('finished', 'abandoned')
     and m.finished_at < now() - interval '7 days';

  return v_count;
end;
$$;

-- ---------------------------------------------------------------- 9

revoke all on all functions in schema app_private from public, anon, authenticated;
alter default privileges in schema app_private
  revoke execute on functions from public, anon, authenticated;
