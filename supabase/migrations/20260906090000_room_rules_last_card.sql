-- Room rules: accept `requireLastCardDeclaration`.
--
-- `app_private.sanitize_room_rules` is an allow-list: a key it does not know
-- makes the whole call fail with `invalid_rules`. It was written (migration
-- 20260830100111) against the GameRules of the day. `requireLastCardDeclaration`
-- — the ULTIMA CARTA switch — was added to `GameRules.toJson()` afterwards and
-- never reached this list, so from that moment EVERY `create_room` sent by the
-- app was refused: the Create Room button could only ever show "Impossibile
-- aprire la stanza", and with no code there was no way into an online match.
-- The tools that exercise the backend directly (tool/online_matrix.dart) build
-- their own minimal rules object, which is why they never saw it.
--
-- The engine that deals the match (supabase/functions/match/engine.js, the same
-- Dart engine compiled to JS) already understands the flag, so passing it
-- through is exactly right: the room plays by the rules the host chose.
--
-- If a rule is ever added to `GameRules.toJson()` again, it has to be added
-- here too — `test/session9_client_fixes_test.dart` fails when the two drift.
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
    "requireLastCardDeclaration": "boolean",
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
