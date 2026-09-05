-- =============================================================================
-- Gioco del 101 — Session 3, migration 1/4: core identity.
--
--   * app_private schema  — server-only code and data; never exposed to the
--                            Data API, no grants to anon/authenticated.
--   * exposure is opt-in  — default privileges are revoked so a future table
--                            or function is invisible to clients until a
--                            migration grants it deliberately.
--   * avatars             — the whitelist of built-in avatar ids.
--   * profiles            — public identity + server-owned progression.
--   * player_stats        — the extra lifetime counters, server-owned.
--   * auth trigger        — every auth.users row (email or anonymous) gets a
--                            profile and a stats row automatically.
--
-- Client capability after this migration (role `authenticated`):
--   profiles       SELECT all rows; UPDATE only nickname/avatar_id on own row
--   player_stats   SELECT all rows
--   avatars        SELECT
--   rpc            touch_presence()
-- Nothing else. XP, level, wins, losses, rating and streaks can only be
-- changed by code running as postgres/service_role (app_private.*).
-- =============================================================================

create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;
grant usage on schema app_private to service_role;

-- --- Exposure is opt-in -----------------------------------------------------
alter default privileges for role postgres in schema public
  revoke select, insert, update, delete, truncate, references, trigger
  on tables from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke usage, select, update on sequences from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated;

-- --- Shared helpers ---------------------------------------------------------
create or replace function app_private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- True for a signed-in user that is NOT an anonymous (guest) user.
create or replace function public.is_permanent_user()
returns boolean
language sql
stable
set search_path = ''
as $$
  select auth.uid() is not null
     and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) is false;
$$;
revoke all on function public.is_permanent_user() from public, anon;
grant execute on function public.is_permanent_user() to authenticated;

-- --- Avatars (built-in assets; the DB enforces the whitelist) ---------------
create table public.avatars (
  id         text primary key,
  sort_order smallint not null
);
comment on table public.avatars is
  'Whitelist of built-in avatar ids drawn by the app (lib/features/profile/domain/avatars.dart).';

insert into public.avatars (id, sort_order) values
  ('lucia', 1), ('marco', 2), ('sofia', 3), ('luca', 4),
  ('giulia', 5), ('enzo', 6), ('rosa', 7), ('dario', 8);

alter table public.avatars enable row level security;
create policy "avatars: players can read"
  on public.avatars for select to authenticated using (true);
grant select on public.avatars to authenticated;

-- --- Profiles ---------------------------------------------------------------
create table public.profiles (
  id             uuid primary key references auth.users (id) on delete cascade,
  nickname       text not null,
  avatar_id      text not null default 'lucia' references public.avatars (id),
  is_guest       boolean not null default false,
  level          integer not null default 1  check (level >= 1),
  xp             integer not null default 0  check (xp >= 0),
  wins           integer not null default 0  check (wins >= 0),
  losses         integer not null default 0  check (losses >= 0),
  matches        integer not null default 0  check (matches >= 0),
  rating         integer not null default 1000,
  current_streak integer not null default 0  check (current_streak >= 0),
  best_streak    integer not null default 0  check (best_streak >= 0),
  last_seen_at   timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint profiles_nickname_length  check (char_length(nickname) between 3 and 16),
  constraint profiles_nickname_trimmed check (nickname = btrim(nickname)),
  constraint profiles_nickname_charset check (nickname !~ '[[:cntrl:]]')
);
comment on table public.profiles is
  'Public player identity. nickname/avatar_id are player-editable; every other column is server-owned.';
comment on column public.profiles.rating is
  'Ranking points. The online points formula (GAME_SPEC §12b) is NOT confirmed; nothing changes this yet.';

create unique index profiles_nickname_lower_idx on public.profiles (lower(nickname));
create index profiles_leaderboard_idx on public.profiles (rating desc, wins desc, created_at);
create index profiles_last_seen_idx on public.profiles (last_seen_at desc);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function app_private.set_updated_at();

-- Defence in depth: even if a grant is widened later, a client role can never
-- move a server-owned column. Server code runs as postgres/service_role.
create or replace function app_private.protect_profile_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('anon', 'authenticated') and (
       new.id             is distinct from old.id
    or new.is_guest       is distinct from old.is_guest
    or new.level          is distinct from old.level
    or new.xp             is distinct from old.xp
    or new.wins           is distinct from old.wins
    or new.losses         is distinct from old.losses
    or new.matches        is distinct from old.matches
    or new.rating         is distinct from old.rating
    or new.current_streak is distinct from old.current_streak
    or new.best_streak    is distinct from old.best_streak
    or new.last_seen_at   is distinct from old.last_seen_at
    or new.created_at     is distinct from old.created_at
  ) then
    raise exception 'profile progression columns are server-owned'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger profiles_protect_columns
  before update on public.profiles
  for each row execute function app_private.protect_profile_columns();

