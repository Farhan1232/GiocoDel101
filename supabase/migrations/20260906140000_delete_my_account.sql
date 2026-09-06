-- Account deletion, asked for by the player themselves.
--
-- Google Play requires any app that creates accounts to offer a way to
-- delete one, from inside the app as well as from a web page. This is the
-- server half: one RPC the signed-in player calls for their OWN account and
-- nothing else — `auth.uid()` is the only identity it will act on, so there
-- is no id to tamper with.
--
-- Everything the account owns goes with it. `public.profiles` cascades from
-- `auth.users`, and every game table cascades from `profiles`, so a single
-- delete removes: the profile, nickname and avatar, player stats, rooms and
-- seats, match participation, private hands, achievements, daily rewards,
-- missions, weekly points, the matchmaking queue row, entitlements and the
-- purchase receipts we hold. Matches other people played keep existing —
-- their references to this player become NULL rather than deleting somebody
-- else's history.
--
-- The purchases themselves are NOT lost to the player: Google Play and the
-- App Store remain the merchant of record, so a new account can restore them
-- with "Ripristina acquisti".
create or replace function public.delete_my_account()
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

  -- Deleting mid-match would cascade the seat away underneath the other
  -- players. Finish or leave the match first; the app says so in words.
  perform app_private.assert_not_in_match(v_user);

  -- A lobby seat is harmless to vacate, so do it rather than refuse.
  perform app_private.leave_all_lobbies(v_user);

  delete from auth.users where id = v_user;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
