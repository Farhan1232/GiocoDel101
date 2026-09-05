# Client report of 2026-09-06 — what was wrong and what changed

Seven things were reported. Six were defects with a single root cause each;
the seventh (real store purchases) is blocked on two credentials only the
owner can create. Everything below was reproduced first — against the live
development backend and, for the UI, against the real Flutter build driven in
a browser — and then fixed.

---

## 1. "Create room gives an error every time" — the big one

**Reproduced.** Tapping *CREA LA STANZA* always answered
"Qualcosa è andato storto — Impossibile aprire la stanza. Riprova."

**Cause.** `create_room` validates the house rules on the server with an
ALLOW-LIST (`app_private.sanitize_room_rules`, migration
`20260830100111_release_hardening`). One key it does not recognise and the
whole call is refused with `invalid_rules`. The app sends
`GameRules.toJson()`, which grew **`requireLastCardDeclaration`** — the
"ULTIMA CARTA" switch — *after* that allow-list was written. The key was
never added, so from that moment **every** room the app tried to open was
refused.

It was invisible to the existing checks because the backend test harness
(`tool/online_matrix.dart`) builds its own minimal rules object, and the
Flutter tests use a fake rooms repository. Neither ever sent the app's real
payload.

**Fix, both sides.**

* The app now sends `GameRules.toRoomJson()` — exactly the keys the deployed
  server accepts (`GameRules.onlineRoomRuleKeys`). Nothing about how a room
  plays changes: the match engine defaults `requireLastCardDeclaration` to
  the same value the app uses.
* `supabase/migrations/20260906090000_room_rules_last_card.sql` adds the key
  to the server's allow-list, so a fresh deployment is correct too.
  **This migration has NOT been applied to the live project** — apply it with
  `supabase db push` when convenient; the app works with or without it.
* `test/session9_client_fixes_test.dart` reads the SQL and fails if the two
  sides ever drift again.

## 2. "The online game does not work"

The same cause: no room could be created, so there was never a code, so
nobody could join. With (1) fixed the whole flow works — verified end to end
through the real UI (sign up → create → share code → join → ready → start →
play) and, at the protocol level, by `tool/online_matrix.dart`: **233 of 235
checks pass**, including full 2-, 3- and 4-player matches, quick match,
rematch, reconnect, turn timers, forfeits and the security drill.

One more online defect was found and fixed on the way:

**The false "Riconnessione…" banner.** A match uses two Realtime channels:
one carries the game (Postgres row changes), the other carries reactions and
presence. The *reactions* channel was the one driving the connection banner,
so when the project's `realtime.messages` policies refuse that join — which
they currently do, see §7 — every online table sat on "Riconnessione…"
forever and tore both channels down on a backoff, while the game underneath
was working perfectly. The banner now follows the channel that actually
carries the game; a reactions failure costs reactions and presence dots, and
nothing else.

## 3. "The search module does not work"

Quick match (*Cerca partita*) is sound on the server — 19/19 checks, real
players are paired and the room is dealt. In the app the **Cerca partita
button was simply disabled** whenever nobody was signed in, with no
explanation, which reads exactly like a broken feature. It now offers to sign
in. Same treatment for Create Room and Join Room, which used to walk a
signed-out player into a lobby that could never open.

The wording under those buttons was wrong too: a signed-out player was told
"sign-in becomes active once the online service is connected" — the service
*is* connected; they were just not signed in. It now says so.

## 4. "Switching to English leaves Italian text"

Two causes, both fixed.

* **Nothing forced a rebuild.** Screens read their copy from `Strings.s`, a
  plain static, so only the parts of the tree sitting inside an `Obx` on the
  settings rebuilt. Screen titles, and every route already on the stack, kept
  the language they were built in. `SettingsController.setLocale` now marks
  the whole tree dirty — the same walk a hot reload does — so the switch is
  total.
* **Untranslated strings.** The two paid tables were always named in Italian
  ("Tavolo Oro", "Tavolo Classico") in Settings and on the setup screen; they
  now use the shop's own translations ("Gold Table", "Classic Table"). The
  default player name follows the language too — *Giocatore* / *Player* — and
  a name the player chose is never touched.

The three free tables (Napoli Notte, Maiolica, Vesuvio), the opponents' names
and the eight preset reactions stay Italian on purpose: they are proper names
and the flavour of the game.

## 5. "Tapping a locked card does nothing"

It was literally wired to nothing (`onTap: unlocked ? … : null`). Now every
locked table, card back and cosmetic answers:

* **earned** cosmetics say which achievement unlocks them;
* **paid** cosmetics open the Shop scrolled to that exact item, ringed in
  gold, with the store's payment sheet already opening;
* **signed out**, they lead to sign-in/registration first — a purchase is
  granted to an account and to nothing else — and once signed in the app
  carries straight on to the item they tapped.

## 6. Google and Apple sign-in removed

The two buttons were placeholders that only ever said "not enabled yet".
They are gone, together with their strings. Email + password and the guest
account are the only ways in — which is also exactly what the auth server has
enabled.

## 7. Real in-app purchases

The "coming soon" wording is gone. What is left is the honest state of a
purchase attempt, and the flow itself is real: five products, the store's own
localized price, the store's own payment sheet, server-verified ownership,
Restore Purchases.

**Two things still block a real purchase, and only you can do them:**

1. **The five products must exist and be ACTIVE** in Play Console with the
   exact ids in `docs/FINAL_IAP_PRODUCT_IDS.md`, and the app must be
   installed from a Play track (internal testing is enough). Until then the
   store returns nothing and each card says so.
2. **The server must be given the Play credentials.** The `verify-purchase`
   function answers `verification_unconfigured` today — I checked it against
   the live project — which means it grants nothing, on purpose. It needs:

   ```bash
   supabase secrets set \
     GOOGLE_SERVICE_ACCOUNT_JSON="$(cat play-service-account.json)" \
     ANDROID_PACKAGE_NAME=it.giocodel101.gioco_del_101 \
     --project-ref fnyllrjchbqfrzezfeso
   ```

   The full walkthrough for creating that service account is step 8 of
   `docs/IAP_STORE_SETUP.md`.

Send the JSON key and the products can be tested for real the same day.

---

## The build

`pubspec.yaml` is now **1.0.1+2** (versionName 1.0.1, versionCode 2). Play
refuses a second upload of versionCode 1, so this is what makes the fixed
build uploadable over the one you already have. It is signed with the same
`upload-keystore.jks` — the same key every future update must use.

---

## Also worth knowing

**The private Realtime channel is refused for real match members.** Joining
`match:<id>` answers *"Unauthorized: You do not have permissions to read from
this Channel topic"* for players who are genuinely seated at that match. The
SQL is right — evaluated by hand with a member's claims,
`is_match_member(match_topic_id(...))` returns true — so this is Realtime's
own authorization step disagreeing with the policy, most likely because its
read check now needs an INSERT policy for `broadcast` that we deliberately do
not grant (clients must not be able to broadcast; reactions are sent by the
server). The app no longer suffers for it (§2), but **reactions and presence
dots do not currently arrive**. Fixing it properly is a decision, not a typo:
either allow members to insert broadcast rows — and accept that a modified
client could then send its own reactions — or move reactions onto the row
stream that already works. Tell me which and I will do it.
