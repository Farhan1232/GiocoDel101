-- =============================================================================
-- Gioco del 101 — Session 8, migration 13: per-item cosmetic entitlements.
--
-- The provisional single "premium" unlock becomes five independent permanent
-- cosmetics (docs/FINAL_IAP_PRODUCT_IDS.md):
--
--   gioco101_table_gold      → table.gold
--   gioco101_table_classic   → table.classic
--   gioco101_deck_special    → deck.special
--   gioco101_cardback_gold   → cardback.gold
--   gioco101_gadget_01       → gadget.01
--
-- The schema was already keyed (user_id, entitlement); what changes is that
-- the ENTITLEMENT IS NOW EXPLICIT: srv_grant_entitlement takes the key the
-- verify-purchase function derived from its own product map — the client
-- names a product, never an entitlement, and the function's allow-list
-- decides. A user may own none, one, several or all five rows.
--
-- Trust model unchanged (docs/SECURITY.md): clients read their own rows;
-- writes happen only through these service_role functions after a store-side
-- verification.
-- =============================================================================

-- The old implicit default granted 'premium' to anything that forgot to say
-- which item it bought. Nothing may be granted implicitly any more.
alter table public.user_entitlements alter column entitlement drop default;

-- --- Grant (service_role only) ----------------------------------------------
-- Signature change (p_entitlement added): drop the session-7 function.
drop function if exists public.srv_grant_entitlement(
  uuid, text, text, text, text, timestamptz, text);

create or replace function public.srv_grant_entitlement(
  p_user        uuid,
  p_entitlement text,
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
     or coalesce(p_store_txn, '') = '' or coalesce(p_product, '') = ''
     or coalesce(p_entitlement, '') = '' then
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
    (user_id, entitlement, status, platform, product_id, purchased_at,
     expires_at, verified_at, environment)
  values
    (p_user, p_entitlement, 'active', p_platform, p_product, now(),
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
revoke all on function public.srv_grant_entitlement(
    uuid, text, text, text, text, text, timestamptz, text)
  from public, anon, authenticated;
grant execute on function public.srv_grant_entitlement(
    uuid, text, text, text, text, text, timestamptz, text)
  to service_role;

-- --- Revoke / expire (service_role only) ------------------------------------
-- Now names WHICH entitlement it touches; null keeps the old whole-account
-- sweep for a store-side refund of everything.
drop function if exists public.srv_revoke_entitlement(uuid, text);

create or replace function public.srv_revoke_entitlement(
  p_user        uuid,
  p_status      text default 'revoked',
  p_entitlement text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rows jsonb;
begin
  if p_status not in ('revoked', 'expired') then
    return jsonb_build_object('error', 'invalid_status');
  end if;
  with changed as (
    update public.user_entitlements
       set status = p_status, updated_at = now()
     where user_id = p_user
       and (p_entitlement is null or entitlement = p_entitlement)
    returning *
  )
  select jsonb_agg(to_jsonb(changed)) into v_rows from changed;
  if v_rows is null then
    return jsonb_build_object('error', 'not_found');
  end if;
  return jsonb_build_object('ok', true, 'entitlements', v_rows);
end;
$$;
revoke all on function public.srv_revoke_entitlement(uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.srv_revoke_entitlement(uuid, text, text)
  to service_role;
