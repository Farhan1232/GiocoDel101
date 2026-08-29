-- =============================================================================
-- Gioco del 101 — Session 4, migration 6: real server-authoritative online play.
--
-- What this adds, and why each piece is where it is:
--
--   * The GAME RULES stay in one place: the Dart GameEngine, compiled to
--     JavaScript and executed by the `match` Edge Function. Postgres never
--     re-derives a rule. It owns everything around the engine instead:
--     identity, membership, seats, versions, idempotency, the turn clock,
--     the private-hand split, the result ledger and every fan-out.
--
--   * Every state change is ONE transaction (`srv_commit_action`,
--     `srv_commit_match`) that locks the engine row `FOR UPDATE`, checks the
--     version the caller computed against, writes the action log, publishes
--     the redacted/private views and stamps the clock. Two racing actions
--     serialise on that lock; the loser sees `stale_version` and is refused.
--
--   * `srv_*` functions are callable ONLY by `service_role` (the Edge
--     Function). Clients keep exactly the surface Session 3 gave them plus a
--     few validating RPCs (queue, heartbeat, snapshot, reactions).
--
--   * Realtime: `postgres_changes` on the tables below (RLS applies per
--     subscriber), one PRIVATE channel per match (`match:<uuid>`) for
--     presence and server-sent reactions. Broadcast is never the source of
--     truth — every event is also a row a client can re-read.
-- =============================================================================

-- --- Rooms: quick-match rooms ---------------------------------------------
alter table public.rooms
  add column kind text not null default 'private'
    check (kind in ('private', 'quick'));
comment on column public.rooms.kind is
  'private = created by a host with a code; quick = assembled by the matchmaking queue (any member may start).';

-- --- Matches: the server-owned turn clock and bookkeeping -------------------
alter table public.matches
  add column current_user_id    uuid references public.profiles (id) on delete set null,
  add column turn_started_at    timestamptz,
  add column turn_deadline_at   timestamptz,
  add column turn_timer_seconds smallint not null default 0
    check (turn_timer_seconds in (0, 15, 30, 60)),
  add column last_action_at     timestamptz not null default now(),
  add column abandoned_by       uuid references public.profiles (id) on delete set null,
  add column rematch_of         uuid references public.matches (id) on delete set null;
create index matches_current_user_idx on public.matches (current_user_id);
create index matches_abandoned_by_idx on public.matches (abandoned_by);
create index matches_rematch_of_idx   on public.matches (rematch_of);
create index matches_stale_idx on public.matches (last_action_at) where status = 'in_progress';
comment on column public.matches.turn_deadline_at is
  'Server-owned. Set from the engine state (turn timer) or, between rounds, now()+30s. Clients only display it.';

alter table public.match_players
  add column consecutive_timeouts smallint not null default 0,
  add column forfeited_at         timestamptz,
  add column rematch_requested_at timestamptz,
  add column last_reaction_at     timestamptz;

-- The owner of the current turn may also be told which card they just drew
-- (GAME_SPEC §8): it lives in the private row, never in the public state.
alter table public.match_private_state add column drawn_card text;

-- --- Idempotency: one receipt per (match, action id) ------------------------
create table public.match_action_receipts (
  match_id   uuid not null references public.matches (id) on delete cascade,
  action_id  uuid not null,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  accepted   boolean not null,
  failure    text,
  version    integer not null,   -- version after the action (accepted) or the one it was judged against
  created_at timestamptz not null default now(),
  primary key (match_id, action_id)
);
create index match_action_receipts_user_idx on public.match_action_receipts (user_id);
comment on table public.match_action_receipts is
  'Every client action carries a UUID. A retry with the same id returns this row instead of being applied twice.';
alter table public.match_action_receipts enable row level security;
create policy "match_action_receipts: your own receipts"
  on public.match_action_receipts for select to authenticated
  using ((select auth.uid()) = user_id);
grant select on public.match_action_receipts to authenticated;

