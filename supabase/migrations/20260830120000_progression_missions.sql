-- =============================================================================
-- Gioco del 101 — Session 5, migration 8: progression that the server judges.
--
--   leaderboard(scope, limit, offset)   paging; my_leaderboard_rank(scope)
--   match_round_results                 per-seat facts of every finished round
--                                       (written by srv_commit_action)
--   app_private.evaluate_achievements   the six badges + the older three,
--                                       decided from server-held state only
--   daily missions                      7-day rotation (mirrors MissionCatalog
--                                       in Dart), progress written ONLY by
--                                       srv_commit_action / settle_match,
--                                       claims judged on the database clock
--
-- Nothing here trusts the client: no RPC takes a "progress" or "unlock"
-- argument. The phone can only ask "what are today's missions" and "claim
-- this one"; the server re-checks completion and the date itself.
-- =============================================================================

-- --- Leaderboard: paging + own rank ------------------------------------------
drop function if exists public.leaderboard(text, integer);

create or replace function public.leaderboard(
  p_scope  text,
  p_limit  integer default 50,
  p_offset integer default 0
)
returns table (
  rank      bigint,
  user_id   uuid,
  nickname  text,
  avatar_id text,
  points    integer,
  is_self   boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select * from (
    select
      row_number() over (order by p.rating desc, p.wins desc, p.created_at) as rank,
      p.id as user_id, p.nickname, p.avatar_id, p.rating as points,
      p.id = auth.uid() as is_self
    from public.profiles p
    where p_scope = 'all_time'
    union all
    select
      row_number() over (order by w.points desc, w.wins desc, p.created_at) as rank,
      p.id, p.nickname, p.avatar_id, w.points,
      p.id = auth.uid()
    from public.weekly_points w
    join public.profiles p on p.id = w.user_id
    where p_scope = 'weekly'
      and w.week_start = (date_trunc('week', now() at time zone 'Europe/Rome'))::date
  ) board
  order by rank
  limit  least(greatest(coalesce(p_limit, 50), 1), 200)
  offset least(greatest(coalesce(p_offset, 0), 0), 100000);
$$;
revoke all on function public.leaderboard(text, integer, integer) from public, anon;
grant execute on function public.leaderboard(text, integer, integer) to authenticated;

-- "Where am I?" independent of the page loaded. Empty when not ranked
-- (no weekly points this week).
create or replace function public.my_leaderboard_rank(p_scope text)
returns table (
  rank      bigint,
  user_id   uuid,
  nickname  text,
  avatar_id text,
  points    integer,
  is_self   boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select * from (
    select
      row_number() over (order by p.rating desc, p.wins desc, p.created_at) as rank,
      p.id as user_id, p.nickname, p.avatar_id, p.rating as points, true as is_self
    from public.profiles p
    where p_scope = 'all_time'
    union all
    select
      row_number() over (order by w.points desc, w.wins desc, p.created_at) as rank,
      p.id, p.nickname, p.avatar_id, w.points, true
    from public.weekly_points w
    join public.profiles p on p.id = w.user_id
    where p_scope = 'weekly'
      and w.week_start = (date_trunc('week', now() at time zone 'Europe/Rome'))::date
  ) board
  where board.user_id = auth.uid();
$$;
revoke all on function public.my_leaderboard_rank(text) from public, anon;
grant execute on function public.my_leaderboard_rank(text) to authenticated;

-- --- Per-round facts ---------------------------------------------------------
-- The engine's lastRoundResult, one row per seat per round, recorded by the
-- commit that ended the round. This is what "Centouno!" and "Mano Perfetta"
-- are judged from: the server saw the round end; the phone reported nothing.
create table public.match_round_results (
  match_id      uuid     not null references public.matches (id) on delete cascade,
  round         smallint not null check (round >= 1),
  user_id       uuid     not null references public.profiles (id) on delete cascade,
  won_round     boolean  not null default false,
  hit_exact_101 boolean  not null default false,
  eliminated    boolean  not null default false,
  perfect_hand  boolean  not null default false,
  cards_left    smallint not null default 0,
  penalty       integer  not null default 0,
  new_score     integer  not null default 0,
  created_at    timestamptz not null default now(),
  primary key (match_id, round, user_id)
);
create index match_round_results_user_idx on public.match_round_results (user_id);
comment on table public.match_round_results is
  'Server-recorded outcome of every finished online round; feeds achievements.';

alter table public.match_round_results enable row level security;
create policy "match_round_results: visible to players of the match"
  on public.match_round_results for select to authenticated
  using (public.is_match_member(match_id));
grant select on public.match_round_results to authenticated;

create or replace function app_private.record_round_result(p_match_id uuid, p_state jsonb)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_result jsonb := p_state -> 'lastRoundResult';
  v_round  integer;
  v_row    jsonb;
  v_user   uuid;
  v_pid    text;
  v_won    boolean;
begin
  if v_result is null or v_result = 'null'::jsonb then
    return;
  end if;
  v_round := coalesce((v_result ->> 'roundNumber')::integer, (p_state ->> 'round')::integer, 1);
  for v_row in select * from jsonb_array_elements(coalesce(v_result -> 'rows', '[]'::jsonb)) loop
    v_pid := v_row ->> 'playerId';
    select mp.user_id into v_user
      from public.match_players mp
     where mp.match_id = p_match_id and mp.engine_player_id = v_pid;
    if v_user is null then
      continue;
    end if;
    v_won := (v_result ->> 'winnerId') = v_pid;
    insert into public.match_round_results (
      match_id, round, user_id, won_round, hit_exact_101, eliminated,
      perfect_hand, cards_left, penalty, new_score
    ) values (
      p_match_id, v_round, v_user, v_won,
      coalesce((v_row ->> 'hitExact101')::boolean, false),
      coalesce((v_row ->> 'eliminated')::boolean, false),
      -- "Mano Perfetta": won the round without drawing a single card.
      v_won and coalesce((p_state -> 'drawsByPlayer' ->> v_pid)::integer, 0) = 0,
      coalesce((v_row ->> 'cardsLeft')::integer, 0),
      coalesce((v_row ->> 'penalty')::integer, 0),
      coalesce((v_row ->> 'newScore')::integer, 0)
    )
    on conflict do nothing;
  end loop;
end;
$$;

-- --- Daily missions: the seven-day rotation -----------------------------------
-- MUST match lib/features/missions/domain/mission.dart (MissionCatalog).
alter table public.daily_missions add column if not exists sort_order smallint not null default 0;

create or replace function app_private.mission_rotation(p_isodow integer)
returns table (sort_order smallint, mission_key text, target integer, reward_xp integer)
language sql
immutable
set search_path = ''
as $$
  select r.sort_order, r.mission_key, r.target, r.reward_xp from (values
    (1, 1::smallint, 'play_matches', 2, 30), (1, 2::smallint, 'play_aces',    3, 25), (1, 3::smallint, 'use_nine',     1, 20),
    (2, 1::smallint, 'win_match',    1, 40), (2, 2::smallint, 'play_twos',    3, 25), (2, 3::smallint, 'online_match', 1, 30),
    (3, 1::smallint, 'play_matches', 3, 35), (3, 2::smallint, 'block_two',    1, 30), (3, 3::smallint, 'use_nine',     2, 25),
    (4, 1::smallint, 'win_match',    1, 40), (4, 2::smallint, 'play_aces',    4, 30), (4, 3::smallint, 'play_matches', 2, 30),
    (5, 1::smallint, 'play_twos',    4, 30), (5, 2::smallint, 'use_nine',     2, 25), (5, 3::smallint, 'online_match', 1, 30),
    (6, 1::smallint, 'play_matches', 3, 35), (6, 2::smallint, 'win_match',    2, 50), (6, 3::smallint, 'block_two',    1, 30),
    (7, 1::smallint, 'play_aces',    3, 25), (7, 2::smallint, 'use_nine',     3, 30), (7, 3::smallint, 'online_match', 2, 45)
  ) as r(isodow, sort_order, mission_key, target, reward_xp)
  where r.isodow = p_isodow
  order by r.sort_order;
$$;

-- The server's calendar day. The phone's clock is never consulted.
create or replace function app_private.today_rome()
returns date
language sql
stable
set search_path = ''
as $$
  select (now() at time zone 'Europe/Rome')::date;
$$;

create or replace function app_private.ensure_daily_missions(p_date date)
returns void
language sql
set search_path = ''
as $$
  insert into public.daily_missions (mission_date, mission_key, target, reward_xp, reward_coins, sort_order)
  select p_date, r.mission_key, r.target, r.reward_xp, 0, r.sort_order
  from app_private.mission_rotation(extract(isodow from p_date)::integer) r
  on conflict (mission_date, mission_key) do nothing;
$$;

-- Adds p_inc to today's mission p_key for p_user, capped at the target.
-- Called only from server code that observed the play.
create or replace function app_private.track_mission(p_user uuid, p_key text, p_inc integer default 1)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_today   date := app_private.today_rome();
  v_mission public.daily_missions;
begin
  if p_user is null or p_inc is null or p_inc <= 0 then
    return;
  end if;
  perform app_private.ensure_daily_missions(v_today);
  for v_mission in
    select * from public.daily_missions
     where mission_date = v_today and mission_key = p_key
  loop
    insert into public.user_daily_missions (user_id, mission_id, progress)
    values (p_user, v_mission.id, least(p_inc, v_mission.target))
    on conflict (user_id, mission_id) do update
      set progress = least(public.user_daily_missions.progress + p_inc, v_mission.target)
      where public.user_daily_missions.claimed_at is null;
    update public.user_daily_missions
       set completed_at = now()
     where user_id = p_user and mission_id = v_mission.id
       and completed_at is null and progress >= v_mission.target;
  end loop;
end;
$$;

-- RPC: today's missions with this player's progress.
create or replace function public.my_daily_missions()
returns table (
  mission_id   uuid,
  mission_date date,
  mission_key  text,
  target       integer,
  reward_xp    integer,
  reward_coins integer,
  progress     integer,
  completed_at timestamptz,
  claimed_at   timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user  uuid := auth.uid();
  v_today date := app_private.today_rome();
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  perform app_private.ensure_daily_missions(v_today);
  return query
    select dm.id, dm.mission_date, dm.mission_key, dm.target, dm.reward_xp, dm.reward_coins,
           coalesce(um.progress, 0), um.completed_at, um.claimed_at
      from public.daily_missions dm
      left join public.user_daily_missions um
        on um.mission_id = dm.id and um.user_id = v_user
     where dm.mission_date = v_today
     order by dm.sort_order, dm.mission_key;
end;
$$;
revoke all on function public.my_daily_missions() from public, anon;
grant execute on function public.my_daily_missions() to authenticated;

-- RPC: claim. Judged here, on the server clock: today's mission, complete,
-- not yet claimed. Grants XP through the same routine matches use.
create or replace function public.claim_mission_reward(p_mission_id uuid)
returns table (
  mission_id   uuid,
  mission_date date,
  mission_key  text,
  target       integer,
  reward_xp    integer,
  reward_coins integer,
  progress     integer,
  completed_at timestamptz,
  claimed_at   timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user    uuid := auth.uid();
  v_mission public.daily_missions;
  v_row     public.user_daily_missions;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(hashtext('mission_claim:' || v_user::text));

  select * into v_mission from public.daily_missions where id = p_mission_id;
  if not found or v_mission.mission_date <> app_private.today_rome() then
    raise exception 'mission_expired' using errcode = 'P0001';
  end if;
  select * into v_row from public.user_daily_missions
   where user_id = v_user and mission_id = p_mission_id
   for update;
  if not found or v_row.progress < v_mission.target then
    raise exception 'not_completed' using errcode = 'P0001';
  end if;
  if v_row.claimed_at is not null then
    raise exception 'already_claimed' using errcode = 'P0001';
  end if;

  update public.user_daily_missions
     set claimed_at = now(), completed_at = coalesce(completed_at, now())
   where user_id = v_user and mission_id = p_mission_id;
  perform app_private.grant_xp(v_user, v_mission.reward_xp);
  if v_mission.reward_coins > 0 then
    update public.player_stats set coins = coins + v_mission.reward_coins where user_id = v_user;
  end if;

  return query
    select dm.id, dm.mission_date, dm.mission_key, dm.target, dm.reward_xp, dm.reward_coins,
           um.progress, um.completed_at, um.claimed_at
      from public.daily_missions dm
      join public.user_daily_missions um on um.mission_id = dm.id and um.user_id = v_user
     where dm.id = p_mission_id;
end;
$$;
revoke all on function public.claim_mission_reward(uuid) from public, anon;
grant execute on function public.claim_mission_reward(uuid) to authenticated;

-- --- Achievements, judged from server-held facts ------------------------------
-- Runs after record_match_result (so streaks and match counts are final).
create or replace function app_private.evaluate_achievements(p_match_id uuid, p_state jsonb)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_seat   record;
  v_chain  integer := coalesce((p_state -> 'stats' ->> 'longestChain')::integer, 0);
  v_suits  integer;
begin
  for v_seat in
    select mp.user_id, mp.engine_player_id, mp.is_winner,
           p.matches, p.current_streak, p.wins
      from public.match_players mp
      join public.profiles p on p.id = mp.user_id
     where mp.match_id = p_match_id
  loop
    -- Prima Vittoria — any win (idempotent).
    if v_seat.is_winner then
      perform app_private.unlock_achievement(v_seat.user_id, 'prima_vittoria');
    end if;

    -- Centouno! — landed on exactly 101 in some round of this match.
    if exists (select 1 from public.match_round_results r
                where r.match_id = p_match_id and r.user_id = v_seat.user_id and r.hit_exact_101) then
      perform app_private.unlock_achievement(v_seat.user_id, 'rinascita');
    end if;

    -- Vendetta — a win that follows a defeat: the streak restarted at 1
    -- with at least one earlier match on record.
    if v_seat.is_winner and v_seat.current_streak = 1 and v_seat.matches >= 2 then
      perform app_private.unlock_achievement(v_seat.user_id, 'vendetta');
    end if;

    -- Maestro del Nove — won having named all four suits with a Cavallo.
    v_suits := coalesce(jsonb_array_length(p_state -> 'stats' -> 'cavalloSuits' -> v_seat.engine_player_id), 0);
    if v_seat.is_winner and v_suits >= 4 then
      perform app_private.unlock_achievement(v_seat.user_id, 'maestro_semi');
    end if;

    -- Imbattibile — five wins in a row.
    if v_seat.current_streak >= 5 then
      perform app_private.unlock_achievement(v_seat.user_id, 'imbattibile');
    end if;

    -- Veterano — 25 matches.
    if v_seat.matches >= 25 then
      perform app_private.unlock_achievement(v_seat.user_id, 'veterano');
    end if;

    -- Catena — a chain of three 2s (+6) happened at this table.
    if v_chain >= 3 then
      perform app_private.unlock_achievement(v_seat.user_id, 'catena');
    end if;

    -- Mano Perfetta — won a round without drawing.
    if exists (select 1 from public.match_round_results r
                where r.match_id = p_match_id and r.user_id = v_seat.user_id and r.perfect_hand) then
      perform app_private.unlock_achievement(v_seat.user_id, 'mano_perfetta');
    end if;

    -- Missions the match itself completes.
    perform app_private.track_mission(v_seat.user_id, 'play_matches', 1);
    perform app_private.track_mission(v_seat.user_id, 'online_match', 1);
    if v_seat.is_winner then
      perform app_private.track_mission(v_seat.user_id, 'win_match', 1);
    end if;
  end loop;
end;
$$;

-- settle_match now also judges achievements and missions.
create or replace function app_private.settle_match(p_match_id uuid, p_state jsonb)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_winner_engine text := p_state ->> 'winnerId';
  v_winner_user   uuid;
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
  perform app_private.record_match_result(p_match_id, app_private.rating_deltas(p_match_id));
  perform app_private.evaluate_achievements(p_match_id, p_state);
end;
$$;

-- --- srv_commit_action: unchanged contract, plus round facts + mission ticks --
create or replace function public.srv_commit_action(
  p_match_id     uuid,
  p_actor        uuid,
  p_action_id    uuid,
  p_base_version integer,
  p_new_state    jsonb,
  p_actions      jsonb,
  p_kind         text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_current_version integer;
  v_old_state       jsonb;
  v_new_version     integer := (p_new_state ->> 'version')::integer;
  v_status          text    := p_new_state ->> 'status';
  v_seat            integer := coalesce((p_new_state ->> 'currentSeat')::integer, 0);
  v_current_user    uuid;
  v_deadline        timestamptz;
  v_started         timestamptz;
  v_action          jsonb;
  v_card            text;
  v_receipt         public.match_action_receipts;
  v_log_version     integer := p_base_version;
begin
  if p_kind not in ('action', 'timeout', 'forfeit', 'system') then
    raise exception 'invalid_kind' using errcode = '22023';
  end if;

  -- Serialise on the engine row; every concurrent commit queues here.
  select version, state into v_current_version, v_old_state
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

    -- §V — mission progress from the play the server just accepted. Only a
    -- player's OWN action counts (never a timeout move made on their behalf).
    if p_kind = 'action' and p_actor is not null and (v_action ->> 'type') = 'playCard' then
      v_card := v_action ->> 'card';
      case split_part(v_card, '_', 2)
        when 'asso' then
          perform app_private.track_mission(p_actor, 'play_aces', 1);
        when 'due' then
          perform app_private.track_mission(p_actor, 'play_twos', 1);
        when 'cavallo' then
          perform app_private.track_mission(p_actor, 'use_nine', 1);
          if coalesce((v_old_state ->> 'pendingDrawCount')::integer, 0) > 0 then
            perform app_private.track_mission(p_actor, 'block_two', 1);
          end if;
        else
          null;
      end case;
    end if;
  end loop;

  perform app_private.publish_match_state(p_match_id, p_new_state);

  -- The round just ended: keep every seat's result for the achievement judge.
  if v_status in ('roundOver', 'finished') then
    perform app_private.record_round_result(p_match_id, p_new_state);
  end if;

  select user_id into v_current_user from public.match_players
   where match_id = p_match_id and engine_player_id = 'p' || v_seat::text;

  v_started  := app_private.epoch_ms_to_ts(p_new_state -> 'turnStartedAt');
  v_deadline := app_private.epoch_ms_to_ts(p_new_state -> 'turnDeadlineAt');
  if v_status = 'roundOver' then
    v_deadline := now() + interval '30 seconds';
    v_started  := now();
  elsif v_status in ('awaitingAction', 'awaitingSuitChoice') and v_deadline is null
        and exists (select 1 from public.matches where id = p_match_id and turn_timer_seconds > 0) then
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
revoke all on function public.srv_commit_action(uuid, uuid, uuid, integer, jsonb, jsonb, text) from public, anon, authenticated;
grant execute on function public.srv_commit_action(uuid, uuid, uuid, integer, jsonb, jsonb, text) to service_role;
