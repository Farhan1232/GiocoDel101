-- =============================================================================
-- Gioco del 101 — Session 4, migration 7: the private-channel policy helper
-- must live where the policy's role can call it.
--
-- realtime.messages policies run as the subscribing role (`authenticated`),
-- which has no USAGE on app_private — so migration 6's policies raised
-- "permission denied for schema app_private" for members (Realtime reports
-- that as MissingPartition / Unauthorized). The helper only parses a topic
-- string; it carries no data and is safe in public.
-- =============================================================================

create or replace function public.match_topic_id(p_topic text)
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
revoke all on function public.match_topic_id(text) from public, anon;
grant execute on function public.match_topic_id(text) to authenticated, service_role;

drop policy if exists "match channel: members receive broadcast and presence" on realtime.messages;
drop policy if exists "match channel: members track presence only" on realtime.messages;

create policy "match channel: members receive broadcast and presence"
  on realtime.messages for select to authenticated
  using (
    realtime.messages.extension in ('broadcast', 'presence')
    and public.is_match_member(public.match_topic_id((select realtime.topic())))
  );
create policy "match channel: members track presence only"
  on realtime.messages for insert to authenticated
  with check (
    realtime.messages.extension = 'presence'
    and public.is_match_member(public.match_topic_id((select realtime.topic())))
  );

drop function if exists app_private.match_id_of_topic(text);
