# In-app purchase architecture — Session 7 (2026-08-31)

## The one rule

**The client never decides premium.** A store event is a claim; the server
verifies it with Google/Apple and grants the entitlement with the service
role. A modified APK can *ask*, it cannot *grant* — the same trust model as
the online match (docs/SECURITY.md).

## Final business model (Session 8, 2026-09-01)

The client chose **optional cosmetic one-time purchases** — no
subscription, no consumable currency, no pay-to-win. Five products
(`ShopCatalog`, canonical ids in docs/FINAL_IAP_PRODUCT_IDS.md), each a
**permanent non-consumable** granting one independent server entitlement:

| Product | Entitlement | Unlocks |
|---|---|---|
| `gioco101_table_gold` | `table.gold` | "Tavolo Oro" table theme |
| `gioco101_table_classic` | `table.classic` | "Tavolo Classico" table theme |
| `gioco101_deck_special` | `deck.special` | "Mazzo Inciso Oro" card-face finish (the app's own engraved vector deck, gilded; the free Napoletane deck is never replaced) |
| `gioco101_cardback_gold` | `cardback.gold` | "Oro Reale" card back (backs only, faces untouched) |
| `gioco101_gadget_01` | `gadget.01` | "Sigillo del 101" felt ornament |

There is **no global premium flag**: a player may own none, one, several
or all five (`PurchaseController.owns('table.gold')` etc.). The session-7
placeholder `gioco101_premium` is retired and refused by the server. The
default game — every rule and mode, online and offline — stays free; the
paid items are gated in `SettingsController` selection only
(`entitlementCheck` → `PurchaseController.owns`, wired in
`InitialBinding`), and a revoked entitlement drops the app back to the
free defaults. **No price is ever hard-coded**: the shop shows
`ProductDetails.price` (the store's localized string) or an honest
"unavailable" line; the client re-prices in the consoles with no app
update. The schema still carries `expires_at`, so a future subscription
remains a data change, not a schema change.

## The pieces

### Flutter (`lib/features/purchases/`)

| Piece | Role |
|---|---|
| `PurchaseStore` (application/purchase_store.dart) | The seam over the official `in_app_purchase` plugin (flutter.dev, v3.3.0). `InAppPurchaseStore` on Android/iOS; `UnavailablePurchaseStore` on web/desktop/tests — nothing else ever touches `InAppPurchase.instance`. |
| `PurchaseController` (application/purchase_controller.dart) | Registered **permanent** at boot (`InitialBinding`), so the purchase stream has exactly one subscriber for the app's life — a pending payment can clear, or an unfinished transaction be redelivered, while any screen is up. Owns the whole flow: load → buy/restore → verify → complete → entitlement. One `PurchasePhase` at a time; every async path settles. |
| `EntitlementRepository` (application/entitlement_repository.dart) | Reads the player's own `user_entitlements` rows (RLS-scoped select, one per owned item); sends purchases to the `verify-purchase` Edge Function. `NoBackend` variant for the offline build. |
| `ShopScreen` (presentation/shop_screen.dart) | Route `/shop` ("Negozio"), reached from Settings. Five item cards: preview, name, description, **store-returned price**, buy / "Sbloccato" + select. "Ripristina acquisti" and the legal links at the bottom. Italian primary copy, English localized. |
| `ShopCatalog` (domain/shop_catalog.dart) | The five canonical products: id ↔ entitlement ↔ cosmetic. Fixed by contract with the consoles — not build-time configurable. |

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
- **Migration 13** `20260831201759_cosmetic_entitlements.sql`:
  `srv_grant_entitlement` now takes the **entitlement key** (derived
  server-side from the product map — a client names a product, never an
  entitlement); `srv_revoke_entitlement` can revoke one entitlement or the
  whole account; the `'premium'` column default is dropped. The Session 8
  attack drill re-ran live on dev (2026-09-01): client INSERT/UPDATE
  refused (42501), `srv_*` refused for `authenticated`, same-user replay
  idempotent, cross-user replay `transaction_owned_elsewhere`, second
  entitlement coexists, scoped revoke touches only its row, RLS shows 0
  foreign rows / exactly the owner's own; drill rows cleaned up; advisors
  show nothing new.
- **Edge Function `verify-purchase`** (v2 on GiocoDel101-Dev,
  `verify_jwt: true`): authenticate → validate shape → **five-product
  allow-list + entitlement map** (`PRODUCT_ENTITLEMENTS` in verify.ts —
  code, not env; `PREMIUM_PRODUCT_IDS` is no longer read) → store
  verification → grant → reply.
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
