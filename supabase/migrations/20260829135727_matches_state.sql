-- =============================================================================
-- Gioco del 101 — Session 3, migration 3/4: matches and the split state model.
--
-- One match has FOUR representations, and only the first three are visible:
--
--   match_public_state    (public)      the redacted GameState every seat may
--                                       see: top card, active suit, whose turn,
--                                       scores, hand COUNTS, draw-pile COUNT.
--   match_private_state   (public)      one row per (match, player): that
--                                       player's own hand. RLS: own row only.
--   match_actions         (public)      the accepted/rejected action log.
--   match_engine_state    (app_private) the FULL GameState incl. seed and the
--                                       ordered drawPile. No client grant, and
--                                       the schema is not exposed at all.
--
-- The client never receives another player's hand or the deck order because
-- those bytes are never in a row it can select — not because the UI hides
-- them. Session 4's authoritative function applies GameAction via the Dart
-- engine and calls app_private.publish_match_state to fan the result out.
-- =============================================================================

create type public.match_status as enum ('in_progress', 'finished', 'abandoned');

create table public.matches (
  id           uuid primary key default gen_random_uuid(),
  room_id      uuid references public.rooms (id) on delete set null,
  status       public.match_status not null default 'in_progress',
  rules        jsonb not null,
  player_count smallint not null check (player_count between 2 and 4),
  winner_id    uuid references public.profiles (id) on delete set null,
  started_at   timestamptz not null default now(),
  finished_at  timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index matches_room_idx on public.matches (room_id);
create index matches_finished_idx on public.matches (finished_at desc) where status = 'finished';

create trigger matches_set_updated_at
  before update on public.matches
  for each row execute function app_private.set_updated_at();

alter table public.rooms
  add constraint rooms_match_id_fkey
  foreign key (match_id) references public.matches (id) on delete set null;

create table public.match_players (
  match_id         uuid not null references public.matches (id) on delete cascade,
  user_id          uuid not null references public.profiles (id) on delete cascade,
  seat             smallint not null check (seat between 0 and 3),
  engine_player_id text not null,        -- the id used inside GameState ('p0'...)
  final_score      integer,
  placement        smallint check (placement between 1 and 4),
  is_winner        boolean not null default false,
  rating_before    integer,
  rating_after     integer,
  xp_awarded       integer not null default 0,
  connection       public.connection_state not null default 'online',
  last_seen_at     timestamptz not null default now(),
  left_at          timestamptz,
  primary key (match_id, user_id),
  unique (match_id, seat),
  unique (match_id, engine_player_id)
);
create index match_players_user_idx on public.match_players (user_id);

create table public.match_public_state (
  match_id   uuid primary key references public.matches (id) on delete cascade,
  version    integer not null default 0,
  state      jsonb not null,
  updated_at timestamptz not null default now()
);
comment on table public.match_public_state is
  'Redacted GameState (no seed, no drawPile, no hands, no drawnCard). Produced only by app_private.redact_game_state.';

create table public.match_private_state (
  match_id   uuid not null references public.matches (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  version    integer not null default 0,
  hand       jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (match_id, user_id)
);
comment on table public.match_private_state is
  'One row per seat holding that player''s hand. RLS restricts every read to the owner.';

create table app_private.match_engine_state (
  match_id   uuid primary key references public.matches (id) on delete cascade,
  version    integer not null default 0,
  state      jsonb not null,
  updated_at timestamptz not null default now()
);
comment on table app_private.match_engine_state is
  'The authoritative GameState including seed and the ordered drawPile. Never exposed.';

create table public.match_actions (
  id         bigint generated always as identity primary key,
  match_id   uuid not null references public.matches (id) on delete cascade,
  version    integer not null,             -- the state version the action targeted
  actor_id   uuid references public.profiles (id) on delete set null,  -- null = system
  action     jsonb not null,               -- GameAction.toJson()
  accepted   boolean not null,
  failure    text,                         -- GameFailure name when rejected
  created_at timestamptz not null default now()
);
create index match_actions_match_version_idx on public.match_actions (match_id, version);

-- --- Membership helper ------------------------------------------------------
create or replace function public.is_match_member(p_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.match_players mp
    where mp.match_id = p_match_id and mp.user_id = auth.uid()
  );
$$;
revoke all on function public.is_match_member(uuid) from public, anon;
grant execute on function public.is_match_member(uuid) to authenticated;

-- --- RLS --------------------------------------------------------------------
alter table public.matches             enable row level security;
alter table public.match_players       enable row level security;
alter table public.match_public_state  enable row level security;
alter table public.match_private_state enable row level security;
alter table public.match_actions       enable row level security;
alter table app_private.match_engine_state enable row level security;  -- no policies: nobody but owner

create policy "matches: visible to its players"
  on public.matches for select to authenticated
  using (public.is_match_member(id));

create policy "match_players: visible to players of the match"
  on public.match_players for select to authenticated
  using (public.is_match_member(match_id));

create policy "match_public_state: visible to players of the match"
  on public.match_public_state for select to authenticated
  using (public.is_match_member(match_id));

create policy "match_private_state: only your own hand"
  on public.match_private_state for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "match_actions: visible to players of the match"
  on public.match_actions for select to authenticated
  using (public.is_match_member(match_id));

grant select on public.matches, public.match_players, public.match_public_state,
                public.match_private_state, public.match_actions
  to authenticated;
-- No INSERT/UPDATE/DELETE grant on any of these: results are server-written.

-- --- Redaction (the contract Session 4 must honour) -------------------------
-- Strips everything that reveals hidden information from GameState.toJson():
--   seed, drawPile (-> drawPileCount), drawnCard, history, and every
--   players[].hand (-> handCount).
create or replace function app_private.redact_game_state(p_state jsonb)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select (p_state - 'seed' - 'drawPile' - 'drawnCard' - 'history')
      || jsonb_build_object(
           'drawPileCount', jsonb_array_length(coalesce(p_state -> 'drawPile', '[]'::jsonb)),
           'players', (
             select coalesce(jsonb_agg(
               (pl - 'hand')
               || jsonb_build_object('handCount',
                    jsonb_array_length(coalesce(pl -> 'hand', '[]'::jsonb)))
               order by ord), '[]'::jsonb)
             from jsonb_array_elements(coalesce(p_state -> 'players', '[]'::jsonb))
                  with ordinality as t(pl, ord)
           )
         );
$$;

create or replace function app_private.hand_of(p_state jsonb, p_engine_player_id text)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select coalesce((
    select pl -> 'hand'
    from jsonb_array_elements(coalesce(p_state -> 'players', '[]'::jsonb)) as pl
    where pl ->> 'id' = p_engine_player_id
    limit 1
  ), '[]'::jsonb);
$$;

-- Writes the engine state and derives the public + private rows atomically.
-- Server-only (no grant): called by the Session 4 authoritative function.
create or replace function app_private.publish_match_state(p_match_id uuid, p_state jsonb)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_version integer := coalesce((p_state ->> 'version')::integer, 0);
  v_status  text    := p_state ->> 'status';
begin
  insert into app_private.match_engine_state (match_id, version, state)
  values (p_match_id, v_version, p_state)
  on conflict (match_id) do update
    set version = excluded.version, state = excluded.state, updated_at = now();

  insert into public.match_public_state (match_id, version, state)
  values (p_match_id, v_version, app_private.redact_game_state(p_state))
  on conflict (match_id) do update
    set version = excluded.version, state = excluded.state, updated_at = now();

  insert into public.match_private_state (match_id, user_id, version, hand)
  select p_match_id, mp.user_id, v_version,
         app_private.hand_of(p_state, mp.engine_player_id)
  from public.match_players mp
  where mp.match_id = p_match_id
  on conflict (match_id, user_id) do update
    set version = excluded.version, hand = excluded.hand, updated_at = now();

  if v_status = 'finished' then
    update public.matches
       set status = 'finished', finished_at = coalesce(finished_at, now())
     where id = p_match_id and status = 'in_progress';
  end if;
end;
$$;
