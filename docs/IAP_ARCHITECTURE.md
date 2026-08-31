# In-app purchase architecture — Session 7 (2026-08-31)

## The one rule

**The client never decides premium.** A store event is a claim; the server
verifies it with Google/Apple and grants the entitlement with the service
role. A modified APK can *ask*, it cannot *grant* — the same trust model as
the online match (docs/SECURITY.md).

## Provisional business model

The brief said only "integration of the purchase system" — no product, no
price, no subscription period. What is built: a single **one-time
(non-consumable) "Premium" unlock**, product id configurable
(`PurchaseConfig`, default placeholder `gioco101_premium`). The schema and
the verifiers already carry `expires_at` and environment, so a subscription
is a data/config change, not a schema change. **Open decisions for the
client** (docs/IAP_STORE_SETUP.md): real product ids, price points,
one-time vs subscription, and **what premium actually unlocks** — no
existing feature was put behind a paywall; the entitlement is plumbed,
displayed on the Premium screen, and readable anywhere via
`Get.find<PurchaseController>().isPremium`.

## The pieces

### Flutter (`lib/features/purchases/`)

| Piece | Role |
|---|---|
| `PurchaseStore` (application/purchase_store.dart) | The seam over the official `in_app_purchase` plugin (flutter.dev, v3.3.0). `InAppPurchaseStore` on Android/iOS; `UnavailablePurchaseStore` on web/desktop/tests — nothing else ever touches `InAppPurchase.instance`. |
| `PurchaseController` (application/purchase_controller.dart) | Registered **permanent** at boot (`InitialBinding`), so the purchase stream has exactly one subscriber for the app's life — a pending payment can clear, or an unfinished transaction be redelivered, while any screen is up. Owns the whole flow: load → buy/restore → verify → complete → entitlement. One `PurchasePhase` at a time; every async path settles. |
| `EntitlementRepository` (application/entitlement_repository.dart) | Reads the player's own `user_entitlements` row (RLS-scoped select); sends purchases to the `verify-purchase` Edge Function. `NoBackend` variant for the offline build. |
| `PremiumScreen` (presentation/premium_screen.dart) | Route `/premium`, reached from Settings. Title/description/**price** come from `ProductDetails` — no hard-coded price anywhere. Buttons: buy, "Ripristina acquisti". Italian primary copy, English localized. |
| `PurchaseConfig` (domain/purchase_config.dart) | Product ids, overridable with `--dart-define=PREMIUM_PRODUCT_ID_ANDROID/IOS`. |

### Purchase flow

```
buy() ──▶ store payment sheet ──▶ purchaseStream update
  pending    → phase purchasing
  canceled   → phase error(cancelled); transaction completed (closed)
  error      → phase error(paymentFailed); transaction completed
  purchased/restored:
      ├─ already handled this session? → completePurchase only (idempotent)
      ├─ verify-purchase Edge Function (JWT of THIS user + token/receipt)
      │     ├─ ok → adopt server entitlement → completePurchase → success
      │     └─ fail → transaction NOT completed → error, retryable
      │              (the store redelivers it; a server hiccup cannot
      │               eat a payment, and Android auto-refunds an
      │               unacknowledged purchase after 3 days)
```

### Restore

`restore()` → `restorePurchases()`; restorations arrive on the same stream
and take the same verification path (idempotent server-side — re-answering
the same grant, never charging). If the store stays silent, an 8 s fallback
re-reads the server entitlement and settles the UI either way ("Nessun
acquisto da ripristinare" when there is nothing).

### Server (Supabase)

- **Migration 12** `20260831181638_purchase_entitlements.sql`:
  - `user_entitlements` — the authoritative premium: status
    (`active|expired|revoked`), platform, product, `expires_at`
    (null = lifetime), environment. PK `(user_id, entitlement)`.
  - `purchase_transactions` — every verified store transaction,
    **unique (platform, store_transaction_id)**: the replay guard.
  - RLS: `SELECT` own rows only, for `authenticated`. **No client write
    path exists at all** — no insert/update policy, no client-callable RPC.
  - `srv_grant_entitlement` / `srv_revoke_entitlement` — SECURITY DEFINER,
    `EXECUTE` revoked from everyone but `service_role`. Grant is idempotent
    per store transaction; a transaction already recorded for another
    account answers `transaction_owned_elsewhere`.
- **Edge Function `verify-purchase`** (v1 on GiocoDel101-Dev,
  `verify_jwt: true`): authenticate → validate shape → product allow-list
  (`PREMIUM_PRODUCT_IDS` env) → store verification → grant → reply.
  - **Android**: Google Play Developer API
    (`purchases.products.get`), service-account JWT signed in-function
    (WebCrypto RS256). Needs `GOOGLE_SERVICE_ACCOUNT_JSON` +
    `ANDROID_PACKAGE_NAME`.
  - **iOS**: `/verifyReceipt` with the documented 21007 sandbox retry and a
    bundle-id check. Needs `APPLE_BUNDLE_ID` (+ `APPLE_SHARED_SECRET` for
    subscriptions). Moving to the App Store Server API is noted in the
    store-setup doc once an App Store Connect API key exists.
  - **Without credentials the function answers 503
    `verification_unconfigured` and grants nothing.** Verification is never
    faked. The Flutter side shows honest copy and leaves the transaction
    open for retry.

### Subscriptions later (§26)

Not enabled — the client has not chosen a subscription. The path is laid:
`expires_at` + `status` can represent active / expired / revoked /
cancelled-until-expiry; `srv_revoke_entitlement` is the hook a store
server-notification endpoint (Google RTDN / Apple ASSN) would call. That
endpoint does not exist yet and must not be improvised before the client
picks a model.

## Security model, verified live on GiocoDel101-Dev

All run against the dev database (2026-08-31):

| Attack | Result |
|---|---|
| authenticated client INSERTs its own entitlement | refused (no policy, no grant) |
| authenticated client UPDATEs status/expiry | refused |
| client calls `srv_grant_entitlement` / `srv_revoke_entitlement` | refused (`insufficient_privilege`) |
| replay the same store transaction, same user | idempotent — same grant re-answered |
| replay another user's transaction id | `transaction_owned_elsewhere` (409 at the function) |
| user B reads user A's entitlement/transactions | 0 rows (RLS); owner sees exactly their own |
| unknown product id | refused before any store call |
| forged verification payload | never reaches a grant: the store verifier decides, and without credentials nothing verifies |
| Supabase security advisors after the migration | no new findings beyond the project's intended guest-access design; the `srv_*` functions do **not** appear in the client-executable list |

## Guests (§31)

Guests are `authenticated` (anonymous sign-in), so a guest *can* buy; the
entitlement binds to that account. Store-side, the purchase belongs to the
Google/Apple account, so "Ripristina acquisti" recovers it onto any signed-in
game account on the same device/store — that is the recovery story if a
guest account is lost. The Premium screen requires being signed in; the
existing guest→registered upgrade keeps the same user id, so nothing is lost
on upgrade. Whether guests should be blocked from buying is a client call.

## Tests

- `test/session7_iap_test.dart` — 18 cases against fakes: store
  unavailable / product missing / loaded, pending, cancelled, failed,
  success, verification failure leaves the transaction open and retry
  succeeds, duplicate delivery verifies once, network failure grants
  nothing, restore (event, silent-fallback, nothing-to-restore), expired /
  revoked / future-expiry entitlements, no-backend safety, and the
  purchase-stream listener count staying exactly 1 until `onClose`.
- `supabase/functions/verify-purchase/verify_test.ts` — 5 Deno tests:
  request validation, product allow-list, transaction-id precedence, and
  both providers refusing (never fake-verifying) without credentials.
