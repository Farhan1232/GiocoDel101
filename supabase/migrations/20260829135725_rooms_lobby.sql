-- =============================================================================
-- Gioco del 101 — Session 3, migration 2/4: rooms and the lobby lifecycle.
--
--   rooms         one row per room; six-character code from the no-look-alike
--                 alphabet the app already uses (RoomCode.alphabet).
--   room_players  one row per seated player; seat 0..3, host flag, ready flag,
--                 presence.
--
-- Lifecycle:  lobby -> starting -> in_progress -> finished
--             lobby -> cancelled (host left alone / expired)
-- The transition lobby -> starting/in_progress (dealing the first hand) is
-- Session 4's authoritative match function; it is not implemented here.
--
-- Client capability (role `authenticated`):
--   rooms          SELECT rooms you are seated in, plus public rooms in lobby
--   room_players   SELECT seats of rooms you are seated in
--   rpc            create_room, join_room, leave_room, set_ready, room_heartbeat
-- No direct INSERT/UPDATE/DELETE anywhere — the RPCs validate every move.
-- =============================================================================

create type public.room_status as enum
  ('lobby', 'starting', 'in_progress', 'finished', 'cancelled');
create type public.connection_state as enum ('online', 'away', 'offline');

create table public.rooms (
  id                 uuid primary key default gen_random_uuid(),
  code               text not null unique
                     check (code ~ '^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$'),
  host_id            uuid not null references public.profiles (id) on delete cascade,
  name               text not null default '' check (char_length(name) <= 24),
  max_players        smallint not null check (max_players between 2 and 4),
  is_private         boolean not null default true,
  turn_timer_seconds smallint not null default 30
                     check (turn_timer_seconds in (0, 15, 30, 60)),
  rules              jsonb not null default '{}'::jsonb,
  status             public.room_status not null default 'lobby',
  match_id           uuid,               -- FK added in migration 3
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  last_activity_at   timestamptz not null default now()
);
comment on table public.rooms is
  'A room configured by a host (RoomConfig). rules is GameRules.toJson().';

create index rooms_public_lobby_idx
  on public.rooms (created_at desc) where status = 'lobby' and is_private = false;
create index rooms_host_idx on public.rooms (host_id);
create index rooms_status_activity_idx on public.rooms (status, last_activity_at);

create trigger rooms_set_updated_at
  before update on public.rooms
  for each row execute function app_private.set_updated_at();

