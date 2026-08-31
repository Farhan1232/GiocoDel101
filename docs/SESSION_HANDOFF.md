# Session Handoff — Session 7 → store publishing

Date: 2026-08-31 (Session 7), on top of everything below. Branch:
`feature/session-1-ui-foundation` (continued).

---

## 0z. Session 7 — crash/slowdown fixes + the purchase system. READ FIRST.

The client reported the game "gradually slows down and eventually
force-closes" on multiple physical phones, and asked for "integration of the
purchase system". Both delivered:

1. **Stability (P0)** — four deep audits found and fixed real, confirmed
   leaks; the full account with evidence is
   **`docs/PERFORMANCE_CRASH_AUDIT.md`**. Headlines: the offline "Rivincita"
   retained one whole mounted table per rematch (`offNamed` → `offNamedUntil`);
   card decodes were keyed up to 720 px for 360-px sources against an
   unconfigured 100 MiB image cache (now capped at 48 MiB with decode keys
   clamped to the source); a stale `TableController` registration could leave
   a live, undismissable online controller (sockets + timers) running
   invisibly forever; card-flight awaits stranded on teardown retained
   disposed screens; the audioplayers backend grew a native entry per sound
   played (now one fixed player per effect). Plus: finished online matches no
   longer re-subscribe, the 6 s poll no longer rebuilds an unchanged table,
   flights repaint one layer instead of the whole tree, and several stuck-UI
   paths (matchmaking, lobby, rematch) now settle.
   **No game rule, no schema, no wire format, no visual design changed.**
   **PHYSICAL DEVICE CRASH REPRODUCTION NOT VERIFIED** — no device on this
   machine; the client must re-test (instructions in the audit doc).

2. **IAP** — official `in_app_purchase` (3.3.0), a permanent
   `PurchaseController` owning the single purchase-stream subscription, a
   `/premium` screen (store-priced, Italian primary), "Ripristina acquisti",
   and server-authoritative entitlements: migration 12
   (`user_entitlements` + `purchase_transactions`, RLS read-own-row, writes
   only via service-role `srv_grant/revoke_entitlement`) and the
   `verify-purchase` Edge Function (v1 on GiocoDel101-Dev) which verifies
   with Google/Apple and answers `verification_unconfigured` — granting
   nothing — until store credentials exist. Architecture:
   **`docs/IAP_ARCHITECTURE.md`**; the client-side checklist (product ids,
   consoles, secrets, signing): **`docs/IAP_STORE_SETUP.md`**.
   Attack drill run live on dev (client writes, srv_ calls, replays,
   cross-account reads — all refused); advisors show nothing new.
   **STORE SANDBOX VERIFICATION PENDING** — needs Play Console /
   App Store Connect, which only the client can provide.

Numbers after Session 7: **712 Flutter tests** (25 new), **68 + 5 Deno
tests**, bot simulation 270 matches / 72 488 actions / 0 violations /
0 hangs, `flutter analyze` clean, both APKs + AAB building (still
debug-signed — no `key.properties`). New tests:
`test/session7_stability_test.dart`, `test/session7_iap_test.dart`,
`supabase/functions/verify-purchase/verify_test.ts` (needs `--allow-env`).

Supabase dev state: migrations **12 = 12**
(`20260831181638_purchase_entitlements`), Edge Functions `match` v8
(untouched) and `verify-purchase` v1.

---

## 0a. Client change request, 2026-08-31 — READ THIS FIRST

A scoped change on top of Session 6. Full account, with evidence, in
**`docs/CLIENT_CHANGE_2026_08_31.md`**. Five requests, all delivered:

1. **The previous round's closer leads the next round** (GAME_SPEC §12). Was
   already the active preset (`roundStarterPolicy = previousRoundWinner`);
   now confirmed rather than provisional, and proven for 2/3/4 players
   including "not the clockwise successor". **No production code changed.**
2. **Paying a +2 chain no longer ends the turn** (GAME_SPEC §6b — the
   substantial change). The seat that draws the penalty keeps the turn and
   plays one ordinary legal card; then the turn advances. Holds for +2/+4/+6/+8.
   `GameState.penaltyResolvedThisTurn` is new. Engine, compiled server engine,
   bots and table all follow it; the turn clock re-stamps so the continuation
   has real time.
