# Payments — what is actually live, checked on 2026-09-07

The client's question was: *"the payment integration is okay because I have
already enabled one-time payment and added ids, is it okay? Just real-time
testing left."*

Half of it is okay. The **app** and the **database** are ready and were
re-checked against the live project today. The **server-side verification
credentials are still missing**, and that is not a detail: with them absent
the app refuses to unlock anything a tester buys, and Google refunds the
purchase three days later. Everything needed to fix it is in
[§ The one blocker](#the-one-blocker) and takes about fifteen minutes in two
consoles.

---

## What was verified today, against the live systems

| Check | Result |
| --- | --- |
| `verify-purchase` Edge Function deployed | **Yes** — ACTIVE, version 2 |
| `verify-purchase` answers a real request | **503 `verification_unconfigured`** ← the blocker |
| Product allow-list on the server | the same five ids as the app (`verify.ts`) |
| Android package id | `it.giocodel101.gioco_del_101` (`android/app/build.gradle.kts`) |
| Google Play Billing Library | **8.0.0** (via `in_app_purchase_android` 0.5.3) — current, accepted by Play |
| `targetSdk` / `compileSdk` / `minSdk` | 36 / 36 / 24 — meets Play's 2026 requirement |
| `user_entitlements` table | exists, RLS on, one policy (a player reads only their own rows) |
| Grant path end to end | 5 active rows for the owner's complimentary account — the read + unlock path works |
| Release signing | upload keystore, `CN=Gioco del 101` (not the debug key) |

The exact probe, so it can be repeated:

```
POST https://<project>.supabase.co/functions/v1/verify-purchase
Authorization: Bearer <any signed-in user's JWT>
{"platform":"android","productId":"gioco101_table_gold",
 "verificationData":"...","transactionId":"..."}

→ HTTP 503  {"error":"verification_unconfigured"}
```

`verification_unconfigured` is the function saying, truthfully, *"I have no
Google credentials, so I will not pretend a purchase is real."* It is the
designed behaviour, not a bug — but it must be switched off before anyone
tests a payment.

---

## The one blocker

The `verify-purchase` function needs two environment values. They live only
on the server — never in the app, never in the repository.

```
GOOGLE_SERVICE_ACCOUNT_JSON   the Play service-account key, the JSON verbatim
ANDROID_PACKAGE_NAME          it.giocodel101.gioco_del_101
```

**Google Cloud / Play Console**

1. Play Console → Setup → **API access** → link a Google Cloud project.
2. Create a **service account**, then create a **JSON key** for it.
3. Play Console → Users and permissions → invite that service account with
   **View financial data** and **Manage orders and subscriptions** for this
   app. (Permission changes can take a few hours to take effect — do this
   first, not last.)

**Supabase**

```
supabase secrets set \
  GOOGLE_SERVICE_ACCOUNT_JSON="$(cat play-service-account.json)" \
  ANDROID_PACKAGE_NAME=it.giocodel101.gioco_del_101 \
  --project-ref fnyllrjchbqfrzezfeso
```

(or Dashboard → Edge Functions → verify-purchase → Secrets.)

Then repeat the probe above. A configured function answers **402
`verification_failed`** for the fake token instead of 503 — that is the
"credentials are live" signal, and the moment closed testing can start.

### Why it cannot wait until after the test

The app deliberately **does not acknowledge a purchase it could not
verify**, so a failed verification never eats a payment: Play keeps the
transaction open and redelivers it. But Google **automatically refunds and
revokes any purchase left unacknowledged for three days**. So a tester who
buys before the credentials are set will be charged, will get nothing, and
will be refunded seventy-two hours later. Set the credentials first.

---

## Still to confirm in Play Console (nobody outside the console can see it)

- [ ] The five products exist with these **exact** ids and are **Active**:
      `gioco101_table_gold`, `gioco101_table_classic`,
      `gioco101_deck_special`, `gioco101_cardback_gold`,
      `gioco101_gadget_01`.
- [ ] Each is a **one-time product** (non-consumable), priced ≈ €4.99. The
      app always shows the store's own price — a re-price needs no new build.
- [ ] **License testers** are configured (Play Console → Settings → License
      testing) so test purchases are free and refundable.
- [ ] The new build is on the **closed testing** track and the testers have
      accepted the opt-in link. Billing only works for a build Play knows.

If a product id is missing or inactive, the app does not invent a price: the
shop card reads "not yet available in the store" and says so when tapped.

---

## The closed-testing run, in order

1. Set the two secrets above; re-run the probe until it answers 402.
2. Upload `app-release.aab` (1.0.2+3) to the **closed testing** track,
   roll it out, and wait for it to go live for testers.
3. On a real device, signed in with a **license tester** Google account,
   install from the Play link (not the APK — Play Billing needs the Play
   install).
4. Create an account in the app (email + password). Guests cannot buy: the
   entitlement is attached to a real account so it survives a reinstall.
5. Shop → buy one product. Expected: Play's own sheet → "verification" →
   the item unlocks and the card reads as owned.
6. Check the server actually recorded it:
   `select * from user_entitlements where user_id = '<the tester>';`
   — one row, `status = active`, `environment = sandbox` for a test buy.
7. Uninstall, reinstall, sign in with the same account, **Ripristina
   acquisti**. The item comes back — this is the one Google reviewers test.
8. Buy the remaining four the same way.
9. Try buying the same product twice: Play answers "already owned" and the
   app treats the redelivery as the same transaction, never a second grant.

## Notes for the owner

- **The app talks to the Dev Supabase project** (`GiocoDel101-Dev`). That is
  fine for closed testing. Before a public release, decide whether to
  promote it or create a production project — a production project needs the
  same migrations, the same two secrets, and a rebuild with its URL and key.
- **Email confirmation is off** on that project, so anyone can sign up with
  an address they do not own. Fine for a closed test, worth turning on
  before the public release.
- **Supabase's built-in email sender is a development one**: a handful of
  messages per hour, and on newer projects it will only deliver to the
  project's own team addresses. Password-reset and confirmation mail for
  real testers needs a custom SMTP provider configured in
  Authentication → SMTP settings. See `docs/PASSWORD_RESET.md`.
