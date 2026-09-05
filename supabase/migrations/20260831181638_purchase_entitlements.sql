-- =============================================================================
-- Gioco del 101 — Session 7, migration 12: premium entitlements.
--
--   user_entitlements       one row per player: the authoritative premium
--   purchase_transactions   every store transaction the server verified,
--                           unique per (platform, store transaction id)
--   srv_grant_entitlement   service_role only — called by the
--                           `verify-purchase` Edge Function AFTER the store
--                           confirmed the purchase
--   srv_revoke_entitlement  service_role only — refunds / expiry
--
-- The client may READ its own rows and nothing else. No RPC lets a client
-- write, extend or verify anything: a modified APK can ask for premium, it
-- cannot give itself premium (docs/SECURITY.md).
-- =============================================================================

create table public.user_entitlements (
  user_id      uuid not null references public.profiles(id) on delete cascade,
  entitlement  text not null default 'premium',
  status       text not null check (status in ('active', 'expired', 'revoked')),
  platform     text not null check (platform in ('android', 'ios')),
  product_id   text not null,
  purchased_at timestamptz not null default now(),
  -- Null = lifetime (non-consumable). A subscription writes its renewal
  -- horizon here; store server notifications move it.
  expires_at   timestamptz,
  verified_at  timestamptz not null default now(),
  environment  text not null default 'production'
               check (environment in ('production', 'sandbox')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  primary key (user_id, entitlement)
);
comment on table public.user_entitlements is
  'Authoritative premium per player. Written only by srv_grant_entitlement / '
  'srv_revoke_entitlement (service_role); clients read their own row.';

alter table public.user_entitlements enable row level security;
create policy "user_entitlements: read own row"
  on public.user_entitlements for select to authenticated
  using (user_id = (select auth.uid()));
grant select on public.user_entitlements to authenticated;

create table public.purchase_transactions (
  id                      uuid primary key default gen_random_uuid(),
  user_id                 uuid not null references public.profiles(id) on delete cascade,
  platform                text not null check (platform in ('android', 'ios')),
  product_id              text not null,
  store_transaction_id    text not null,
  original_transaction_id text,
  status                  text not null check (status in ('verified', 'rejected')),
  environment             text not null default 'production'
                          check (environment in ('production', 'sandbox')),
  created_at              timestamptz not null default now(),
  -- The replay guard: one store transaction grants once, to one account.
  unique (platform, store_transaction_id)
);
create index purchase_transactions_user_idx
  on public.purchase_transactions (user_id);
comment on table public.purchase_transactions is
  'Verified store transactions. No secrets, no receipts — identifiers only.';

alter table public.purchase_transactions enable row level security;
create policy "purchase_transactions: read own rows"
  on public.purchase_transactions for select to authenticated
  using (user_id = (select auth.uid()));
grant select on public.purchase_transactions to authenticated;

-- --- Grant (service_role only) ----------------------------------------------
-- Idempotent on (platform, store transaction id):
--   * unseen transaction        → record it, upsert the entitlement active
--   * same user re-sends it     → re-answer the same grant (app restarts,
--                                 redelivered purchase updates)
--   * ANOTHER user replays it   → refused: a leaked token cannot buy premium
--                                 for a second account
create or replace function public.srv_grant_entitlement(
  p_user        uuid,
  p_platform    text,
  p_product     text,
  p_store_txn   text,
  p_original_txn text default null,
  p_expires     timestamptz default null,
  p_environment text default 'production'
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner uuid;
  v_row   public.user_entitlements;
begin
  if p_user is null or p_platform not in ('android', 'ios')
     or coalesce(p_store_txn, '') = '' or coalesce(p_product, '') = '' then
    return jsonb_build_object('error', 'invalid_grant');
  end if;

  select user_id into v_owner
    from public.purchase_transactions
   where platform = p_platform and store_transaction_id = p_store_txn;
  if v_owner is not null and v_owner <> p_user then
    return jsonb_build_object('error', 'transaction_owned_elsewhere');
  end if;

  if v_owner is null then
    insert into public.purchase_transactions
      (user_id, platform, product_id, store_transaction_id,
       original_transaction_id, status, environment)
    values
      (p_user, p_platform, p_product, p_store_txn,
       p_original_txn, 'verified', p_environment)
    on conflict (platform, store_transaction_id) do nothing;
  end if;

  insert into public.user_entitlements as ue
    (user_id, status, platform, product_id, purchased_at,
     expires_at, verified_at, environment)
  values
    (p_user, 'active', p_platform, p_product, now(),
     p_expires, now(), p_environment)
  on conflict (user_id, entitlement) do update set
    status      = 'active',
    platform    = excluded.platform,
    product_id  = excluded.product_id,
    -- Null means lifetime and lifetime wins; otherwise keep the later horizon.
    expires_at  = case
                    when ue.expires_at is null or excluded.expires_at is null
                      then null
                    else greatest(ue.expires_at, excluded.expires_at)
                  end,
    verified_at = now(),
    environment = excluded.environment,
    updated_at  = now()
  returning * into v_row;

  return jsonb_build_object('ok', true, 'entitlement', to_jsonb(v_row));
end;
$$;
revoke all on function public.srv_grant_entitlement(uuid, text, text, text, text, timestamptz, text)
  from public, anon, authenticated;
grant execute on function public.srv_grant_entitlement(uuid, text, text, text, text, timestamptz, text)
  to service_role;

-- --- Revoke / expire (service_role only) ------------------------------------
-- Refund and subscription-lifecycle handling: store server notifications
-- (Google RTDN / Apple App Store Server Notifications) land here when the
-- client wires them up on the store side.
create or replace function public.srv_revoke_entitlement(
  p_user   uuid,
  p_status text default 'revoked'
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.user_entitlements;
begin
  if p_status not in ('revoked', 'expired') then
    return jsonb_build_object('error', 'invalid_status');
  end if;
  update public.user_entitlements
     set status = p_status, updated_at = now()
   where user_id = p_user
  returning * into v_row;
  if v_row is null then
    return jsonb_build_object('error', 'not_found');
  end if;
  return jsonb_build_object('ok', true, 'entitlement', to_jsonb(v_row));
end;
$$;
revoke all on function public.srv_revoke_entitlement(uuid, text)
  from public, anon, authenticated;
grant execute on function public.srv_revoke_entitlement(uuid, text)
  to service_role;