3. **Performance** — audited, and a repeatable long-session harness added
   (`test/long_session_performance_test.dart`). The one real fix is stepped,
   layout-sized image decoding for the new card artwork. **The reported
   slowdown was not reproduced here**; see the doc for what is and is not
   verified.
4. **The cards are now real Carte Napoletane** — 40 public-domain faces in
   `assets/cards/`, licence in `assets/cards/LICENSE.txt`. The engraved
   painters stay as the fallback.
5. **The deal rotates clockwise every round** (GAME_SPEC §12a).
   `GameState.dealerSeat` is new, independent of who leads; the table deals
   from the dealer's left and badges the dealing seat.

**No Supabase migration was needed** — both new state fields are public and the
redaction is a blacklist. RLS, private hands and the security model are
untouched.

Numbers after the change: **571 Flutter tests**, **58 Deno tests**, 51
conformance fixtures (5 new for §6b, 3 for §12a) replayed on both the Dart VM
and the compiled JavaScript, bot simulation **270 matches / 0 violations /
0 hangs**, both APKs building.

The updated `match` Edge Function **was deployed** to `GiocoDel101-Dev`
(v5 → **v6**). Only the function changed — no migration, no schema or policy
change, no database reset; rolling back is a redeploy from the previous commit.

Against that deployment, `tool/online_rule_check.dart` (new — a focused driver
that costs one request per action instead of a full snapshot fan-out) proves
all three rules live with independent authenticated users: **2 players 20/20,
3 players 20/20, 4 players 21/21 — 61 checks, 0 failures**, including a stacked
**+4** and the pass-when-nothing-legal branch.

`tool/online_matrix.dart` also gained §6b/§12/§12a assertions, but **did not
finish a full match here**: four attempts each died partway through the game
drive on a transport error on `rest/v1/rpc/match_snapshot`. Everything it
reached passed (37–39 checks: setup, private room, private hands, RLS,
concurrency, idempotency, receipts). Re-run it from a normal network.

Session 6 added **no feature**. It audited, broke, fixed, verified and
polished what Sessions 1–5 built. The feature-by-feature evidence table is
`docs/FINAL_VERIFICATION.md`; this file is the narrative, the numbers and
what is still open.

---

## 0b. Client FINAL change, 2026-08-31 — READ THIS SECOND

Three more requests, closing the brief. Full account, with evidence, in
**`docs/CLIENT_FINAL_CHANGE.md`**. All three delivered; nothing outside them
was touched.

1. **Fante and Cavallo are worth 25 points in the hand** (GAME_SPEC §1, §10).
   The client's "9" is the Cavallo and their "Jack" is the Fante. One table,
   `GameRules.defaultScoreValues`; `ScorePolicy.handPenalty` is still the only
   thing that prices a card. **Penalty only** — the Cavallo still names a suit
   and blocks a chain, the Fante is still an ordinary card, and
   `CardRank.cavallo.value` is still 9 because that is its *rank*.
   `GameState.schemaVersion` went 2 → **3** so a pre-change save is migrated
   off the old price list instead of resuming under it.
2. **"ULTIMA CARTA"** (GAME_SPEC §16 — the substantial change). A play from
   **two** cards to **one** is refused with
   `GameFailure.lastCardDeclarationRequired` unless the seat has declared this
   turn. Implemented as `DeclareLastCardAction`, so the *server* enforces it
   online with the same compiled engine — a modified client can neither skip
   the announcement nor make one for another seat. New state:
   `GameState.lastCardDeclaredBy` (a seat id, public, cleared by every turn
   change, deal, draw and forfeit). New rule flag:
   `GameRules.requireLastCardDeclaration` (default **true**). No penalty was
   invented; the client did not ask for one. Bots, Pass & Play and the
   tutorial go through `GameSession.autoPlayCard`, which sends the same two
   actions a person's button and card tap produce — one implementation, no
   bypass.
3. **Large hands stay usable** (10 / 15 / 20 / 25+ cards). Two real defects
   found and fixed: a card's tap area was its whole rectangle rather than the
   strip its neighbour leaves visible, so past about nine cards a tap selected
   the *wrong* card; and "selection lifts a card" actually moved it **down**
   and out of the strip. `HandFan` now solves one `_FanGeometry` per build and
   degrades in a fixed order — spacing, overlap, card width (never below a
   readable 46 px, and only when it avoids scrolling), then scrolling with an
   edge fade and the selected card scrolled into view.

