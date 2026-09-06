-- Complimentary accounts: the owner's own test logins own every cosmetic,
-- for free, for life.
--
-- Google Play's licence testers are not charged, but a licence test still has
-- to go all the way through Google, and it cannot help at all before the five
-- products exist and are ACTIVE in the console. This is the other half: an
-- allow-list of email addresses that simply own the five entitlements, so the
-- owner can see and use the paid tables, deck, back and gadget while the
-- store side is still being set up.
--
-- It lives entirely on the server. The app has no idea this exists: it asks
-- "what do I own?" and is told. So the list can be changed or emptied with
-- one statement and no new build, and nothing in a shipped APK grants
-- anything to anyone.
--
-- Rows are written with environment = 'sandbox', which is what they are: not
-- purchases. Real receipts from `verify-purchase` stay 'production', so the
-- two can always be told apart.
create table if not exists app_private.comp_accounts (
  email      text primary key,
  note       text,
  created_at timestamptz not null default now()
);

comment on table app_private.comp_accounts is
  'Emails that own every cosmetic without paying. Owner test accounts only.';

-- Grants the five cosmetics to one user. Idempotent, and it re-activates a
-- row that had been revoked.
create or replace function app_private.grant_comp_entitlements(p_user uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_granted integer;
begin
  insert into public.user_entitlements (
    user_id, entitlement, status, platform, product_id,
    purchased_at, expires_at, verified_at, environment
  )
  select p_user, m.entitlement, 'active', 'android', m.product_id,
         now(), null, now(), 'sandbox'
  from (values
    ('table.gold',     'gioco101_table_gold'),
    ('table.classic',  'gioco101_table_classic'),
    ('deck.special',   'gioco101_deck_special'),
    ('cardback.gold',  'gioco101_cardback_gold'),
    ('gadget.01',      'gioco101_gadget_01')
  ) as m(entitlement, product_id)
  on conflict (user_id, entitlement) do update
    set status      = 'active',
        expires_at  = null,
        verified_at = now(),
        updated_at  = now();

  get diagnostics v_granted = row_count;
  return v_granted;
end;
$$;

revoke all on function app_private.grant_comp_entitlements(uuid) from public, anon, authenticated;

-- A profile is created the moment an account is, so this catches a comp
-- address however it signs up — and again if the account is deleted and made
-- afresh, which is exactly what testing the "Elimina account" button does.
create or replace function app_private.comp_account_on_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text;
begin
  select lower(u.email) into v_email from auth.users u where u.id = new.id;
  if v_email is null then
    return new;
  end if;
  if exists (select 1 from app_private.comp_accounts c where c.email = v_email)
  then
    perform app_private.grant_comp_entitlements(new.id);
  end if;
  return new;
end;
$$;

drop trigger if exists comp_account_grant on public.profiles;
create trigger comp_account_grant
  after insert on public.profiles
  for each row execute function app_private.comp_account_on_profile();

-- The owner's account.
insert into app_private.comp_accounts (email, note)
values ('dartuveer@gmail.com', 'Owner / Play Console test account')
on conflict (email) do nothing;

-- Backfill anyone already registered with a listed address.
do $$
declare
  v_id uuid;
begin
  for v_id in
    select u.id
    from auth.users u
    join app_private.comp_accounts c on c.email = lower(u.email)
    join public.profiles p on p.id = u.id
  loop
    perform app_private.grant_comp_entitlements(v_id);
  end loop;
end;
$$;