-- --- Matchmaking queue -------------------------------------------------------
create table public.matchmaking_queue (
  user_id            uuid primary key references public.profiles (id) on delete cascade,
  player_count       smallint not null check (player_count between 2 and 4),
  turn_timer_seconds smallint not null default 30 check (turn_timer_seconds in (0, 15, 30, 60)),
  status             text not null default 'waiting' check (status in ('waiting', 'matched')),
  room_id            uuid references public.rooms (id) on delete set null,
  enqueued_at        timestamptz not null default now(),
  last_seen_at       timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index matchmaking_queue_match_idx
  on public.matchmaking_queue (player_count, turn_timer_seconds, enqueued_at)
  where status = 'waiting';
create index matchmaking_queue_room_idx on public.matchmaking_queue (room_id);
comment on table public.matchmaking_queue is
  'One row per waiting player (PK = user). Matching runs under an advisory lock inside enqueue_quick_match; nobody is ever invented.';
create trigger matchmaking_queue_set_updated_at
  before update on public.matchmaking_queue
  for each row execute function app_private.set_updated_at();
alter table public.matchmaking_queue enable row level security;
create policy "matchmaking_queue: your own entry"
  on public.matchmaking_queue for select to authenticated
  using ((select auth.uid()) = user_id);
grant select on public.matchmaking_queue to authenticated;

-- --- Preset reactions (the only "chat" that exists) --------------------------
create table public.reaction_presets (
  key        text primary key,
  sort_order smallint not null
);
insert into public.reaction_presets (key, sort_order) values
  ('ciao', 1), ('bravo', 2), ('bella_mossa', 3), ('mamma_mia', 4),
  ('ahahaha', 5), ('che_fortuna', 6), ('rivincita', 7), ('gg', 8);
alter table public.reaction_presets enable row level security;
create policy "reaction_presets: readable" on public.reaction_presets
  for select to authenticated using (true);
grant select on public.reaction_presets to authenticated;

-- --- Realtime: tables clients subscribe to (RLS applies per subscriber) -----
alter table public.rooms               replica identity full;
alter table public.room_players        replica identity full;
alter table public.matches             replica identity full;
alter table public.match_public_state  replica identity full;
alter table public.match_private_state replica identity full;
alter table public.matchmaking_queue   replica identity full;
alter publication supabase_realtime add table
  public.rooms, public.room_players, public.matches,
  public.match_public_state, public.match_private_state,
  public.matchmaking_queue;

-- --- Realtime: the private per-match channel `match:<uuid>` -----------------
-- Members may join (receive broadcast + presence) and track presence. Nobody
-- may broadcast from a client: the only broadcast producer is
-- public.send_reaction() below, via realtime.send() from the database.
create or replace function app_private.match_id_of_topic(p_topic text)
returns uuid
language sql
immutable
set search_path = ''
as $$
  select case
    when p_topic ~ '^match:[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    then substr(p_topic, 7)::uuid
    else null
  end;
$$;

create policy "match channel: members receive broadcast and presence"
  on realtime.messages for select to authenticated
  using (
    realtime.messages.extension in ('broadcast', 'presence')
    and public.is_match_member(app_private.match_id_of_topic((select realtime.topic())))
  );
create policy "match channel: members track presence only"
  on realtime.messages for insert to authenticated
  with check (
    realtime.messages.extension = 'presence'
    and public.is_match_member(app_private.match_id_of_topic((select realtime.topic())))
  );

-- --- publish_match_state: now also the owner's drawn card -------------------
create or replace function app_private.publish_match_state(p_match_id uuid, p_state jsonb)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_version integer := coalesce((p_state ->> 'version')::integer, 0);
  v_status  text    := p_state ->> 'status';
  v_current text    := 'p' || coalesce((p_state ->> 'currentSeat')::integer, 0)::text;
begin
  insert into app_private.match_engine_state (match_id, version, state)
  values (p_match_id, v_version, p_state)
  on conflict (match_id) do update
    set version = excluded.version, state = excluded.state, updated_at = now();

  insert into public.match_public_state (match_id, version, state)
  values (p_match_id, v_version, app_private.redact_game_state(p_state))
  on conflict (match_id) do update
    set version = excluded.version, state = excluded.state, updated_at = now();

  insert into public.match_private_state (match_id, user_id, version, hand, drawn_card)
  select p_match_id, mp.user_id, v_version,
         app_private.hand_of(p_state, mp.engine_player_id),
         case when mp.engine_player_id = v_current then p_state ->> 'drawnCard' end
  from public.match_players mp
  where mp.match_id = p_match_id
  on conflict (match_id, user_id) do update
    set version = excluded.version, hand = excluded.hand,
        drawn_card = excluded.drawn_card, updated_at = now();

  if v_status = 'finished' then
    update public.matches
       set status = 'finished', finished_at = coalesce(finished_at, now())
     where id = p_match_id and status = 'in_progress';
  end if;
end;
$$;

-- --- Rating hook -------------------------------------------------------------
-- GAME_SPEC §12b: no online points formula has been confirmed by the client.
-- record_match_result applies whatever deltas it is given; this function is
-- the single place a formula will live. Until then every delta is 0 and
-- profiles.rating does not move — nothing is invented.
create or replace function app_private.rating_deltas(p_match_id uuid)
returns jsonb
language sql
stable
set search_path = ''
as $$
  select coalesce(jsonb_object_agg(mp.user_id::text, 0), '{}'::jsonb)
  from public.match_players mp
  where mp.match_id = p_match_id;
$$;

-- --- Result ledger: placements, then the shared progression routine ---------
create or replace function app_private.settle_match(p_match_id uuid, p_state jsonb)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_winner_engine text := p_state ->> 'winnerId';
  v_winner_user   uuid;
begin
  -- Scores/eliminations come from the engine state; placement is by score
  -- ascending (fewer penalty points is better), winner first.
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

  perform app_private.record_match_result(p_match_id, app_private.rating_deltas(p_match_id));
end;
$$;

-- --- Clock helper --------------------------------------------------------------
create or replace function app_private.epoch_ms_to_ts(p_ms jsonb)
returns timestamptz
language sql
immutable
set search_path = ''
as $$
  select case when p_ms is null or jsonb_typeof(p_ms) <> 'number' then null
              else to_timestamp((p_ms::text)::numeric / 1000.0) end;
$$;

-- =============================================================================
-- SERVER-ONLY API (service_role): what the `match` Edge Function calls.
-- =============================================================================

-- Everything the engine host needs to judge an action: the authoritative
-- state, the caller's seat, the clock, and the other seats' presence (for
-- the abandonment policy).
create or replace function public.srv_load_match(p_match_id uuid, p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_match  public.matches;
  v_me     public.match_players;
  v_state  jsonb;
  v_ver    integer;
begin
  select * into v_match from public.matches where id = p_match_id;
  if not found then
    raise exception 'match_not_found' using errcode = 'P0002';
  end if;
  select * into v_me from public.match_players
   where match_id = p_match_id and user_id = p_user_id;
  if not found then
    raise exception 'not_a_participant' using errcode = '42501';
  end if;
  select state, version into v_state, v_ver
    from app_private.match_engine_state where match_id = p_match_id;

  return jsonb_build_object(
    'match', jsonb_build_object(
      'id', v_match.id,
      'roomId', v_match.room_id,
      'status', v_match.status,
      'version', v_ver,
      'currentUserId', v_match.current_user_id,
      'turnTimerSeconds', v_match.turn_timer_seconds,
      'turnStartedAt', v_match.turn_started_at,
      'turnDeadlineAt', v_match.turn_deadline_at,
      'lastActionAt', v_match.last_action_at,
      'now', now()
    ),
    'state', v_state,
    'me', jsonb_build_object(
      'userId', v_me.user_id, 'seat', v_me.seat,
      'enginePlayerId', v_me.engine_player_id,
      'forfeitedAt', v_me.forfeited_at
    ),
    'players', (
      select jsonb_agg(jsonb_build_object(
        'userId', mp.user_id, 'seat', mp.seat, 'enginePlayerId', mp.engine_player_id,
        'connection', mp.connection, 'lastSeenAt', mp.last_seen_at,
        'consecutiveTimeouts', mp.consecutive_timeouts, 'forfeitedAt', mp.forfeited_at,
        'rematchRequestedAt', mp.rematch_requested_at
      ) order by mp.seat)
      from public.match_players mp where mp.match_id = p_match_id
    )
  );
end;
$$;

create or replace function public.srv_find_receipt(p_match_id uuid, p_action_id uuid)
returns jsonb
language sql
security definer
set search_path = ''
as $$
  select to_jsonb(r) from public.match_action_receipts r
  where r.match_id = p_match_id and r.action_id = p_action_id;
$$;

-- Records a REFUSED client action (no state change) and its receipt, so a
-- retried duplicate gets the same answer.
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
begin
  insert into public.match_actions (match_id, version, actor_id, action, accepted, failure)
  values (p_match_id, p_version, p_user_id, p_action, false, p_failure);
  insert into public.match_action_receipts (match_id, action_id, user_id, accepted, failure, version)
  values (p_match_id, p_action_id, p_user_id, false, p_failure, p_version)
  on conflict (match_id, action_id) do nothing;
end;
$$;

-- THE commit. One transaction: lock, version check, log, publish, clock,
-- receipt, settlement. p_kind: 'action' (a player's own move), 'timeout'
-- (the server moved for p_actor), 'forfeit' (p_actor gave up or was
-- forfeited), 'system' (next round dealt by the server).
create or replace function public.srv_commit_action(
  p_match_id     uuid,
  p_actor        uuid,
  p_action_id    uuid,
  p_base_version integer,
  p_new_state    jsonb,
  p_actions      jsonb,      -- array of the GameAction json applied, in order
  p_kind         text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_current_version integer;
  v_new_version     integer := (p_new_state ->> 'version')::integer;
  v_status          text    := p_new_state ->> 'status';
  v_seat            integer := coalesce((p_new_state ->> 'currentSeat')::integer, 0);
  v_current_user    uuid;
  v_deadline        timestamptz;
  v_started         timestamptz;
  v_action          jsonb;
  v_receipt         public.match_action_receipts;
  v_log_version     integer := p_base_version;
begin
  if p_kind not in ('action', 'timeout', 'forfeit', 'system') then
    raise exception 'invalid_kind' using errcode = '22023';
  end if;

  -- Serialise on the engine row; every concurrent commit queues here.
  select version into v_current_version
    from app_private.match_engine_state
   where match_id = p_match_id
   for update;
  if not found then
    raise exception 'match_not_found' using errcode = 'P0002';
  end if;

  if p_action_id is not null then
    select * into v_receipt from public.match_action_receipts
     where match_id = p_match_id and action_id = p_action_id;
    if found then
      return jsonb_build_object('duplicate', true, 'accepted', v_receipt.accepted,
                                'failure', v_receipt.failure, 'version', v_receipt.version);
    end if;
  end if;

  if v_current_version <> p_base_version then
    raise exception 'stale_version' using errcode = 'P0010',
      detail = format('expected %s, have %s', p_base_version, v_current_version);
  end if;
  if v_new_version <> p_base_version + jsonb_array_length(p_actions) then
    raise exception 'version_mismatch' using errcode = 'P0011';
  end if;
  if not exists (select 1 from public.matches where id = p_match_id and status = 'in_progress') then
    raise exception 'match_not_in_progress' using errcode = 'P0012';
  end if;

  for v_action in select * from jsonb_array_elements(p_actions) loop
    insert into public.match_actions (match_id, version, actor_id, action, accepted)
    values (p_match_id, v_log_version,
            case when p_kind = 'action' then p_actor else null end,
            v_action || jsonb_build_object('kind', p_kind), true);
    v_log_version := v_log_version + 1;
  end loop;

  perform app_private.publish_match_state(p_match_id, p_new_state);

  select user_id into v_current_user from public.match_players
   where match_id = p_match_id and engine_player_id = 'p' || v_seat::text;

  v_started  := app_private.epoch_ms_to_ts(p_new_state -> 'turnStartedAt');
  v_deadline := app_private.epoch_ms_to_ts(p_new_state -> 'turnDeadlineAt');
  if v_status = 'roundOver' then
    -- Between rounds the engine has no turn to time; the server gives the
    -- table 30 s to press "next round" before it deals itself.
    v_deadline := now() + interval '30 seconds';
    v_started  := now();
  elsif v_status in ('awaitingAction', 'awaitingSuitChoice') and v_deadline is null
        and exists (select 1 from public.matches where id = p_match_id and turn_timer_seconds > 0) then
    -- Defensive: a timed match must always carry a deadline.
    select now() + make_interval(secs => turn_timer_seconds) into v_deadline
      from public.matches where id = p_match_id;
    v_started := now();
  end if;

  update public.matches
     set current_user_id  = case when v_status = 'finished' then null else v_current_user end,
         turn_started_at  = v_started,
         turn_deadline_at = case when v_status = 'finished' then null else v_deadline end,
         last_action_at   = now()
   where id = p_match_id;

  if p_kind = 'action' and p_actor is not null then
    update public.match_players set consecutive_timeouts = 0, last_seen_at = now(), connection = 'online'
     where match_id = p_match_id and user_id = p_actor;
  elsif p_kind = 'timeout' and p_actor is not null then
    update public.match_players set consecutive_timeouts = consecutive_timeouts + 1
     where match_id = p_match_id and user_id = p_actor;
  elsif p_kind = 'forfeit' and p_actor is not null then
    update public.match_players set forfeited_at = coalesce(forfeited_at, now())
     where match_id = p_match_id and user_id = p_actor;
    update public.matches set abandoned_by = coalesce(abandoned_by, p_actor) where id = p_match_id;
  end if;

  if p_action_id is not null and p_actor is not null then
    insert into public.match_action_receipts (match_id, action_id, user_id, accepted, version)
    values (p_match_id, p_action_id, p_actor, true, v_new_version);
  end if;

  update public.rooms r set last_activity_at = now()
    from public.matches m where m.id = p_match_id and r.id = m.room_id;

  if v_status = 'finished' then
    perform app_private.settle_match(p_match_id, p_new_state);
  end if;

  return jsonb_build_object('duplicate', false, 'accepted', true, 'version', v_new_version,
                            'status', v_status, 'currentUserId', v_current_user,
                            'turnDeadlineAt', v_deadline);
end;
$$;

-- What the engine host needs to deal a match for a room (start or rematch).
create or replace function public.srv_room_for_deal(p_room_id uuid, p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_room public.rooms;
begin
  select * into v_room from public.rooms where id = p_room_id;
  if not found then
    raise exception 'room_not_found' using errcode = 'P0002';
  end if;
  if not exists (select 1 from public.room_players where room_id = p_room_id and user_id = p_user_id) then
    raise exception 'not_a_member' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'room', jsonb_build_object(
      'id', v_room.id, 'code', v_room.code, 'hostId', v_room.host_id, 'kind', v_room.kind,
      'status', v_room.status, 'matchId', v_room.match_id, 'maxPlayers', v_room.max_players,
      'turnTimerSeconds', v_room.turn_timer_seconds, 'rules', v_room.rules
    ),
    'seats', (
      select jsonb_agg(jsonb_build_object(
        'userId', rp.user_id, 'seat', rp.seat, 'isHost', rp.is_host, 'isReady', rp.is_ready,
        'nickname', p.nickname, 'avatarId', p.avatar_id
      ) order by rp.seat)
      from public.room_players rp join public.profiles p on p.id = rp.user_id
      where rp.room_id = p_room_id
    ),
    'now', now()
  );
end;
$$;

-- Creates the match from a dealt engine state, atomically, once.
-- p_expected_status: 'lobby' for a first start, 'finished' for a rematch.
create or replace function public.srv_commit_match(
  p_room_id         uuid,
  p_user_id         uuid,
  p_expected_status text,
  p_expected_match  uuid,
  p_state           jsonb,
  p_seats           jsonb,   -- [{userId, seat, enginePlayerId}] the state was dealt for
  p_rematch_of      uuid,
  p_match_id        uuid     -- chosen by the caller so GameState.gameId == matches.id
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_room    public.rooms;
  v_match   public.matches;
  v_seat    jsonb;
  v_current uuid;
  v_seat_ix integer := coalesce((p_state ->> 'currentSeat')::integer, 0);
begin
  select * into v_room from public.rooms where id = p_room_id for update;
  if not found then
    raise exception 'room_not_found' using errcode = 'P0002';
  end if;

  -- Idempotent: a second "start" (double tap, retry, two members racing)
  -- returns the match the first one created.
  if v_room.status = 'in_progress' and v_room.match_id is not null
     and v_room.match_id is distinct from p_expected_match then
    return jsonb_build_object('matchId', v_room.match_id, 'created', false);
  end if;
  if v_room.status::text <> p_expected_status or v_room.match_id is distinct from p_expected_match then
    raise exception 'room_not_startable' using errcode = 'P0020',
      detail = format('status=%s match=%s', v_room.status, v_room.match_id);
  end if;

  -- The seats the engine dealt for must be exactly the seats in the room now.
  if (select count(*) from public.room_players where room_id = p_room_id)
     <> jsonb_array_length(p_seats)
     or exists (
       select 1 from jsonb_array_elements(p_seats) s
       where not exists (
         select 1 from public.room_players rp
         where rp.room_id = p_room_id and rp.user_id = (s ->> 'userId')::uuid
           and rp.seat = (s ->> 'seat')::integer
       )
     ) then
    raise exception 'room_changed' using errcode = 'P0021';
  end if;
  if jsonb_array_length(p_seats) <> v_room.max_players then
    raise exception 'room_not_full' using errcode = 'P0022';
  end if;
  if p_expected_status = 'lobby' and v_room.kind = 'private' and v_room.host_id <> p_user_id then
    raise exception 'not_the_host' using errcode = '42501';
  end if;
  if exists (select 1 from public.room_players
             where room_id = p_room_id and not is_ready and not is_host) then
    raise exception 'not_everyone_ready' using errcode = 'P0023';
  end if;

  if p_match_id is null or (p_state ->> 'gameId') is distinct from p_match_id::text then
    raise exception 'match_id_mismatch' using errcode = '22023';
  end if;
  insert into public.matches (id, room_id, rules, player_count, turn_timer_seconds, rematch_of)
  values (p_match_id, p_room_id, coalesce(p_state -> 'rules', '{}'::jsonb), jsonb_array_length(p_seats),
          v_room.turn_timer_seconds, p_rematch_of)
  returning * into v_match;

  for v_seat in select * from jsonb_array_elements(p_seats) loop
    insert into public.match_players (match_id, user_id, seat, engine_player_id)
    values (v_match.id, (v_seat ->> 'userId')::uuid, (v_seat ->> 'seat')::integer,
            v_seat ->> 'enginePlayerId');
  end loop;

  perform app_private.publish_match_state(v_match.id, p_state);

  select user_id into v_current from public.match_players
   where match_id = v_match.id and engine_player_id = 'p' || v_seat_ix::text;

  update public.matches
     set current_user_id  = v_current,
         turn_started_at  = coalesce(app_private.epoch_ms_to_ts(p_state -> 'turnStartedAt'), now()),
         turn_deadline_at = app_private.epoch_ms_to_ts(p_state -> 'turnDeadlineAt'),
         last_action_at   = now()
   where id = v_match.id;

  update public.rooms
     set status = 'in_progress', match_id = v_match.id, last_activity_at = now()
   where id = p_room_id;

  update public.room_players set is_ready = true where room_id = p_room_id;
  delete from public.matchmaking_queue where room_id = p_room_id;

  return jsonb_build_object('matchId', v_match.id, 'created', true);
end;
$$;

-- A participant asks for a rematch. Returns the vote count; 'ready' when
-- every seat still in the room has asked.
create or replace function public.srv_rematch_vote(p_match_id uuid, p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_match  public.matches;
  v_votes  integer;
  v_needed integer;
begin
  select * into v_match from public.matches where id = p_match_id for update;
  if not found then
    raise exception 'match_not_found' using errcode = 'P0002';
  end if;
  if v_match.status <> 'finished' then
    raise exception 'match_not_finished' using errcode = 'P0001';
  end if;
  if v_match.room_id is null
     or not exists (select 1 from public.room_players where room_id = v_match.room_id and user_id = p_user_id) then
    raise exception 'not_a_member' using errcode = '42501';
  end if;
  update public.match_players set rematch_requested_at = coalesce(rematch_requested_at, now())
   where match_id = p_match_id and user_id = p_user_id;
  if not found then
    raise exception 'not_a_participant' using errcode = '42501';
  end if;

  select count(*) into v_needed from public.room_players where room_id = v_match.room_id;
  select count(*) into v_votes
    from public.room_players rp
    join public.match_players mp on mp.match_id = p_match_id and mp.user_id = rp.user_id
   where rp.room_id = v_match.room_id and mp.rematch_requested_at is not null;

  update public.rooms set last_activity_at = now() where id = v_match.room_id;

  return jsonb_build_object('roomId', v_match.room_id, 'votes', v_votes, 'needed', v_needed,
                            'ready', v_needed >= 2 and v_votes = v_needed);
end;
$$;

-- A seat leaves a finished/lobby room; blocked during a live match (forfeit
-- through the Edge Function first, which then calls this).
create or replace function public.srv_remove_seat(p_room_id uuid, p_user_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  select app_private.remove_from_room(p_room_id, p_user_id);
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'public.srv_load_match(uuid, uuid)',
    'public.srv_find_receipt(uuid, uuid)',
    'public.srv_record_rejection(uuid, uuid, uuid, integer, jsonb, text)',
    'public.srv_commit_action(uuid, uuid, uuid, integer, jsonb, jsonb, text)',
    'public.srv_room_for_deal(uuid, uuid)',
    'public.srv_commit_match(uuid, uuid, text, uuid, jsonb, jsonb, uuid, uuid)',
    'public.srv_rematch_vote(uuid, uuid)',
    'public.srv_remove_seat(uuid, uuid)'
  ] loop
    execute format('revoke all on function %s from public, anon, authenticated', f);
    execute format('grant execute on function %s to service_role', f);
  end loop;
end $$;

-- =============================================================================
-- CLIENT API (authenticated): validating RPCs only.
-- =============================================================================

-- leave_room: no walking out of a live match through the lobby door.
create or replace function public.leave_room(p_room_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  if exists (select 1 from public.rooms where id = p_room_id and status = 'in_progress') then
    raise exception 'match_in_progress' using errcode = 'P0030';
  end if;
  perform app_private.remove_from_room(p_room_id, v_user);
end;
$$;

-- Quick match: join the queue; if enough compatible players are waiting,
-- assemble a room for them right now, under one advisory lock.
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
  if exists (
    select 1 from public.match_players mp join public.matches m on m.id = mp.match_id
    where mp.user_id = v_user and m.status = 'in_progress' and mp.forfeited_at is null
  ) then
    raise exception 'already_in_match' using errcode = 'P0031';
  end if;

  perform pg_advisory_xact_lock(hashtext('gioco101.matchmaking'));

  select * into v_row from public.matchmaking_queue where user_id = v_user;
  if found and v_row.status = 'matched' and v_row.room_id is not null
     and exists (select 1 from public.rooms where id = v_row.room_id and status in ('lobby', 'in_progress')) then
    return v_row;  -- already matched: idempotent
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
revoke all on function public.enqueue_quick_match(integer, integer) from public, anon;
grant execute on function public.enqueue_quick_match(integer, integer) to authenticated;

create or replace function public.quick_match_heartbeat()
returns public.matchmaking_queue
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.matchmaking_queue;
begin
  update public.matchmaking_queue set last_seen_at = now()
   where user_id = auth.uid()
  returning * into v_row;
  return v_row;
end;
$$;
revoke all on function public.quick_match_heartbeat() from public, anon;
grant execute on function public.quick_match_heartbeat() to authenticated;

create or replace function public.cancel_quick_match()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.matchmaking_queue;
begin
  select * into v_row from public.matchmaking_queue where user_id = auth.uid() for update;
  if not found then return; end if;
  if v_row.status = 'matched' and v_row.room_id is not null then
    -- Matched but backing out: leave the assembled lobby too.
    perform app_private.remove_from_room(v_row.room_id, auth.uid());
  end if;
  delete from public.matchmaking_queue where user_id = auth.uid();
end;
$$;
revoke all on function public.cancel_quick_match() from public, anon;
grant execute on function public.cancel_quick_match() to authenticated;

-- The match a player should be put back into after a restart, if any.
create or replace function public.my_active_match()
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'matchId', m.id, 'roomId', m.room_id, 'status', m.status,
    'version', ps.version, 'startedAt', m.started_at
  )
  from public.match_players mp
  join public.matches m on m.id = mp.match_id
  left join public.match_public_state ps on ps.match_id = m.id
  where mp.user_id = auth.uid() and m.status = 'in_progress' and mp.forfeited_at is null
  order by m.started_at desc
  limit 1;
$$;
revoke all on function public.my_active_match() from public, anon;
grant execute on function public.my_active_match() to authenticated;

-- One consistent snapshot: public state + own hand + clock + seats. Runs as
-- the caller, so RLS decides what is visible — the private row is the
-- caller's own or nothing.
create or replace function public.match_snapshot(p_match_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_match  public.matches;
  v_public public.match_public_state;
  v_mine   public.match_private_state;
begin
  select * into v_match from public.matches where id = p_match_id;
  if not found then
    raise exception 'not_a_participant' using errcode = '42501';
  end if;
  select * into v_public from public.match_public_state where match_id = p_match_id;
  select * into v_mine from public.match_private_state
   where match_id = p_match_id and user_id = auth.uid();
  return jsonb_build_object(
    'match', jsonb_build_object(
      'id', v_match.id, 'roomId', v_match.room_id, 'status', v_match.status,
      'winnerId', v_match.winner_id, 'currentUserId', v_match.current_user_id,
      'turnTimerSeconds', v_match.turn_timer_seconds,
      'turnStartedAt', v_match.turn_started_at, 'turnDeadlineAt', v_match.turn_deadline_at,
      'abandonedBy', v_match.abandoned_by, 'rematchOf', v_match.rematch_of
    ),
    'version', v_public.version,
    'state', v_public.state,
    'hand', coalesce(v_mine.hand, '[]'::jsonb),
    'handVersion', v_mine.version,
    'drawnCard', v_mine.drawn_card,
    'players', (
      select jsonb_agg(jsonb_build_object(
        'userId', mp.user_id, 'seat', mp.seat, 'enginePlayerId', mp.engine_player_id,
        'nickname', p.nickname, 'avatarId', p.avatar_id, 'connection', mp.connection,
        'lastSeenAt', mp.last_seen_at, 'forfeitedAt', mp.forfeited_at,
        'rematchRequestedAt', mp.rematch_requested_at, 'isWinner', mp.is_winner,
        'placement', mp.placement, 'finalScore', mp.final_score, 'xpAwarded', mp.xp_awarded
      ) order by mp.seat)
      from public.match_players mp join public.profiles p on p.id = mp.user_id
      where mp.match_id = p_match_id
    ),
    'serverNow', now()
  );
end;
$$;
revoke all on function public.match_snapshot(uuid) from public, anon;
grant execute on function public.match_snapshot(uuid) to authenticated;

create or replace function public.match_heartbeat(p_match_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.match_players
     set last_seen_at = now(), connection = 'online'
   where match_id = p_match_id and user_id = auth.uid();
$$;
revoke all on function public.match_heartbeat(uuid) from public, anon;
grant execute on function public.match_heartbeat(uuid) to authenticated;

-- Preset reactions: whitelist + rate limit, then a server-sent broadcast on
-- the private match channel. There is no free-text path.
create or replace function public.send_reaction(p_match_id uuid, p_key text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_seat public.match_players;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  if not exists (select 1 from public.reaction_presets where key = p_key) then
    raise exception 'invalid_reaction' using errcode = '22023';
  end if;
  select * into v_seat from public.match_players
   where match_id = p_match_id and user_id = v_user for update;
  if not found then
    raise exception 'not_a_participant' using errcode = '42501';
  end if;
  if v_seat.last_reaction_at is not null and v_seat.last_reaction_at > now() - interval '2 seconds' then
    raise exception 'rate_limited' using errcode = 'P0040';
  end if;
  update public.match_players set last_reaction_at = now()
   where match_id = p_match_id and user_id = v_user;
  perform realtime.send(
    jsonb_build_object('userId', v_user, 'seat', v_seat.seat, 'key', p_key,
                       'sentAt', now()),
    'reaction', 'match:' || p_match_id::text, true);
end;
$$;
revoke all on function public.send_reaction(uuid, text) from public, anon;
grant execute on function public.send_reaction(uuid, text) to authenticated;

-- --- Housekeeping ---------------------------------------------------------------
-- A match nobody has touched for a day is abandoned (its room finished), so
-- no table can stay "in progress" forever. Turn-level timeouts are handled
-- live by the Edge Function (`timeout` op) — see docs/ONLINE_MULTIPLAYER.md.
create or replace function app_private.expire_stale_matches(p_idle interval default interval '24 hours')
returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_count integer;
begin
  with expired as (
    update public.matches
       set status = 'abandoned', finished_at = now(), current_user_id = null, turn_deadline_at = null
     where status = 'in_progress' and last_action_at < now() - p_idle
    returning id, room_id
  ), rooms_done as (
    update public.rooms r set status = 'finished'
      from expired e where r.id = e.room_id and r.status = 'in_progress'
    returning r.id
  )
  select count(*) into v_count from expired;
  delete from public.matchmaking_queue where last_seen_at < now() - interval '10 minutes';
  return v_count;
end;
$$;

create extension if not exists pg_cron;
select cron.schedule('gioco101-expire-stale-rooms', '*/10 * * * *',
  $$select app_private.expire_stale_rooms()$$);
select cron.schedule('gioco101-expire-stale-matches', '*/10 * * * *',
  $$select app_private.expire_stale_matches()$$);
