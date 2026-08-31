# Store setup — the five cosmetic products (client checklist)

Session 8 (2026-09-01). The code and the server are complete
(docs/IAP_ARCHITECTURE.md): five permanent, one-time, cosmetic-only
purchases; server-verified ownership; Restore Purchases; Terms & Privacy
screens. Everything below needs the **client's store accounts** and cannot
be done from this repository. Until it is done, the app answers honestly:
the Shop shows "not yet available in the store" (console side missing) or
"verification not live yet" (server credentials missing), and **nothing is
ever granted or charged**.

## The five products — create these EXACT ids in BOTH consoles

```
gioco101_table_gold
gioco101_table_classic
gioco101_deck_special
gioco101_cardback_gold
gioco101_gadget_01
```

- Type: **one-time / non-consumable** (Google Play: "In-app product";
  Apple: "Non-Consumable").
- Initial price: **about €4.99 / €5.00 EUR each** (pick the closest store
  price tier). The price can be changed later in the consoles at any time —
  the app always displays the store's own localized price and needs **no
  code change** for a re-price.
- Full details per product: `docs/FINAL_IAP_PRODUCT_IDS.md`.

## Google Play Console — step by step

1. Open (or create) the app with package id
   **`it.giocodel101.gioco_del_101`** (verified against
   `android/app/build.gradle.kts`).
2. Products → In-app products → Create: make the **five** products with the
   exact ids above. Names/descriptions can start from
   `docs/FINAL_IAP_PRODUCT_IDS.md` (Italian primary).
3. Set the initial price ≈ **€4.99** each (Italy/EUR base; let Play convert
   the other territories or adjust per country).
4. **Activate** all five products.
5. Configure **license testers** (Play Console → Settings → License
   testing) so test purchases are never charged.
6. Create an **upload keystore** and give us (or configure)
   `android/key.properties` — Play rejects debug-signed bundles. See
   "Signing" in DELIVERY_README.md. Never commit the keystore.
7. Upload the signed **app-release.aab** to the **Internal testing** track
   (Play Billing only works for builds Play knows about).
8. Server verification credentials: create a **service account** in Google
   Cloud, grant it access in Play Console (Users & permissions →
   "View financial data" + "Manage orders" for this app), create a JSON
   key, and set it as Edge Function secrets (server only — never in the
   app or repo):
   `supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON='<json>' ANDROID_PACKAGE_NAME=it.giocodel101.gioco_del_101 --project-ref <ref>`
9. Install the internal-testing build from Play on a real device with a
   license-tester account and buy each product once; then test
   "Ripristina acquisti" after a reinstall.

## App Store Connect — step by step

1. Open (or create) the app record. The repo's iOS bundle id is
   **`it.giocodel101.giocoDel101`** (from
   `ios/Runner.xcodeproj/project.pbxproj`); keep it or change it in Xcode
   before the first upload.
2. Monetization → In-App Purchases → Create: the **five** products, type
   **Non-Consumable**, with the exact ids above (App Store Connect accepts
   these ids as-is).
3. Choose the price point closest to **€4.99** for each.
4. Add the required localization (display name, description — start from
   `docs/FINAL_IAP_PRODUCT_IDS.md`) and a review screenshot per product
   when submitting.
5. Enable the **In-App Purchase capability** in Xcode signing (macOS-only
   step; nothing in the repo blocks it — this machine is Linux, so iOS was
   compiled/verified statically only).
6. Create **sandbox testers** (Users and Access → Sandbox).
7. Server verification config:
   `supabase secrets set APPLE_BUNDLE_ID=it.giocodel101.giocoDel101 APPLE_SHARED_SECRET=<shared secret> --project-ref <ref>`
   (the shared secret matters only if a subscription is ever added;
   harmless otherwise).
8. Test on an iPhone via TestFlight with a sandbox tester: buy each
   product, then Restore Purchases.
9. Later, recommended: an **App Store Connect API key** to move server
   verification from `/verifyReceipt` (functional, deprecated) to the App
   Store Server API.

## Supabase (per environment)

- Dev is DONE: migration 13 (`20260831201759_cosmetic_entitlements`)
  applied and `verify-purchase` **v2** deployed on GiocoDel101-Dev.
- A production project needs: all 13 migrations, the `match` and
  `verify-purchase` functions deployed, and the secrets above.
- The product allow-list is **code**, not configuration
  (`verify.ts` → `PRODUCT_ENTITLEMENTS`); the old `PREMIUM_PRODUCT_IDS`
  env var is no longer read and can be deleted if it was ever set.

## Legal URLs the consoles ask for

- `PRIVACY_POLICY_URL` — **REQUIRED** by both Google Play and Apple. Host
  `docs/legal/privacy-policy.html` on your website and paste its URL.
- `TERMS_URL` — optional but recommended (Apple shows the standard EULA
  otherwise). Host `docs/legal/terms-and-conditions.html`.
- Owner details still missing from the documents (they render as honest
  placeholders until provided as build defines —
  `lib/core/legal/legal_config.dart`): `LEGAL_ENTITY_NAME`,
  `LEGAL_SUPPORT_EMAIL`, `LEGAL_PRIVACY_EMAIL` (optional),
  `LEGAL_COUNTRY`, `PRIVACY_POLICY_URL`, `TERMS_URL`.

## What "tested" will mean

A side-loaded APK **cannot** prove Play Billing end to end. Real
verification requires: the internal-testing build installed from Play, a
license tester, the five products active, and the service-account key in
the function env. The iOS equivalent needs a sandbox tester on a
TestFlight/dev build from Xcode. Until then the honest status is:
**CODE + SERVER ARCHITECTURE COMPLETE — STORE PRODUCT CONFIGURATION
PENDING — SANDBOX PURCHASE TEST PENDING.**

## Secret hygiene

Server env only: the Google JSON key, Apple shared secret / .p8,
service-role key. None of these ever go into Flutter assets, source, git,
docs, or the delivery archives — and none are there today (scanned before
delivery, see FINAL_VERIFICATION).
