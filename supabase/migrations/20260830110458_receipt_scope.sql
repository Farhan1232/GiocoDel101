-- Session 6 follow-up: the receipt lookup inside srv_commit_action (under
-- the engine-row lock) is scoped to the actor like srv_find_receipt. Found by
-- the matrix's hardening area: another seat reusing a refused action id was
-- still answered with the first seat's receipt.

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
      -- A receipt belongs to the seat that earned it. Another seat presenting
      -- the same id (a leaked or guessed uuid) is refused outright rather
      -- than handed somebody else's answer.
      if v_receipt.user_id is distinct from p_actor then
        raise exception 'action_id_taken' using errcode = 'P0013';
      end if;
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
