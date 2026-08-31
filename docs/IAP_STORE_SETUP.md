# Store setup checklist — what the purchase system still needs from outside

The code and the server are in place (docs/IAP_ARCHITECTURE.md). Everything
below needs the **client's store accounts** and cannot be done from this
repository. Until it is done, the app answers honestly: the Premium screen
shows "product not available" (store side missing) or "verification not
live yet" (server credentials missing), and **nothing is ever granted**.

## Decisions the client must make first

1. **Product model** — one-time "Premium" unlock (what is built,
   provisional) or a subscription (monthly/annual)? A subscription
   additionally needs store server notifications wired (below).
2. **Price** per store/region (set in the consoles; the app always shows
   the store's own localized price).
3. **Real product ids** — the code default is the placeholder
   `gioco101_premium`. Use the real ids at build time:
   `--dart-define=PREMIUM_PRODUCT_ID_ANDROID=… --dart-define=PREMIUM_PRODUCT_ID_IOS=…`
   and mirror them in the Edge Function env `PREMIUM_PRODUCT_IDS`.
4. **What premium unlocks** — currently nothing is paywalled; the
   entitlement is plumbed and displayed. Tell us the feature list.
5. Whether **guests** may purchase (currently allowed; the entitlement binds
   to the guest account, recoverable via store restore).

## Google Play Console

- [ ] App created with package id **`it.giocodel101.gioco_del_101`** (must
      match `android/app/build.gradle.kts`).
- [ ] Upload keystore + `android/key.properties` (release signing — see
      README; Play rejects debug-signed bundles).
- [ ] Upload the AAB to the **internal testing** track (Billing only works
      for builds Play knows about).
- [ ] Create the in-app product (id above), set price, activate it.
- [ ] Add **license testers** (Settings → License testing) so test purchases
      are not charged.
- [ ] Create a **service account** in Google Cloud, grant it access in Play
      Console (Users & permissions) with "View financial data" +
      "Manage orders" for the app, and create a JSON key.
- [ ] Put the key into the Edge Function secrets (never in the app or repo):
      `supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON='<json>' ANDROID_PACKAGE_NAME=it.giocodel101.gioco_del_101 --project-ref <ref>`
- [ ] For a subscription later: enable **Real-time developer notifications**
      (Pub/Sub) and add a receiving endpoint (not yet built — by design).

## App Store Connect

- [ ] App record with the final **bundle id** (set it in Xcode; the repo's
      iOS project uses `$(PRODUCT_BUNDLE_IDENTIFIER)`).
- [ ] Enable the **In-App Purchase capability** in Xcode signing
      (macOS-only step; nothing in the repo blocks it).
- [ ] Create the in-app product (id above), price, localized display name.
- [ ] Sandbox tester accounts (Users and Access → Sandbox).
- [ ] Edge Function secrets:
      `supabase secrets set APPLE_BUNDLE_ID=<bundle id> APPLE_SHARED_SECRET=<shared secret> --project-ref <ref>`
      (the shared secret is required only for subscriptions, harmless
      otherwise).
- [ ] Later, recommended: an **App Store Connect API key** to move
      verification from `/verifyReceipt` (functional, deprecated) to the App
      Store Server API, and to enable App Store Server Notifications.

## Supabase (per environment)

- [ ] The `verify-purchase` function is deployed (v1 on GiocoDel101-Dev).
      Production project: apply migration
      `20260831181638_purchase_entitlements.sql` and deploy the function
      there too — **nothing else in this phase touched the schema**.
- [ ] Set the secrets above; optionally `PREMIUM_PRODUCT_IDS` (comma-
      separated allow-list; defaults to `gioco101_premium`).

## What "tested" will mean

A side-loaded APK **cannot** prove Play Billing end to end. Real
verification requires: the internal-testing build installed from Play, a
license tester account, the product active, and the service-account key in
the function env. The iOS equivalent needs a sandbox tester on a
TestFlight/dev build from Xcode. Until then the honest status is:
**CODE/ARCHITECTURE COMPLETE — STORE SANDBOX VERIFICATION PENDING.**

## Secret hygiene

Server env only: the Google JSON key, Apple shared secret / .p8, service-role
key. None of these ever go into Flutter assets, source, git, or docs — and
none are there today (verified before commit).