alter table public.profiles enable row level security;

create policy "profiles: players can read every profile"
  on public.profiles for select to authenticated using (true);

create policy "profiles: players edit only their own row"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Column-level grant: the client can touch nickname and avatar_id, nothing else.
grant select on public.profiles to authenticated;
grant update (nickname, avatar_id) on public.profiles to authenticated;

-- --- Extra lifetime stats (server-owned) ------------------------------------
create table public.player_stats (
  user_id                   uuid primary key references public.profiles (id) on delete cascade,
  rounds_played             integer not null default 0 check (rounds_played >= 0),
  rounds_won                integer not null default 0 check (rounds_won >= 0),
  cards_played              integer not null default 0 check (cards_played >= 0),
  aces_played               integer not null default 0 check (aces_played >= 0),
  twos_played               integer not null default 0 check (twos_played >= 0),
  longest_chain             integer not null default 0 check (longest_chain >= 0),
  resets_101                integer not null default 0 check (resets_101 >= 0),
  largest_comeback          integer not null default 0 check (largest_comeback >= 0),
  daily_challenges_completed integer not null default 0 check (daily_challenges_completed >= 0),
  online_matches            integer not null default 0 check (online_matches >= 0),
  coins                     integer not null default 0 check (coins >= 0),
  updated_at                timestamptz not null default now()
);
comment on table public.player_stats is
  'Lifetime counters mirrored from StatisticsModel. Server-owned; clients only read.';

create trigger player_stats_set_updated_at
  before update on public.player_stats
  for each row execute function app_private.set_updated_at();

alter table public.player_stats enable row level security;
create policy "player_stats: players can read every row"
  on public.player_stats for select to authenticated using (true);
grant select on public.player_stats to authenticated;

-- --- Automatic profile initialisation ---------------------------------------
-- Runs for every new auth user: email sign-up AND anonymous (guest) sign-in.
-- The nickname comes from raw_user_meta_data.nickname when present (sign-up
-- form), otherwise 'Ospite-XXXX' for guests / 'Giocatore-N' for others.
-- Collisions are resolved here so sign-up never fails on a taken nickname.
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
              '[[:cntrl:]]', '', 'g')), '');
  if v_base is null or char_length(v_base) < 3 then
    v_base := case when v_guest then 'Ospite' else 'Giocatore' end;
  end if;
  v_base := left(v_base, 16);

  v_avatar := new.raw_user_meta_data ->> 'avatar_id';
  if v_avatar is null
     or not exists (select 1 from public.avatars a where a.id = v_avatar) then
    v_avatar := 'lucia';
  end if;

  if v_guest then
    -- Guests always carry a discriminator so two 'Ospite' never look alike.
    v_candidate := left(v_base, 11) || '-'
                || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4));
  else
    v_candidate := v_base;
  end if;

  while exists (select 1 from public.profiles p
                where lower(p.nickname) = lower(v_candidate)) loop
    v_n := v_n + 1;
    if v_guest then
      v_candidate := left(v_base, 11) || '-'
                  || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4));
    else
      v_candidate := left(v_base, 16 - char_length(v_n::text) - 1) || '-' || v_n;
    end if;
  end loop;

  insert into public.profiles (id, nickname, avatar_id, is_guest, last_seen_at)
  values (new.id, v_candidate, v_avatar, v_guest, now());

  insert into public.player_stats (user_id) values (new.id);

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app_private.handle_new_user();

-- A guest that links an email (is_anonymous -> false) becomes permanent.
create or replace function app_private.handle_user_upgraded()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce(old.is_anonymous, false) and not coalesce(new.is_anonymous, false) then
    update public.profiles set is_guest = false where id = new.id;
  end if;
  return new;
end;
$$;

create trigger on_auth_user_upgraded
  after update of is_anonymous on auth.users
  for each row execute function app_private.handle_user_upgraded();

-- --- Presence ---------------------------------------------------------------
-- The only way a client moves last_seen_at: its own row, server clock.
create or replace function public.touch_presence()
returns void
language sql
security definer
set search_path = ''
as $$
  update public.profiles
     set last_seen_at = now()
   where id = auth.uid();
$$;
revoke all on function public.touch_presence() from public, anon;
grant execute on function public.touch_presence() to authenticated;
