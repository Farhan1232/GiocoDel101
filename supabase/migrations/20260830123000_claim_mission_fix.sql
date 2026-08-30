-- =============================================================================
-- Gioco del 101 — Session 5, migration 9: claim_mission_reward column fix.
--
-- The function declares `returns table (mission_id, …, completed_at, …)`,
-- which makes those names PL/pgSQL variables; the unqualified references in
-- the body were therefore ambiguous ("column reference mission_id is
-- ambiguous") and every claim failed. Found by tool/progression_smoke.dart.
-- Same contract, table references now qualified.
-- =============================================================================

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
#variable_conflict use_column
declare
  v_user    uuid := auth.uid();
  v_mission public.daily_missions;
  v_row     public.user_daily_missions;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(hashtext('mission_claim:' || v_user::text));

  select dm.* into v_mission from public.daily_missions dm where dm.id = p_mission_id;
  if not found or v_mission.mission_date <> app_private.today_rome() then
    raise exception 'mission_expired' using errcode = 'P0001';
  end if;
  select um.* into v_row from public.user_daily_missions um
   where um.user_id = v_user and um.mission_id = p_mission_id
   for update;
  if not found or v_row.progress < v_mission.target then
    raise exception 'not_completed' using errcode = 'P0001';
  end if;
  if v_row.claimed_at is not null then
    raise exception 'already_claimed' using errcode = 'P0001';
  end if;

  update public.user_daily_missions um
     set claimed_at = now(), completed_at = coalesce(um.completed_at, now())
   where um.user_id = v_user and um.mission_id = p_mission_id;
  perform app_private.grant_xp(v_user, v_mission.reward_xp);
  if v_mission.reward_coins > 0 then
    update public.player_stats ps set coins = ps.coins + v_mission.reward_coins where ps.user_id = v_user;
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
