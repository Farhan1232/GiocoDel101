-- =============================================================================
-- Gioco del 101 — Session 3, migration 4/4: progression, rewards, leaderboards.
--
--   achievements / user_achievements   catalogue + unlocks (server-written)
--   daily_rewards                      the 7-day ladder, one claim per day
--   daily_missions / user_daily_missions  definitions + progress (server-written)
--   weekly_points                      per-week aggregate feeding the weekly board
--   leaderboard(scope, limit)          the one query both boards use
--
-- Server-only progression API (app_private.*, no client grant):
--   grant_xp, unlock_achievement, record_match_result
--
-- PROVISIONAL numbers (GAME_SPEC §12b is not confirmed by the client):
--   xp per match 20, xp per win 45, level cost 120 + 40/level — the same
--   placeholder ProfileSummary.fromLocal used, so the profile does not jump.
--   Ranking points: record_match_result accepts explicit deltas and applies
--   NO formula of its own.
-- =============================================================================

-- --- Achievements -----------------------------------------------------------
create table public.achievements (
  id                   text primary key,
  icon                 text not null,
  unlocks_theme_id     text,
  unlocks_card_back_id text,
  sort_order           smallint not null
);
comment on table public.achievements is
  'Mirror of AchievementsCatalog.all — ids are the historic ones the app already stores.';

insert into public.achievements (id, icon, unlocks_theme_id, unlocks_card_back_id, sort_order) values
  ('prima_vittoria', 'trophy',  null,       null,       1),
  ('rinascita',      'ring',    null,       'notturno', 2),
  ('vendetta',       'restart', null,       null,       3),
  ('maestro_semi',   'suits',   'maiolica', 'cobalto',  4),
  ('imbattibile',    'stats',   null,       null,       5),
  ('veterano',       'players', null,       null,       6),
  ('catena',         'chain',   'vesuvio',  'brace',    7),
  ('mano_perfetta',  'hand',    null,       null,       8),
  ('sfida_giorno',   'calendar', null,      null,       9);