**No Supabase migration was needed again** — `lastCardDeclaredBy` is public and
the redaction is a blacklist. RLS, private hands and the security model are
untouched. `match_private_state` gained nothing.

The `match` Edge Function **was deployed** to `GiocoDel101-Dev` (v6 → **v7**).
Only the function changed. Rolling back is a redeploy from the previous commit.

**Live proof that the rule is the server's, not the client's:** the first run
of `tool/online_rule_check.dart` after the deploy failed with
`FAIL server accepted playCard from p0 (lastCardDeclarationRequired)` — the
tool had not been taught to declare. It now declares through the server like
the app does, and passes: **2 players 28/28, 3 players 34/34, 4 players 24/24
— 86 checks, 0 failures**, with 14 ULTIMA CARTA announcements accepted by the
server and published to the table.

Numbers after the change: **651 Flutter tests**, **66 Deno tests**, 59
conformance fixtures (8 new for §16) replayed on both the Dart VM and the
compiled JavaScript, bot simulation **540 matches / 140 247 actions / 0
violations / 0 hangs / 0 illegal proposals**, both APKs building.

`tool/online_matrix.dart` gained §16 assertions and declares through the
server. Its **short form completed — 157 checks, every functional area
green**. Its **full form did not finish in this environment**: the longest run
reached **200 checks, 0 failures** (complete 2-player game, match result,
rematch, reconnect, realtime, reactions, RLS, concurrency, hardening, turn
timer, forfeit, quick match, into the 3-player game) before being cut off by
process limits. The only assertions left unproven by it are its two
*live-game coverage counters* — that a reshuffle and a Cavallo block each
occurred at least once — and both rules are covered by conformance fixtures on
the VM **and** the compiled JavaScript, and by the bot simulation. Re-run the
full matrix from a normal shell to close that line.

Two reporting fixes went into the matrix tool while doing this: its §16 check
is now a global counter (like `_totalRecycles`), so it reports in the short
form too; and the short form no longer reports RESHUFFLE / 9 BLOCK as
*failures* when it skips the very games that produce them.

---

## 0c. Client follow-up, 2026-09-01 — the clockwise sequential deal

> "The sequential hand in clockwise order still doesn't work."

**The dealer rotation added on 2026-08-31 was cosmetic.** `dealerSeat` moved,
the badge moved and the deal animation travelled round the table — but
`GameEngine._deal` dealt in plain seat order (0, 1, 2, 3) and never read
`dealerSeat`, so who dealt had no effect on who received which card.
`DealCue`'s own comment said as much: *"presentation only … does not depend on
this order."*

**Now:** `GameState.dealingSeatOrder` is the canonical lap — every live seat,
one step clockwise, starting one place after `dealerSeat`, wrapping so the
dealer is served last. `_deal` deals by it, one card per seat per lap; the
animation's `dealingOrder(state)` is a one-line delegation to the same getter,
so the card a player receives is the card they watch arrive. Eliminated seats
are skipped with the clockwise order of the rest preserved.

Turn order is untouched: §12 still gives the lead to the previous round's
closer, §12a still rotates the dealer, and the deal answers neither question.

The only production change is that loop plus the derived getters. No rule, no
scoring, no §16, no layout, no security, no schema, no wire format — no
migration; `dealerSeat` was already public and the order derives from it.
What *does* change is which cards a seed deals to which seat, which is the
fix; the 61 conformance fixtures were regenerated and every hand-written
assertion still holds.

Numbers: **684 Flutter tests**, **68 Deno tests**, 61 conformance fixtures on
the Dart VM **and** the compiled JavaScript, bot simulation **540 matches /
0 violations / 0 hangs / 0 illegal proposals**.

The `match` Edge Function was redeployed to `GiocoDel101-Dev` (v7 → **v8**).
`tool/online_rule_check.dart` gained a §3 check that recomputes the expected
lap from the server's published `dealerSeat`: **2 seats 50/50, 3 seats 36/36,
4 seats 46/46, 0 failures**, observing dealer 1 → `[0,1]`, dealer 2 →
`[0,1,2]`, dealer 3 → `[0,1,2,3]` and dealer 0 → `[1,2,3,0]` — exactly the
sequences the client specified.

