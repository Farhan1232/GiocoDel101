# Client round, 2026-09-07 — version 1.0.2 (build 3)

Three requests, and one answer the client did not ask for but needs before
closed testing.

1. *"Add a forgot screen, user enters email, attached with Supabase."*
2. *"Make proper alignment of the reward screen — claim etc. should work
   perfectly."*
3. *"Make the APK and the AAB for the Play Store update."*
4. *"Check the payment integration is okay — only real-time testing left."*

Nothing else was touched. `flutter analyze` is clean and the suite is at
**778 tests**, up from 749.

---

## 1. Forgot password — it now completes

The screen already existed and already called Supabase. What did not exist
was **anywhere for the emailed link to come back to**: the app never told
Supabase where to send the player, so Supabase used the project's Site URL
(`http://localhost:3000`) and the link ended in a browser on a page that
does not exist. Sending the mail was the easy half; this release adds the
other half.

- `resetPasswordForEmail` now sends a `redirectTo` — one constant,
  `it.giocodel101://reset-password`, overridable at build time.
- The Android manifest and the iOS `Info.plist` claim that URL, so the phone
  hands it to the game instead of to a browser.
- `supabase/config.toml` lists it in the redirect allow-list, and that was
  **applied to the live project on 2026-09-07** and verified: the URL now
  comes back in Supabase's `location` header instead of being replaced by
  the Site URL. `docs/PASSWORD_RESET.md` has the one-line curl that proves
  it, for the next project.
- A new **"Nuova password"** screen: new password, confirmation, the same
  validation as sign-up, and the account is signed in with it immediately.
- The app shell opens that screen by itself when a reset link is opened, and
  a **dead link now says so** — expired, already used, or opened on a
  different phone — instead of the app opening and doing nothing. That last
  case is why `PasswordResetLink` exists: the failure arrives as a bare
  error on the auth stream, indistinguishable from a token refresh that lost
  the network, unless the app knows a link just arrived.
- The "email sent" confirmation now states the two constraints of the flow
  up front: **this phone**, **within the hour**. Both come from PKCE.
- New copy in Italian and English; two new named errors (a spent link, a
  password identical to the current one) instead of "something went wrong".

Full description, including the two Supabase settings this depends on:
`docs/PASSWORD_RESET.md`.

## 2. The daily reward screen

Five separate things were wrong; all five are fixed.

| Before | Now |
| --- | --- |
| The title sat hard against the back button — "Ricompensa giornaliera" is long enough to fill the bar exactly | The title bar keeps a gutter on both sides (every screen benefits) |
| Seven tiles over four columns left the second row of three shoved against the left edge | The short row is centred under the long one |
| "Giorno 1" filled its tile and so rendered left-aligned, while the trophy and the amount under it were centred | The day label is centred like everything else in the tile |
| The claim button floated in the middle of the screen with a third of the page empty below it | The ladder is centred in the space it has and the button is anchored above the caption at the bottom |
| Under the button, the caption repeated the sentence above the ladder word for word whenever the reward was claimable | The caption only appears when it has something new to say |

And claiming itself:

- **The button is never dead.** It used to be greyed out whenever the reward
  could not be taken, which told the player nothing. Now it always responds:
  not signed in offers the way in, a guest is told an account is needed,
  already claimed says come back tomorrow, no backend says so.
- **A successful claim says what was won** — the server's number, not the
  client's guess — and the coin balance updates behind it.
- The button stops spinning before the dialog appears, instead of spinning
  behind it.

**The server side was checked live, not just read.** A throwaway account was
created against the real project, and it walked the whole ladder:

```
my_daily_reward_status  → streak 0, can_claim true, coins 0
claim_daily_reward      → day 1, amount 10
my_daily_reward_status  → streak 1, claimed_today true, coins 10
claim_daily_reward      → refused: already_claimed
delete_my_account       → 204, and the reward row went with it
```

So claiming works, the streak advances, a second claim on the same day is
refused by the database rather than by the app, and the amounts are the
server's. The test account was deleted afterwards; the project is as it was.

## 3. The build

`1.0.1+2` → **`1.0.2+3`**. Play needs the build number to go up; 3 follows
the 2 already on the store.

- `app-release.aab` — the file to upload for the update.
- `app-release.apk` — for installing directly on a test device. **Play
  Billing does not work in this APK** (a purchase needs an install Play
  itself made) — use it for everything except buying.

Both are signed with the upload keystore (`CN=Gioco del 101`), not the debug
key.

## 4. Payments

The app and the database are ready; the **server verification credentials
are still not set**, which was checked against the live function today —
it answers `503 verification_unconfigured`. Closed testing cannot start
before that is fixed, because Google refunds any purchase the app has not
acknowledged within three days, and the app refuses to acknowledge a
purchase it could not verify.

What was verified, what is missing, and the order to run closed testing in:
`docs/PAYMENTS_LIVE_STATUS_2026_09_07.md`.

---

## What the owner still has to do

1. ~~**Supabase → Redirect URLs**~~ — done on 2026-09-07 and verified live.
2. **Supabase → SMTP**: the built-in sender **refuses to deliver to any
   address that is not on the project's team**, so reset mail will not reach
   testers until a provider is connected.
3. **`verify-purchase` secrets**: `GOOGLE_SERVICE_ACCOUNT_JSON` and
   `ANDROID_PACKAGE_NAME`, from a Play service account.
4. **Play Console**: the five products active, license testers configured,
   1.0.2+3 uploaded to the closed track.