create table public.user_achievements (
  user_id        uuid not null references public.profiles (id) on delete cascade,
  achievement_id text not null references public.achievements (id) on delete cascade,
  unlocked_at    timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;

create policy "achievements: players can read the catalogue"
  on public.achievements for select to authenticated using (true);
create policy "user_achievements: badges are public"
  on public.user_achievements for select to authenticated using (true);

grant select on public.achievements, public.user_achievements to authenticated;

-- --- Daily rewards ----------------------------------------------------------
create table public.daily_rewards (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  claimed_on date not null,
  day_index  smallint not null check (day_index between 1 and 7),
  amount     integer not null check (amount > 0),
  claimed_at timestamptz not null default now(),
  primary key (user_id, claimed_on)
);
create index daily_rewards_user_recent_idx on public.daily_rewards (user_id, claimed_on desc);

alter table public.daily_rewards enable row level security;
create policy "daily_rewards: players read their own claims"
  on public.daily_rewards for select to authenticated
  using ((select auth.uid()) = user_id);
grant select on public.daily_rewards to authenticated;

-- --- Daily missions ---------------------------------------------------------
create table public.daily_missions (
  id            uuid primary key default gen_random_uuid(),
  mission_date  date not null,
  mission_key   text not null,
  target        integer not null check (target > 0),
  reward_xp     integer not null default 0 check (reward_xp >= 0),
  reward_coins  integer not null default 0 check (reward_coins >= 0),
  unique (mission_date, mission_key)
);
create table public.user_daily_missions (
  user_id      uuid not null references public.profiles (id) on delete cascade,
  mission_id   uuid not null references public.daily_missions (id) on delete cascade,
  progress     integer not null default 0 check (progress >= 0),
  completed_at timestamptz,
  claimed_at   timestamptz,
  primary key (user_id, mission_id)
);

alter table public.daily_missions enable row level security;
alter table public.user_daily_missions enable row level security;
create policy "daily_missions: players read the definitions"
  on public.daily_missions for select to authenticated using (true);
create policy "user_daily_missions: players read their own progress"
  on public.user_daily_missions for select to authenticated
  using ((select auth.uid()) = user_id);
grant select on public.daily_missions, public.user_daily_missions to authenticated;

-- --- Weekly aggregate -------------------------------------------------------
create table public.weekly_points (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  week_start date not null,
  points     integer not null default 0 check (points >= 0),
  wins       integer not null default 0 check (wins >= 0),
  matches    integer not null default 0 check (matches >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, week_start)
);
create index weekly_points_board_idx on public.weekly_points (week_start, points desc, wins desc);

alter table public.weekly_points enable row level security;
create policy "weekly_points: boards are public"
  on public.weekly_points for select to authenticated using (true);
grant select on public.weekly_points to authenticated;

-- --- Level ladder (provisional; mirrors ProfileSummary.fromLocal) -----------
create or replace function app_private.level_for_xp(p_xp integer)
returns table (level integer, xp_into_level integer, xp_for_level integer)
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_xp    integer := greatest(coalesce(p_xp, 0), 0);
  v_level integer := 1;
  v_cost  integer := 120;
begin
  while v_xp >= v_cost loop
    v_xp := v_xp - v_cost;
    v_level := v_level + 1;
    v_cost := v_cost + 40;
  end loop;
  level := v_level; xp_into_level := v_xp; xp_for_level := v_cost;
  return next;
end;
$$;

-- --- Server-only progression API -------------------------------------------
create or replace function app_private.grant_xp(p_user_id uuid, p_amount integer)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_xp integer;
begin
  if p_amount is null or p_amount <= 0 then
    return;
  end if;
  update public.profiles
     set xp = xp + p_amount
   where id = p_user_id
  returning xp into v_xp;
  if found then
    update public.profiles p
       set level = l.level
      from app_private.level_for_xp(v_xp) as l
     where p.id = p_user_id;
  end if;
end;
$$;

create or replace function app_private.unlock_achievement(p_user_id uuid, p_achievement_id text)
returns boolean
language plpgsql
set search_path = ''
as $$
begin
  insert into public.user_achievements (user_id, achievement_id)
  values (p_user_id, p_achievement_id)
  on conflict do nothing;
  return found;
end;
$$;

-- Applies a finished match to every seat's profile and the weekly board.
-- p_rating_deltas: {"<user_id>": <int>} — optional; no formula lives here.
create or replace function app_private.record_match_result(
  p_match_id      uuid,
  p_rating_deltas jsonb default null
)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_match  public.matches;
  v_seat   record;
  v_week   date := (date_trunc('week', now() at time zone 'Europe/Rome'))::date;
  v_xp     integer;
  v_delta  integer;
begin
  select * into v_match from public.matches where id = p_match_id for update;
  if not found or v_match.status <> 'finished' then
    raise exception 'match_not_finished' using errcode = 'P0001';
  end if;

  for v_seat in
    select mp.*, p.rating, p.current_streak, p.best_streak
    from public.match_players mp
    join public.profiles p on p.id = mp.user_id
    where mp.match_id = p_match_id
    for update of mp
  loop
    v_xp := 20 + case when v_seat.is_winner then 45 else 0 end;   -- provisional
    v_delta := coalesce((p_rating_deltas ->> v_seat.user_id::text)::integer, 0);

    update public.profiles
       set matches        = matches + 1,
           wins           = wins   + case when v_seat.is_winner then 1 else 0 end,
           losses         = losses + case when v_seat.is_winner then 0 else 1 end,
           current_streak = case when v_seat.is_winner then current_streak + 1 else 0 end,
           best_streak    = greatest(best_streak,
                              case when v_seat.is_winner then current_streak + 1 else best_streak end),
           rating         = rating + v_delta
     where id = v_seat.user_id;

    perform app_private.grant_xp(v_seat.user_id, v_xp);

    update public.match_players
       set rating_before = v_seat.rating,
           rating_after  = v_seat.rating + v_delta,
           xp_awarded    = v_xp
     where match_id = p_match_id and user_id = v_seat.user_id;

    update public.player_stats
       set online_matches = online_matches + 1
     where user_id = v_seat.user_id;

    insert into public.weekly_points (user_id, week_start, points, wins, matches)
    values (v_seat.user_id, v_week, v_xp, case when v_seat.is_winner then 1 else 0 end, 1)
    on conflict (user_id, week_start) do update
      set points  = public.weekly_points.points + excluded.points,
          wins    = public.weekly_points.wins + excluded.wins,
          matches = public.weekly_points.matches + 1,
          updated_at = now();

    if v_seat.is_winner then
      perform app_private.unlock_achievement(v_seat.user_id, 'prima_vittoria');
    end if;
  end loop;
end;
$$;

-- --- RPC: claim_daily_reward (permanent accounts only) ----------------------
create or replace function public.claim_daily_reward()
returns public.daily_rewards
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user   uuid := auth.uid();
  v_ladder constant integer[] := array[10, 15, 20, 30, 40, 60, 120];
  v_today  date := (now() at time zone 'Europe/Rome')::date;
  v_last   public.daily_rewards;
  v_day    smallint;
  v_row    public.daily_rewards;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  if not public.is_permanent_user() then
    raise exception 'guest_not_allowed' using errcode = '42501';
  end if;

  -- Serialise per user so two taps cannot claim twice.
  perform pg_advisory_xact_lock(hashtext('daily_reward:' || v_user::text));

  if exists (select 1 from public.daily_rewards
             where user_id = v_user and claimed_on = v_today) then
    raise exception 'already_claimed' using errcode = 'P0001';
  end if;

  select * into v_last
  from public.daily_rewards
  where user_id = v_user
  order by claimed_on desc
  limit 1;

  if found and v_last.claimed_on = v_today - 1 then
    v_day := (v_last.day_index % 7) + 1;
  else
    v_day := 1;
  end if;

  insert into public.daily_rewards (user_id, claimed_on, day_index, amount)
  values (v_user, v_today, v_day, v_ladder[v_day])
  returning * into v_row;

  update public.player_stats
     set coins = coins + v_row.amount
   where user_id = v_user;

  return v_row;
end;
$$;
revoke all on function public.claim_daily_reward() from public, anon;
grant execute on function public.claim_daily_reward() to authenticated;

-- --- RPC: my_daily_reward_status --------------------------------------------
create or replace function public.my_daily_reward_status()
returns table (streak integer, claimed_today boolean, can_claim boolean, coins integer)
language sql
stable
security invoker
set search_path = ''
as $$
  with today as (
    select (now() at time zone 'Europe/Rome')::date as d
  ),
  last as (
    select dr.claimed_on, dr.day_index
    from public.daily_rewards dr
    where dr.user_id = auth.uid()
    order by dr.claimed_on desc
    limit 1
  )
  select
    case
      when l.claimed_on = t.d       then l.day_index
      when l.claimed_on = t.d - 1   then l.day_index
      else 0
    end::integer as streak,
    coalesce(l.claimed_on = t.d, false) as claimed_today,
    (public.is_permanent_user() and coalesce(l.claimed_on <> t.d, true)) as can_claim,
    coalesce((select ps.coins from public.player_stats ps where ps.user_id = auth.uid()), 0) as coins
  from today t
  left join last l on true;
$$;
revoke all on function public.my_daily_reward_status() from public, anon;
grant execute on function public.my_daily_reward_status() to authenticated;

-- --- RPC: leaderboard -------------------------------------------------------
-- all_time: profiles.rating (then wins). weekly: weekly_points of the current
-- ISO week (Europe/Rome). Reads go through RLS (security invoker).
create or replace function public.leaderboard(p_scope text, p_limit integer default 50)
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
  limit least(greatest(coalesce(p_limit, 50), 1), 200);
$$;
revoke all on function public.leaderboard(text, integer) from public, anon;
grant execute on function public.leaderboard(text, integer) to authenticated;