Full account in **`docs/CLIENT_FINAL_CHANGE.md`**.

---

## 0. What Session 6 found and fixed

Four parallel read-only audits (server security, client performance,
hygiene/localisation/theme, cards/layout/accessibility) plus a live
inspection of `GiocoDel101-Dev`. Everything below was **reproduced or read
in the code first**, then fixed, then re-verified.

### Server (migrations 10 `20260830100111_release_hardening.sql` and 11 `20260830110458_receipt_scope.sql`, `match` function redeployed)

| Finding | Severity | Fix |
|---|---|---|
| 31-bit deal seed: a modified client with the engine could enumerate 2³¹ deals until one matched its own hand and know every card | **high** | `seed52()`; `_seededRandom` folds the high bits in with arithmetic (dart2js-safe); two wide-seed conformance fixtures prove VM = JS; 41 old fixtures byte-identical |
| A seat at a live match could `create_room` / `join_room` (only the queue refused) — observed: one user at **four** stalled tables on the dev project | med | `app_private.assert_not_in_match` in all three; `join_room` also answers `match_already_started` |
| Instant-forfeit result farming with a throw-away guest (+1 win, +65 XP, streak, badges for three requests) | med | `settle_match` records nothing when the match ended by forfeit before a completed round (provisional — §5) |
| Refused actions logged the card the actor holds; every seat reads the log | med | card stripped from the log; ≤ 100 refusals per seat per match |
| `rooms.rules` unvalidated, unbounded, straight into the engine | med | `sanitize_room_rules` (key allow-list, types, ranges, ≤ 4 KB) |
| Receipt lookup before the membership check, unscoped | low | membership first; `srv_find_receipt(match, action, user)`; the lookup inside `srv_commit_action` refuses another seat's receipt (`action_id_taken`, migration 11 — the matrix's new hardening area caught that the first fix was incomplete) |
| `timeout` accepted from a forfeited caller; a third-strike forfeit left the seat in the room and blocked the rematch vote | low | refused / seat removed |
| Unmapped Postgres errors echoed verbatim (`Key (…) already exists`) | low | `{error: "internal"}` + function log |
| `handle_new_user` could end a nickname with a space (fails the trimmed check → **sign-up fails**); invisible/bidi characters accepted | low | trim after cut; check constraint |
| Stale `matched` queue row after leaving the lobby by another door | low | membership re-checked |
| All-absent tables waited 24 h; receipts grew forever | low | abandoned after 1 h with no action and no heartbeat; receipts pruned after 7 days |
| `app_private` functions had default `EXECUTE` for everyone (schema `USAGE` already refused) | low | revoked, default privileges too |

### Client

