# Forgot password — the whole round trip

Until this release the app had a "forgot password" screen that sent the
Supabase reset email and then had **nowhere for the link to land**. Supabase
was never told where to send the player back, so it fell back to the
project's Site URL (`http://localhost:3000`) and the link died in a browser.
The screen looked finished; the feature was not.

It is now a complete loop. What follows is how it works, the two settings on
the Supabase side it depends on, and how to test it.

## The loop

```
 Sign in ─▶ "Password dimenticata?" ─▶ Forgot screen: type the email
                                          │
                       resetPasswordForEmail(email,
                         redirectTo: it.giocodel101://reset-password)
                                          │
                                   Supabase sends the mail
                                          │
                       tap the link (on the same phone, within the hour)
                                          │
        Supabase /auth/v1/verify ─▶ 303 to it.giocodel101://reset-password?code=…
                                          │
                     Android intent filter / iOS URL type hands it to the app
                                          │
              supabase_flutter exchanges the PKCE code for a recovery session
                                          │
                      AuthChangeEvent.passwordRecovery ─▶ SessionController
                                          │
                    the app shell opens the "Nuova password" screen
                                          │
              updateUser(password) ─▶ signed in with the new password
```

Where each piece lives:

| Piece | File |
| --- | --- |
| The redirect URL (one constant) | `lib/core/config/supabase_env.dart` |
| Sending the mail | `SupabaseAuthGateway.sendPasswordReset` |
| Noticing the link arrive | `lib/features/auth/application/password_reset_link.dart` |
| Recovery / dead-link events | `SupabaseAuthGateway.passwordRecovery` |
| Reacting to them | `SessionController.recovery` → `lib/app/app.dart` |
| Choosing the new password | `lib/features/auth/presentation/reset_password_screen.dart` |
| Android claim on the link | `android/app/src/main/AndroidManifest.xml` |
| iOS claim on the link | `ios/Runner/Info.plist` (`CFBundleURLTypes`) |
| The allow-list entry | `supabase/config.toml` (`auth.additional_redirect_urls`) |

`test/session10_reset_and_rewards_test.dart` pins all four places that name
the URL against each other, so they cannot drift apart silently.

## Two settings on the Supabase project

### 1. Allow the redirect — **done on 2026-09-07**

Supabase refuses any `redirect_to` it was not told about and quietly
substitutes the Site URL instead, which is exactly the failure this release
fixes.

`it.giocodel101://reset-password` was pushed to **GiocoDel101-Dev** with
`supabase config push` on 2026-09-07 and verified live: the allow-listed URL
now comes back in the `location` header while an unlisted one is still
replaced by the Site URL. The auth diff was that one line; nothing else on
the project changed.

It is recorded here because **a new project needs it again**. To add it by
hand:

**Dashboard** → Authentication → URL Configuration → **Redirect URLs** → add

```
it.giocodel101://reset-password
```

The dashboard field is the safe route and takes ten seconds. The value is
also committed to `supabase/config.toml`, so it can be applied with

```
supabase config push --project-ref fnyllrjchbqfrzezfeso
```

— but note that this pushes the **whole `[auth]` block** of the file, not
just the one line, so anything changed in the dashboard and never mirrored
back into `config.toml` would be overwritten. Prefer the dashboard unless
the file is known to be in step with the project.

To check it took, without sending any mail — an allow-listed URL comes back
in the `location` header, a rejected one is replaced by the Site URL:

```
curl -sD - -o /dev/null -H "apikey: <publishable key>" \
  "https://<project>.supabase.co/auth/v1/verify?token=x&type=recovery\
&redirect_to=it.giocodel101%3A%2F%2Freset-password" | grep -i location
```

### 2. A real SMTP sender (required before real testers use it)

Supabase's built-in mailer is a development one: a few messages an hour, and
on newer projects it delivers only to the project team's own addresses. A
tester who never receives the mail will report "forgot password is broken"
and be right. Configure a provider (Resend, SendGrid, Postmark, …) under
Authentication → **SMTP settings**, then raise the email rate limit under
Authentication → Rate limits.

## Testing it

1. Install the build on a real phone (the deep link needs a real OS).
2. Sign in screen → **Password dimenticata?** → type an address that has an
   account → send. The confirmation says the link works on **this phone**
   and for **one hour** — both are true, and both are properties of the PKCE
   flow, not choices.
3. Open the mail **on that phone** and tap the link. The app comes to the
   front on "Nuova password".
4. Type a new password twice (minimum eight characters) → save. A
   confirmation appears and the app is already signed in with it.
5. Sign out, sign in with the new password.

Deliberate behaviours worth knowing before they are reported as bugs:

- **The link only works on the phone that asked for it.** PKCE stores the
  code verifier on the requesting device; opening the mail on a laptop
  cannot complete the exchange. The app says so before it sends.
- **A spent, expired or foreign link is not silent.** The app says the link
  is no longer valid and to ask for a new one, rather than opening and
  doing nothing.
- **The screen never says whether an address has an account.** The same
  confirmation appears either way, so the form cannot be used to find out
  who is registered.
- **Password minimum is eight characters**, matching sign-up
  (`AuthValidators.minPasswordLength` and the project's own
  `minimum_password_length`).
