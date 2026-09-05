-- =============================================================================
-- Gioco del 101 — Session 3, migration 5: covering indexes for foreign keys.
-- Raised by the Supabase performance advisor (unindexed_foreign_keys). Pure
-- performance; no change to grants, policies or shapes.
-- =============================================================================

create index if not exists match_actions_actor_idx           on public.match_actions (actor_id);
create index if not exists match_private_state_user_idx      on public.match_private_state (user_id);
create index if not exists matches_winner_idx                on public.matches (winner_id);
create index if not exists profiles_avatar_idx               on public.profiles (avatar_id);
create index if not exists rooms_match_idx                   on public.rooms (match_id);
create index if not exists user_achievements_achievement_idx on public.user_achievements (achievement_id);
create index if not exists user_daily_missions_mission_idx   on public.user_daily_missions (mission_id);