| Finding | Fix |
|---|---|
| **Release APK had no `INTERNET` permission** (only the debug/profile manifests did) — online play impossible in any release build | added to `main/AndroidManifest.xml` |
| Realtime reconnect **churn loop**: closing the old channel reported `closed` to the same callback, which re-armed the reconnect and tore down the healthy new channel — forever, on every app resume | subscription generation gate; `connected` cancels the pending reconnect |
| The **whole table rebuilt once a second** online: `TableSessionStatus` had no `==` and the top bar read it inside the screen-wide `Obx` | value semantics + a scoped `Obx` around the timer ring and connection dot |
| Polls (6 s snapshot, 10 s heartbeat, 1 s clock) kept running after the match finished | stopped in `_maybeFinish`. (An attempt to stretch the snapshot poll to 18 s while the socket is healthy was **reverted**: with a missed Realtime UPDATE the Chrome host learned of its turn too late and was forfeited after three timeouts — the 6 s poll is load-bearing for the turn timer) |
| Offline `MatchLauncher` registered the driver route-scoped; with `replace: true` (CPU fallback, offline rematch) GetX deleted it as soon as the launching route was disposed — bots would stop | `permanent: true` + `MatchLauncher.dismiss()` on exit / home; regression test |
| Lobby showed raw error text (`e.detail ?? e.error.name`, raw server codes) in two places | mapped to Italian/English copy; lobby poll coalesced |
| **Online round-result sheet could open empty and never close** (found only by the headless-Chrome driver): `GameScreen` pushed the sheet 520 ms after `lastRoundResult` was set without re-checking it; a fast opponent dealing the next round inside that beat left the host behind a blank "Round completato" — its turns timed out and the server forfeited it after three strikes (runs 4 and 5 of the driver) | the delayed navigation re-checks the result and the route; a sheet built with no result pops itself; regression test |
| Card flights changed `elevation` per frame → shadow blur re-rasterised up to 28 cards per frame during a deal | constant elevation |
| Felt ambient layer repainted every frame for the whole match | time quantised to 24 steps |
| Matchmaking: a vanished queue row never re-enqueued (`_search` refused while `_searching`) | fixed |
| Setup screen built a `TextEditingController` per rebuild | one per seat, disposed |
| `xp_bar` caption overflowed 320 px / large text (Home, Missions) | `Flexible` + ellipsis (the only overflow in 154 screen×size×scale cases) |
| Cards, hand and discard pile had **no semantics**; icon pills unlabeled | `cardDisplayName` (localised), `Semantics` on `PlayingCard`, hand cards, discard, every back/reactions pill |
| Contrast: `textMuted #7A7285` (off-palette, 3.3:1), ivory on terracotta buttons (2.8:1) | muted = `#B6AC9C` at 80 %; dark ink on danger buttons |
| Hand-fan tap step could fall to 25 px; settings rows not tappable | `minStep ≥ 48`; the row toggles its switch |
| OS reduce-motion flag ignored; hand shake ignored the setting | `Motion.systemReduceMotion` from `MediaQuery.disableAnimations` |
| ~20 hardcoded Italian literals (setup names, replay sheet, daily challenges, theme taglines) broke the English locale | localised |
| Missing copy from the brief | `Stanza non trovata.`, `La partita è già iniziata.`, `Connessione persa. Tentativo di riconnessione...`, `Mossa non valida.`, `Non è il tuo turno.`, `Sessione scaduta. Accedi di nuovo.` (shown once by the app shell when a session the player did not end goes away) |
| "seme" vs the brief's "palo" | all Italian copy now says **palo / pali** (`Scegli il palo`, `Palo attivo`, `Rituale dei Pali`) — §5 |
| `debugPrint` in 38 places prints in release too | `Log.d` (debug builds only) |
| Unused code / assets | `FlippingCard`, `CardBackInks`, `BotProfile.blurb`, `DailyChallenge.reward`, 28 unused ARB keys removed; `OFL-Cinzel.txt` / `OFL-Manrope.txt` now bundled and registered |
| Template leftovers | web title/description/theme colour, white Android launch flash, `ic_launcher_background`, gradle `TODO`s; release signing reads `android/key.properties` when present |
| Test-account password in `tool/ui_drive_web.ts` | `UI_HOST_PASSWORD` from the environment |
| Create/Join Room footer still said "L’avvio delle partite online arriva con il prossimo aggiornamento" (Session 3 placeholder, spotted in the driver's screenshot) | "La partita parte quando tutti i posti sono occupati e ogni giocatore è pronto." |

### Left alone on purpose
- `CardAsset.imagePath` (documented future work), `preview/*.png` contact
  sheets, `env/supabase.dev.json.example` holding the dev project's
  publishable key (public by design, and the tools depend on it).
- No AdMob, IAP, subscriptions or store work — next phase.

---

## 1. Verification — exactly what ran

### Local gates (final tree)

| Gate | Result |
|---|---|
| `dart format lib test tool` | clean |
| `flutter analyze` | **No issues found** |
| `flutter test` | **515/515** (505 before Session 6 + 10 in `test/session6_release_test.dart`) |
| `deno test --allow-read supabase/functions/match/` | **50/50** (43 conformance fixtures incl. two wide-seed ones + 7 timeout tests) |
| `deno check supabase/functions/match/index.ts` | clean (added to the routine after a missed `seed31` reference reached the dev deployment for eight minutes — see below) |
| `dart run tool/bot_simulation.dart
RULE_CHECK_SEATS=4 dart run tool/online_rule_check.dart   # §6b/§12/§12a, live
RENDER_PREVIEWS=1 flutter test test/napoletane_deck_test.dart --timeout none
GENERATE_FIXTURES=1 flutter test test/tools/generate_conformance_fixtures.dart` | **270 matches, 90 796 actions, 0 invariant violations, 0 hangs, 0 illegal proposals** |
| `flutter build apk --debug --dart-define-from-file=env/supabase.dev.json` | ok — `build/app/outputs/flutter-apk/app-debug.apk` (178 MB), rebuilt from the final tree |
| `flutter build apk --release …` | ok — `build/app/outputs/flutter-apk/app-release.apk` (59.7 MB), **debug-signed** (no `key.properties`) |
| `flutter build appbundle --release …` | ok — `build/app/outputs/bundle/release/app-release.aab` (57.6 MB), debug-signed |
| `flutter build web` | ok (1 min 17 s), used by the headless-Chrome driver |

### Remote — GiocoDel101-Dev (`fnyllrjchbqfrzezfeso`)

Inspected through the Supabase MCP before any change: 9 migrations
(11 after), 1 Edge Function, every table RLS-enabled with
SELECT-only client grants, `srv_*` service-role only, two pg_cron sweeps
running every 10 min, no duplicate seats/members, no orphan engine state,
no duplicate daily-reward rows, an empty queue — and the four stalled
4-seat tables described above (now `abandoned`). Advisors: the only real
item is **leaked-password protection disabled** (known production
checklist); the SECURITY DEFINER and "anonymous access" warnings are the
intended RPC/guest design.

**Baseline** `tool/online_matrix.dart` (full, before Session 6's changes,
1465 s): every area PASS except REALTIME 3/5 — two `postgres_changes`
UPDATE events were not received within the wait window. Session 5's full
run had passed the same checks; treated as delivery latency on the free
tier and re-checked below.

**After** (migration 10 + redeployed function, full run):

| Run | Result |
|---|---|
| **full** (2377 s, five independent users, deployed function + migration 10) | **22 of 23 areas PASS, 156/157 checks.** SETUP 1/1 · PRIVATE ROOM 6/6 · PRIVATE HAND SECURITY 20/20 · CONCURRENCY & ATTACKS 14/14 · 2 PLAYER 2/2 · MATCH RESULT 21/21 · REMATCH 8/8 · RECONNECT 3/3 · **REALTIME 5/5** (the baseline's two misses did not recur) · REACTIONS 5/5 · RLS 9/9 · TURN TIMER 7/7 · FORFEIT / LEAVE 4/4 · QUICK MATCH 15/15 · 3 PLAYER 3/3 · 4 PLAYER 3/3 · ASSO, +2, STACKING, 9, RESHUFFLE, 9 BLOCK all PASS. Games: **2-player to 101** — 495 actions in 822 s, 15 rounds, 32 Assi, 24 Due, 37 Cavalli (2 blocks), max chain 2, 0 refused; **3-player to 45** — 126 actions, 4 rounds, 10 Assi, 9 Due, 12 Cavalli (1 block), 5 penalty draws, 0 refused; **4-player to 45, 8-card hands** — 448 actions in 1162 s, 7 rounds, 33 Assi, 35 Due, 41 Cavalli (2 blocks), max chain 3, 26 penalty draws, **6 reshuffles**, 0 refused. The one FAIL was in the **new** SESSION 6 HARDENING area (21/22): "another seat reusing an action id is judged afresh" — `srv_commit_action`'s own receipt lookup still matched on `(match, action)` only. Fixed by migration 11 (`action_id_taken`), redeployed, re-run below |
| **quick** (`MATRIX_QUICK=1`, 784 s, after migration 11 + redeploy) | **ALL PASS — 17 areas, 144/144 checks**, SESSION 6 HARDENING **22/22**: the reused action id is now answered `409 action_id_taken` |

**Progression** `tool/progression_smoke.dart` (after):

| Run | Result |
|---|---|
| after migration 10 + redeploy (322 s) | **81 checks, 0 failures.** Two fresh users play a complete 2-player match through the function (winner A); XP 0 → 65 (winner) / 20; `match_round_results` rows agree with what both clients saw; `prima_vittoria` for the winner only; missions `play_aces 3/3`, `use_nine 3/3`, `online_match 1/2`; `play_aces` claim +25 XP (65 → 90), second claim → `already_claimed`, incomplete → `not_completed`, unknown id → `mission_expired`; client writes to `user_daily_missions` / `daily_missions` refused (42501); leaderboard pages and own rank consistent; the forfeit-before-round rule did **not** touch a normally finished match |

**Real app** `tool/ui_drive_web.ts` (the web build of the app in headless
Chrome as the host, driven only through its semantics tree; three
independent supabase-js guests):

| Run | Result |
|---|---|
| 1–2 (before the round-result fix) | booted, signed in, created the room, three independent guests joined and readied, host started, table reached (14 PASS) — then the host stopped acting after round 1 and was forfeited: the blank round-result sheet described above |
| 3 and 7 | refused at "Crea stanza" with **`already_in_match`** — the new guard doing its job on a host still seated at the previous run's table; swept, re-run |
| 6 (profile bundle, readable stack) | the three `pageerror: Cannot read properties of null (reading 'toString')` lines in every run are Flutter's web `KeyboardConverter` choking on puppeteer's synthetic key events during login typing — engine code, not the app, harmless to play |
| **8 (final tree, 1303 s)** | **19/19 PASS, exit 0.** Boot → semantics tree → account landing → real login → Home → room created → code read → three guests signed up, joined by code, readied → lobby showed them → host pressed Start → table → 4-player match to the end: 334 guest actions, 23 host turns through the UI, 8 rounds, **finished** with the host's screen on the result; server logged the host's own actions and never forfeited it; winner and placements recorded (winner 65 XP, others 20); guest profile updated |

Caveat: the driver only presses Pesca / Passa / Prendi (cards carry semantics
now, but it was written before they did), and it gives the host 12 s per turn
to find a button in the semantics tree; the host still collected two timeouts
in run 8, so on a 30 s timer a slow client is not comfortable. Worth a look on
a real phone.

### The one regression Session 6 caused, and caught
The first redeploy still called the removed `seed31()` at two sites
(`ReferenceError` in the function log): `start` answered 500 for eight
minutes on the dev project and the first post-fix matrix run failed at
"host started the match". Fixed, `deno check` added to the routine,
redeployed, re-run. Nothing was persisted by the failing calls.

### Not verified
- Anything on a physical Android/iOS device or an emulator (none on this
  machine); the APK/AAB were built but **not installed anywhere**.
- iOS compilation (no macOS/Xcode).
- Airplane-mode style network loss (simulated only by channel
  unsubscribe/resubscribe, app-resume and token refresh in the matrix).

---

## 2. Blockers / configuration still needed

1. **Signing keystore** — `android/key.properties` + upload keystore; until
   then release builds are debug-signed.
2. **Rating formula (§12b)** — `app_private.rating_deltas()` returns zeros.
3. **XP economy** — 20/45 per match/win and mission rewards are
   placeholders.
4. **Production Supabase checklist** — SMTP, leaked-password protection,
   CAPTCHA for anonymous sign-ins, per-user Edge Function rate limit, a
   retention period for finished matches.
5. **Device QA** — everything above ran on Linux + Chrome only.
6. Store assets, privacy policy and terms with real URLs (next phase).

---

## 3. Files the next phase must read

0. `docs/CLIENT_CHANGE_2026_08_31.md` — the most recent change, and the one
   thing still outstanding (deploy + online matrix).
1. `docs/FINAL_VERIFICATION.md` — the evidence table.
2. `docs/SECURITY.md` §"Session 6 findings" and §"Known limits".
3. `supabase/migrations/20260830100111_release_hardening.sql` and
   `…110458_receipt_scope.sql`.
4. `lib/features/online/application/online_match_controller.dart`
   (subscription generations, poll cadence, finish).
5. `README.md` — rewritten: setup, env, migrations, run/test/build.
6. `test/client_change_2026_08_31_test.dart`,
   `test/long_session_performance_test.dart` and
   `test/napoletane_deck_test.dart` — the 2026-08-31 guards.

---

## 4. Things the next phase must know

1. After **any** engine change: `tool/build_engine_js.sh`, `deno test`,
   **`deno check supabase/functions/match/index.ts`**, redeploy.
2. Migrations 10 and 11 were applied through the MCP; their remote
   versions are `20260830100111` / `20260830110458` and the local files
   are named to match, so `supabase migration list` shows 11 = 11. The CLI `db push` is blocked by
   the tool sandbox in this environment; the MCP `apply_migration` works.
3. `Motion.reduceMotion` is now a getter (user OR system); tests still
   assign it.
4. `MatchLauncher` is `permanent: true` — call `MatchLauncher.dismiss()`
   when leaving an offline table for good (exit dialog and result screen do).
5. `Log.d` instead of `debugPrint`.
6. The matrix's `hardening` area leaves every player free; the two
   throw-away tables it creates are finished by forfeit.
7. `pkill -f <pattern>` still kills the calling shell when the pattern
   appears in its own command line; use `pgrep -f "patter[n]"`.

---

## 5. Client questions (carry-over + new)

| # | Question | Field / place | Provisional |
|---|---|---|---|
| 1 | Cavallo cancels or passes on a pending +2? | `GameRules.nineBlockMode` | `cancel` |
| 2 | Blocking Cavallo still changes suit? | `nineBlockChangesSuit` | `true` |
| 3 | Online points formula (§12b) | `app_private.rating_deltas` | zeros |
| 4 | XP per match / per win; mission XP | `record_match_result`, `mission_rotation` | 20 / 45; 20–50 per mission |
| 5 | Turn-timer expiry | `timeout.ts`, `srv_commit_action` | safe move; forfeit on 3rd strike; 90 s abandonment; 30 s auto-deal |
| 6 | Daily reward: guests allowed? | `claim_daily_reward` | permanent accounts only |
| 7 | Quick-match timer | `MatchmakingScreen._quickMatchTimerSeconds` | 30 s |
| 8 | Forfeited seat's cards to the stock or out? | `GameEngine._forfeit` | bottom of the stock |
| 9 | CPU offer after how long in the queue? | `MatchmakingScreen.cpuOfferAfterSeconds` | 30 s |
| 10 | Offline missions at all, or online only? | `MissionsController` | both, offline pays local XP only |
| 11 | Bot difficulty default | `SettingsModel.defaultDifficulty` | Normal |
| 12 | **New:** a forfeit before the first completed round — nothing for anyone (current), or a loss for the quitter? | `app_private.settle_match` | nothing for anyone |
| 13 | **New:** "palo" (as in the brief) or "seme" (standard Italian) for a suit? | `app_it.arb` | palo |
| 14 | **New:** guests on the leaderboards and in ranked play? | `leaderboard`, `enqueue_quick_match` | allowed |
| 15 | **New:** retention of finished matches (engine state keeps every hand) | `expire_stale_matches` | kept indefinitely |

---

## 6. Commands

```bash
export PATH="$HOME/flutter-sdk/bin:$HOME/.deno/bin:$PATH"
export ANDROID_HOME=$HOME/Android/Sdk

flutter pub get && flutter analyze && flutter test
dart format lib test tool
flutter gen-l10n                                  # after editing an ARB

dart run tool/bot_simulation.dart
RENDER_PREVIEWS=1 flutter test test/napoletane_deck_test.dart --timeout none
GENERATE_FIXTURES=1 flutter test test/tools/generate_conformance_fixtures.dart
tool/build_engine_js.sh && deno test --allow-read supabase/functions/match/ && deno check supabase/functions/match/index.ts
supabase functions deploy match --use-api
supabase migration list                           # 11 = 11

export SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=…
dart run tool/online_matrix.dart                  # MATRIX_QUICK=1 for the short form
dart run tool/progression_smoke.dart
flutter build web --dart-define-from-file=env/supabase.dev.json
(cd build/web && python3 -m http.server 8787 --bind 127.0.0.1 &)
UI_HOST_PASSWORD=… deno run -A tool/ui_drive_web.ts <outDir>

flutter build apk --release --dart-define-from-file=env/supabase.dev.json
flutter build appbundle --release --dart-define-from-file=env/supabase.dev.json
```

---

## 7. Still true from Sessions 1–5

- Feature-first layout; GetX only; `app_it.arb` is the template; ARB files
  kept sorted; the IT==EN test has an allow-list.
- `MatchLauncher` / `OnlineMatchLauncher` / `TutorialLauncher` register the
  `TableController`; `InitialBinding` runs before `runApp`.
- The engine is pure and deterministic; `seed` is private to the server.
- Two Realtime channels per match; policies may only call `public`
  functions; the online driver is `permanent: true`.
- Every new public function needs an explicit `GRANT`; every new table
  needs RLS + `GRANT SELECT`; the mission rotation lives in Dart and SQL.
- `test/tools/*` are tools; `android/gradle.properties` heap stays lowered
  on this machine.
