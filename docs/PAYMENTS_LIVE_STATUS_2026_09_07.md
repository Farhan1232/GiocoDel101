# Payments — what is actually live, checked on 2026-09-07

The client's question was: *"the payment integration is okay because I have
already enabled one-time payment and added ids, is it okay? Just real-time
testing left."*

Almost. The **app**, the **database** and now the **server credentials** are
all in place and were checked against the live systems today. What is left is
a single checkbox in Play Console: the service account is **not permitted to
read this app's orders**, so Play refuses it and nothing can be verified.

The client's Google service-account key arrived and **is installed** on the
`verify-purchase` function. Google accepts the key; Play does not yet accept
the account. See [§ The one blocker](#the-one-blocker).

---

## What was verified today, against the live systems

| Check | Result |
| --- | --- |
| `verify-purchase` Edge Function deployed | **Yes** — ACTIVE |
| `GOOGLE_SERVICE_ACCOUNT_JSON` + `ANDROID_PACKAGE_NAME` | **set** on the function |
| The key itself | **valid** — Google issues an `androidpublisher` token for it |
| Service account ↔ app link | **works** — `edits.insert` answers 200 |
| Service account ↔ **orders** | **refused** — `purchases.products.get` answers **401** ← the blocker |
| Product allow-list on the server | the same five ids as the app (`verify.ts`) |
| Android package id | `it.giocodel101.gioco_del_101` (`android/app/build.gradle.kts`) |
| Google Play Billing Library | **8.0.0** (via `in_app_purchase_android` 0.5.3) — current, accepted by Play |
| `targetSdk` / `compileSdk` / `minSdk` | 36 / 36 / 24 — meets Play's 2026 requirement |
| `user_entitlements` table | exists, RLS on, one policy (a player reads only their own rows) |
| Grant path end to end | 5 active rows for the owner's complimentary account — the read + unlock path works |
| Release signing | upload keystore, `CN=Gioco del 101` (not the debug key) |

Run the check yourself, any time, in one command:

```
deno run --allow-read --allow-net tool/play_access_check.ts <key.json>
```

It signs exactly the JWT the server signs and asks Play about a fake purchase
token, which separates the two failures that look identical from inside the
app:

| Play answers | Meaning |
| --- | --- |
| **400 / 404** | Play knows us and rejected the fake token → **verification is live** |
| **401 / 403** | Play refused the *service account* → the console grant is missing |

Today it answers 401, so `verify-purchase` answers `503
verification_unconfigured` and the app says "verification not live yet" —
truthfully, and deliberately: the function would rather refuse than pretend a
purchase is real.

---

## The one blocker

**Already done** (2026-09-07): the key
`gioco101-play-billing-276@gioco-del-101.iam.gserviceaccount.com` is installed
on the function as `GOOGLE_SERVICE_ACCOUNT_JSON`, with
`ANDROID_PACKAGE_NAME=it.giocodel101.gioco_del_101`. Both live only on the
server — never in the app, never in this repository. **Keep the key file out
of git and off shared drives**: anyone holding it can read this app's order
data.

**What is left is one checkbox in Play Console.**

The account is linked and can already see the app — the API lets it open an
edit. What it cannot do is read orders, which is exactly what verification
is:

> `purchases.products.get` → **401 · The current user has insufficient
> permissions to perform the requested operation.**

1. Play Console → **Users and permissions**.
2. Find `gioco101-play-billing-276@gioco-del-101.iam.gserviceaccount.com`.
   If it is not listed, **Invite new user** with that address.
3. Open it → **App permissions** → add **Gioco del 101** → tick
   **"View financial data, orders, and cancellation survey responses"**.
   ("Manage orders and subscriptions" additionally allows refunds later; it
   is not needed for verification.)
4. Save. Google usually applies it within minutes, occasionally up to 24
   hours.
5. Re-run `tool/play_access_check.ts`. When it prints **VERIFICATION IS
   LIVE**, closed testing can start. Nothing needs rebuilding or
   redeploying — the server picks it up on the next purchase.

### Why it cannot wait until after the test

The app deliberately **does not acknowledge a purchase it could not
verify**, so a failed verification never eats a payment: Play keeps the
transaction open and redelivers it. But Google **automatically refunds and
revokes any purchase left unacknowledged for three days**. So a tester who
buys before the credentials are set will be charged, will get nothing, and
will be refunded seventy-two hours later. Set the credentials first.

---

## Still to confirm in Play Console (nobody outside the console can see it)

- [ ] The service account has **View financial data** for this app (the
      blocker above — `tool/play_access_check.ts` tells you when it lands).
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

1. Grant the financial permission above; re-run
   `tool/play_access_check.ts` until it prints VERIFICATION IS LIVE.
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