create table public.room_players (
  room_id      uuid not null references public.rooms (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  seat         smallint not null check (seat between 0 and 3),
  is_host      boolean not null default false,
  is_ready     boolean not null default false,
  connection   public.connection_state not null default 'online',
  joined_at    timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  primary key (room_id, user_id),
  unique (room_id, seat)
);
create index room_players_user_idx on public.room_players (user_id);

-- --- Membership helper (SECURITY DEFINER so policies do not recurse) --------
create or replace function public.is_room_member(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.room_players rp
    where rp.room_id = p_room_id and rp.user_id = auth.uid()
  );
$$;
revoke all on function public.is_room_member(uuid) from public, anon;
grant execute on function public.is_room_member(uuid) to authenticated;

-- --- RLS --------------------------------------------------------------------
alter table public.rooms enable row level security;
alter table public.room_players enable row level security;

create policy "rooms: members and public lobbies are visible"
  on public.rooms for select to authenticated
  using (
    public.is_room_member(id)
    or (status = 'lobby' and is_private = false)
  );

create policy "room_players: visible to members of the room"
  on public.room_players for select to authenticated
  using (public.is_room_member(room_id));

grant select on public.rooms to authenticated;
grant select on public.room_players to authenticated;

-- --- Room codes -------------------------------------------------------------
create or replace function app_private.generate_room_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
begin
  loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code || substr(v_alphabet, 1 + floor(random() * 32)::int, 1);
    end loop;
    exit when not exists (select 1 from public.rooms r where r.code = v_code);
  end loop;
  return v_code;
end;
$$;

-- --- Internal: drop a player from every lobby they are in -------------------
create or replace function app_private.leave_all_lobbies(p_user_id uuid)
returns void
language plpgsql
set search_path = ''
as $$
declare
  r record;
begin
  for r in
    select rp.room_id
    from public.room_players rp
    join public.rooms ro on ro.id = rp.room_id
    where rp.user_id = p_user_id and ro.status = 'lobby'
  loop
    perform app_private.remove_from_room(r.room_id, p_user_id);
  end loop;
end;
$$;

-- Removes a seat and repairs the room: promote a new host or cancel.
create or replace function app_private.remove_from_room(p_room_id uuid, p_user_id uuid)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_was_host boolean;
  v_next     uuid;
begin
  select is_host into v_was_host
  from public.room_players
  where room_id = p_room_id and user_id = p_user_id
  for update;

  if not found then
    return;
  end if;

  delete from public.room_players
  where room_id = p_room_id and user_id = p_user_id;

  if v_was_host then
    select user_id into v_next
    from public.room_players
    where room_id = p_room_id
    order by seat
    limit 1;

    if v_next is null then
      update public.rooms
         set status = 'cancelled', last_activity_at = now()
       where id = p_room_id and status = 'lobby';
    else
      update public.room_players
         set is_host = true, is_ready = true
       where room_id = p_room_id and user_id = v_next;
      update public.rooms
         set host_id = v_next, last_activity_at = now()
       where id = p_room_id;
    end if;
  else
    update public.rooms set last_activity_at = now() where id = p_room_id;
  end if;
end;
$$;

-- --- RPC: create_room -------------------------------------------------------
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
  v_user uuid := auth.uid();
  v_room public.rooms;
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
  if p_rules is null or jsonb_typeof(p_rules) <> 'object' then
    raise exception 'invalid_rules' using errcode = '22023';
  end if;

  perform app_private.leave_all_lobbies(v_user);

  insert into public.rooms
    (code, host_id, name, max_players, is_private, turn_timer_seconds, rules)
  values
    (app_private.generate_room_code(), v_user,
     left(btrim(coalesce(p_name, '')), 24), p_max_players,
     coalesce(p_is_private, true), p_turn_timer_seconds, p_rules)
  returning * into v_room;

  insert into public.room_players (room_id, user_id, seat, is_host, is_ready)
  values (v_room.id, v_user, 0, true, true);

  return v_room;
end;
$$;
revoke all on function public.create_room(text, integer, boolean, integer, jsonb) from public, anon;
grant execute on function public.create_room(text, integer, boolean, integer, jsonb) to authenticated;

-- --- RPC: join_room ---------------------------------------------------------
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
  if not found or v_room.status <> 'lobby' then
    raise exception 'room_not_found' using errcode = 'P0002';
  end if;

  -- Already seated here: idempotent.
  if exists (select 1 from public.room_players
             where room_id = v_room.id and user_id = v_user) then
    return v_room;
  end if;

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
revoke all on function public.join_room(text) from public, anon;
grant execute on function public.join_room(text) to authenticated;

-- --- RPC: leave_room --------------------------------------------------------
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
  perform app_private.remove_from_room(p_room_id, v_user);
end;
$$;
revoke all on function public.leave_room(uuid) from public, anon;
grant execute on function public.leave_room(uuid) to authenticated;

-- --- RPC: set_ready ---------------------------------------------------------
create or replace function public.set_ready(p_room_id uuid, p_ready boolean)
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
  update public.room_players
     set is_ready = coalesce(p_ready, false), last_seen_at = now()
   where room_id = p_room_id and user_id = v_user;
  if not found then
    raise exception 'not_a_member' using errcode = '42501';
  end if;
  update public.rooms set last_activity_at = now() where id = p_room_id;
end;
$$;
revoke all on function public.set_ready(uuid, boolean) from public, anon;
grant execute on function public.set_ready(uuid, boolean) to authenticated;

-- --- RPC: room_heartbeat ----------------------------------------------------
create or replace function public.room_heartbeat(p_room_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.room_players
     set last_seen_at = now(), connection = 'online'
   where room_id = p_room_id and user_id = auth.uid();
$$;
revoke all on function public.room_heartbeat(uuid) from public, anon;
grant execute on function public.room_heartbeat(uuid) to authenticated;

-- --- Housekeeping (server-only; schedule with pg_cron later) ----------------
create or replace function app_private.expire_stale_rooms(p_idle interval default interval '30 minutes')
returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_count integer;
begin
  with expired as (
    update public.rooms
       set status = 'cancelled'
     where status = 'lobby' and last_activity_at < now() - p_idle
    returning id
  )
  select count(*) into v_count from expired;
  return v_count;
end;
$$;
