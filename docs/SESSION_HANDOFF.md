# Session Handoff — Session 4 → Session 5

Date: 2026-08-30. Branch: `feature/session-1-ui-foundation` (continued; the
Session 4 checkpoint commit sits on top of Session 3's).

Sessions 1–3 handoffs are in git history at their checkpoints; what still
matters is summarised in §7.

---

## 0. What Session 4 delivered

**Real, server-authoritative online play for 2, 3 and 4 players — the same
Dart engine, running on the server.**

- **Engine on the server, not a port.** `tool/engine_js/engine_bridge.dart`
  is compiled with `dart compile js` into
  `supabase/functions/match/engine.js` and executed by the `match` Edge
  Function. The 41 conformance fixtures replay identically under Deno
  (`supabase/functions/match/engine_conformance_test.ts`). One engine
  change was needed for this: the shuffle seed mix keeps both XOR operands
  below 2³¹ (dart2js truncates bitwise ops to 32 bits) — one fixture
  regenerated (`start_next_round_previous_winner_leads`).
- **Engine additions:** `ForfeitAction` (GAME_SPEC §12c) with four new
  conformance fixtures and `test/engine/forfeit_test.dart`; stable event
  names (`GameEventName`); first-class *redacted* states
  (`GameState.isRedacted` / `drawPileCount`, `GamePlayer.concealedCount`)
  so the server's wire format parses into the same model the table draws.
- **Migration 6** (`20260829202017_online_multiplayer.sql`): turn clock on
  `matches`, `match_action_receipts` (idempotency), `matchmaking_queue`,
  `reaction_presets`, Realtime publication + private-channel policies,
  `settle_match`, `rating_deltas` (all zeros, the §12b hook), the
  `srv_*` server API (service_role only), client RPCs
  (`enqueue_quick_match`, `cancel_quick_match`, `quick_match_heartbeat`,
  `my_active_match`, `match_snapshot`, `match_heartbeat`,
  `send_reaction`), `leave_room` blocked during a live match,
  `expire_stale_matches`, pg_cron. **Migration 7**
  (`20260829204500_realtime_topic_helper.sql`): the channel policy helper
  moved to `public` (the `authenticated` role cannot execute
  `app_private`). `supabase migration list`: 7 local = 7 remote.
- **Edge Function `match`** (`supabase/functions/match/index.ts`,
  `timeout.ts`, `engine.ts`): ops `ping`, `start`, `action`, `timeout`,
  `forfeit`, `rematch`. Identity from the JWT; the caller's seat from
  `match_players`; expected-version check; engine; one-transaction commit;
  receipts; the documented timeout / abandonment / forfeit policy.
  Deployed to the dev project (`supabase functions deploy match
  --use-api`, `verify_jwt` on).
- **Flutter:** `TableController` contract (`GameController` and the new
  `OnlineMatchController` both implement it; the table, round-result and
  match-result screens are shared). `OnlineMatchController` renders the
  snapshot + own hand, sends requests with `actionId` + `expectedVersion`,
  reconciles from Realtime hints / a 6 s poll / app resume, derives the
  countdown from the server deadline, claims timeouts, maps state diffs to
  the table's cues, handles reactions and rematch votes. Real lobby
  (Realtime + poll + heartbeat, Ready toggle, Start, auto-enter the table),
  real quick-match queue (2/3/4), "Rientra nella partita" on Home,
  "Riconnessione…" in the top bar, forfeit-on-leave dialog, rematch votes
  on the result screen. 43 new IT/EN strings.
- **Docs:** `docs/ONLINE_MULTIPLAYER.md`, `docs/REALTIME.md`,
  `docs/SECURITY.md` (new); `GAME_SPEC.md` §12c, `GAME_ENGINE.md`,
  `DATABASE_SCHEMA.md`, `SUPABASE_SETUP.md`, `SUPABASE_SECURITY.md`
  updated.
- **Verification tooling:** `tool/online_matrix.dart` (five independent
  authenticated clients against the dev project), `tool/ui_drive_web.ts`
  (the real app in headless Chrome as one player + an independent client as
  the other), `test/session4_online_test.dart` (the controller against an
  in-process fake server that runs the real engine).
- Not done, deliberately: offline bots stay as they were (no online bots);
  no rating formula (§12b still unconfirmed — deltas are 0); guest → account
  upgrade UI; SMTP.

---

## 1. Verification — exactly what ran

### Local gates

| Gate | Result |
|---|---|
| `dart format .` | clean (`lib`, `test`, `tool`) |
| `flutter analyze` | **No issues found** |
| `flutter test` | **454/454 passed** (420 baseline + 34 new: 41 conformance fixtures incl. 4 forfeit, `forfeit_test.dart`, `session4_online_test.dart`) |
| `deno test --allow-read supabase/functions/match/` | **48/48** (41 conformance fixtures through the compiled engine + 7 timeout-policy tests) |
| `deno check supabase/functions/match/index.ts` | ok |
| `flutter build web [--profile] --dart-define-from-file=env/supabase.dev.json` | ok (served from `build/web` for the Chrome runs) |
| `deno check tool/ui_drive_web.ts` | ok |

### Remote — GiocoDel101-Dev (`fnyllrjchbqfrzezfeso`)

`tool/online_matrix.dart` — five fresh `auth.users` (`s4-*@example.com`),
each its own `SupabaseClient` and JWT, publishable key only. Two runs on
2026-08-30 against the deployed function:

| Run | Scope | Result |
|---|---|---|
| **4** (full, 35 min) | 2-player to 101 (375 actions, 12 rounds), 3-player to 45 (139 actions, 4 rounds), 4-player to 45 with 8-card hands (441 actions, 6 rounds, **8 reshuffles**, 5 Cavallo blocks), plus every section below | 20/22 areas PASS. The two FAILs: (a) the double-tap race answered `staleState` instead of the receipt once — fixed in `opAction` (receipt re-check on version mismatch), redeployed, green in run 5; (b) the 3-player deal produced no chain for a Cavallo to block (2 + 5 blocks in the other games) — the check is now aggregate |
| **5** (`MATRIX_QUICK=1`, 13 min, after the redeploy) | 2-player to 101 (373 actions, 9 rounds, 4 blocks, 1 reshuffle) + every section except the 3/4-player games | **ALL PASS — 99/99** |

Section results (run 5 unless noted; run 4 identical except the two items above):

| Area | Result | What actually ran |
|---|---|---|
| PRIVATE ROOM | 6/6 | create with code, join by code, start refused while a guest is not ready, non-host cannot start, host starts, START TWICE → same match (`created:false`) |
| PRIVATE HAND SECURITY | 20/20 | own hand 5 cards; public state has no `hand`/`drawPile`/`seed`/`drawnCard`/`history`, `drawPileCount` right; other player's private row `[]`; `app_private` not exposed; every direct write (public state, actions, `is_winner`, `winner_id`, `rating`, `xp`, `wins`, queue, private hand) `42501`; `srv_*` not callable |
| CONCURRENCY & ATTACKS | 12/12 | play outside turn, opponent's card, malformed card, invalid suit, stale version, spoofed `playerId`, DOUBLE TAP (one applied + one receipt), duplicate network retry (receipt replayed, version unchanged), 40-card conservation, TWO USERS JOINING THE LAST SEAT (one `room_full`), unknown code |
| 2 PLAYER | 2/2 | played to 101 by two independent clients, 0 app-engine moves refused by the server |
| 3 PLAYER / 4 PLAYER (run 4) | 3/3 · 3/3 | played to the end by 3 and 4 independent clients, 0 refused; Asso skip verified (next seat +2) |
| ASSO / +2 / STACKING / 9 / 9 BLOCK / RESHUFFLE | all exercised | Assi 29+10+35, Due 25+10+36 with penalty draws, chains to +6 (max chain 3), Cavalli with server-side suit choice, 7 chain blocks, 9 reshuffles — across the run-4 games |
| MATCH RESULT | 6/6 (21/21 in run 4) | `finished`, `winner_id`, one `is_winner`, placements 1..n, profiles `matches/wins/losses/xp` moved server-side (winner +65 XP, others +20), play after finish → `gameFinished` |
| REMATCH | 8/8 | first vote waits 1/2, last vote deals a fresh match, voting again returns it, 5 new cards at v0, room re-pointed, `my_active_match()` = rematch |
| RECONNECT | 3/3 | new client from the refresh token, active match detected, snapshot + own hand + version restored |
| REALTIME | 5/5 | private `match:<id>` joined; row-change channel subscribed; `match_public_state` and own `match_private_state` UPDATEs received with the new version |
| REACTIONS | 5/5 | preset sent; second within 2 s `rate_limited`; broadcast received by the other seat; non-preset refused; client-side broadcast never reaches the others |
| RLS | 9/9 | outsider: snapshot, rows, action, timeout, rematch, reaction all denied; private channel join `Unauthorized`; someone else's room start `not_a_member` |
| TURN TIMER | 3/3 (7/7 in run 4 with the 16 s wait) | deadline persisted (15 s), early claim `deadlineNotReached`, after the deadline any participant triggers the server move, `consecutive_timeouts` = 1, fresh deadline stamped |
| FORFEIT / LEAVE | 4/4 | `leave_room` blocked in a live match; forfeit ends a 2-player match with the other as winner, `abandoned_by` set; forfeit after finish refused |
| QUICK MATCH | 15/15 | enqueue (waiting), re-enqueue = same row, own row only, heartbeat, incompatible size stays waiting, cancel removes, 2nd compatible player matched → `kind=quick` room with exactly the real users, two members start at once → one match, queue rows cleared, `already_in_match` |

### Real app in Chrome (`tool/ui_drive_web.ts`, `flutter build web --profile`)

No phone or emulator exists on this machine (§2), so the real Flutter app
was exercised as a **web build in headless Chrome**, driven only through its
accessibility (semantics) tree — the same nodes a screen reader sees — with
puppeteer, while three **independent supabase-js clients** played the other
seats through the deployed function. Ten runs on 2026-08-30; the last
(`ui_drive_run10`) is the one that counts:

| Step | Result |
|---|---|
| boot, onboarding, account landing | PASS (real screens, Italian) |
| sign-in through the real login form (`s4-ui-host@example.com`) | PASS |
| Home | PASS; after ~10 s (cold RPC) it offers **Rientra nella partita** for an account with a live match — a separate probe tapped it and the client rejoined a match already in progress at v15, tracked it live (v15→19→28→37, fresh deadlines) and showed the round sheet |
| create a room through the UI; lobby shows a real code (`SN3UYZ`) | PASS |
| three independent clients sign up, join by that code, set ready; the host's lobby shows their seats live | PASS |
| host taps INIZIA LA PARTITA → table (Round 1), room points at the dealt match | PASS |
| the match: 9 rounds, 240 guest actions, 799 s, to `finished` | PASS |
| **the Chrome host's own moves reached the server**: 6 accepted `drawCard`/`pass` actions logged with its `actor_id` (the driver can only press Pesca/Passa/Prendi — cards carry no semantics label) | PASS |
| host's screen shows the match result; server recorded winner, placements 1–4, XP (winner 65, others 20); guest profile updated | PASS |
| "host never timed out" | **FAIL, by design of the automation**: on turns where the driver was slower than the 30 s clock the server's policy moved for the host (`consecutive_timeouts` 2) and finally forfeited it — the documented timeout path, seen working from a real client, but it also means the host did not play *every* turn itself |

Findings this run produced (all fixed and re-verified): the online driver
was route-scoped and got deleted when the lobby route was replaced (table
frozen on its first frame) → `permanent: true` + explicit `dismiss()`;
Postgres Changes are not delivered on private channels → two channels;
database broadcasts arrive enveloped; the `authenticated` role cannot run an
`app_private` helper inside a Realtime policy → migration 7; a
receipt/version race on concurrent duplicates → receipt re-check.
Screenshots of every step are produced by the tool (`<outDir>/ui_*.png`).

### Dev-project state left behind
Test accounts `s4-*@example.com` (passwords in the tools), their rooms and
finished matches. Three matches from the pre-fix Chrome runs were ended by
the abandonment policy (timeouts → forfeit) and are `finished`.

### Not verified
- **Android / iOS device or emulator** — none available (no KVM, no
  system images, no sudo for the Linux desktop's GStreamer headers).
- Turn-level timeout of a seat whose *every* opponent is also offline (only
  the 24 h sweep covers that; see `docs/SECURITY.md`).
- Password-reset e-mail, guest → account upgrade (Session 3 carry-overs).

---

## 2. Blockers

1. **Rating formula (§12b)** — `app_private.rating_deltas()` returns zeros;
   `profiles.rating` never moves. One function to fill once the client
   decides.
2. **Turn-timer expiry (§14.4)** — implemented under the provisional policy
   in `docs/ONLINE_MULTIPLAYER.md` (server safe-move, forfeit on the third
   strike, 90 s abandonment without a timer, 30 s auto-deal between
   rounds). The client should confirm or change the numbers; they are
   constants in `supabase/functions/match/timeout.ts` and
   `srv_commit_action`.
3. **No device or emulator on this machine.** Linux desktop is blocked by
   missing GStreamer headers (`audioplayers_linux`, needs sudo); no KVM for
   an Android emulator. The real-app run used the **web build in headless
   Chrome** (see §1). An Android/iOS run is still owed.
4. **Function rate limiting** — none per user yet (see `docs/SECURITY.md`).
5. SMTP, leaked-password protection, CAPTCHA: the Session 3 production
   checklist, unchanged.

---

## 3. Files Session 5 must read

1. `docs/ONLINE_MULTIPLAYER.md` — the whole online design; start here.
2. `docs/SECURITY.md` — the threat model and the attack log; do not weaken.
3. `docs/REALTIME.md` — two channels per match and why.
4. `supabase/functions/match/index.ts` + `timeout.ts` — the only code that
   changes a live match.
5. `supabase/migrations/20260829202017_online_multiplayer.sql` — the
   `srv_*` API and the commit transaction.
6. `lib/features/online/application/online_match_controller.dart` — the
   client driver; `lib/features/game/application/table_controller.dart` —
   the contract the screens use.
7. `tool/online_matrix.dart` — extend it with every new server behaviour.

---

## 4. Things Session 5 must know

1. **After any engine change:** `tool/build_engine_js.sh`, commit
   `engine.js`, `deno test --allow-read supabase/functions/match/`,
   `supabase functions deploy match --use-api`. The fixtures are the
   contract between the app and the server.
2. **Two channels per match.** Postgres Changes are not delivered on
   private channels: row changes use `match-rows:<id>` (plain channel,
   table RLS filters per subscriber); presence + server-sent reactions use
   the private `match:<id>`. Broadcast payloads from the database arrive as
   `{type, event, payload}` — read `payload`.
3. **Realtime policies must only call `public` functions** the
   `authenticated` role can execute (migration 7 lesson).
4. **The pure-Dart `supabase` client needs
   `AuthClientOptions(authFlowType: AuthFlowType.implicit)`** for
   `signUp` (no PKCE store) — `tool/online_matrix.dart` does this.
5. `supabase migration new` may write an empty file and its output pipe can
   hang in a non-TTY shell — write the SQL, then `supabase db push
   < /dev/null` (works without a password prompt on the linked project).
6. `srv_commit_match` needs the match id from the caller
   (`GameState.gameId == matches.id`).
7. `flutter create --platforms=linux .` added `linux/` and a default
   `test/widget_test.dart` (deleted). The Linux build itself needs
   `libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev`.
8. The matrix takes ~25 min (a full 2-player game to 101 plus 3- and
   4-player games at `targetScore: 45`); `MATRIX_SKIP_TIMEOUT=1` skips the
   16 s wait. It leaves test accounts (`s4-*@example.com`) on the dev
   project.
9. `OnlineMatchController.resync()` is coalesced but awaitable; every
   state path goes through `_applyNewState`. Cues are derived from
   `lastAction` + the before/after diff; a version gap skips animation and
   just shows the table.
10. **GetX route-scoped lifecycle bit us once.** `OnlineMatchLauncher`
    replaces the lobby route; a controller registered `permanent: false`
    during the lobby is deleted when that route pops, table still on
    screen. The online driver is therefore `permanent: true` with an
    explicit `OnlineMatchLauncher.dismiss()`. Unit tests never see this —
    only the real app in Chrome did.

---

## 5. Client questions (carry-over + new)

| # | Question | Field / place | Provisional |
|---|---|---|---|
| 1 | Cavallo cancels or passes on a pending +2? | `GameRules.nineBlockMode` | `cancel` |
| 2 | Blocking Cavallo still changes suit? | `nineBlockChangesSuit` | `true` |
| 3 | Online points formula (§12b) | `app_private.rating_deltas` | zeros |
| 4 | XP per match / per win | `record_match_result` | 20 / 45 |
| 5 | Turn-timer expiry | `timeout.ts`, `srv_commit_action` | safe move; forfeit on 3rd strike; 90 s abandonment; 30 s auto-deal |
| 6 | Daily reward: guests allowed? | `claim_daily_reward` | permanent accounts only |
| 7 | Quick-match timer | `MatchmakingScreen._quickMatchTimerSeconds` | 30 s for everyone (compatibility) |
| 8 | Should a forfeited seat's cards go to the stock or stay out? | `GameEngine._forfeit` | bottom of the stock |

---

## 6. Commands

```bash
export PATH="$HOME/flutter-sdk/bin:$HOME/.deno/bin:$PATH"

flutter pub get && flutter analyze && flutter test
dart format lib test tool
flutter gen-l10n                                  # after editing an ARB

tool/build_engine_js.sh                           # after any engine change
deno test --allow-read supabase/functions/match/
supabase db push < /dev/null                      # linked project
supabase functions deploy match --use-api
supabase migration list

SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… dart run tool/online_matrix.dart

flutter build web --dart-define-from-file=env/supabase.dev.json
(cd build/web && python3 -m http.server 8787 --bind 127.0.0.1 &)
deno run -A tool/ui_drive_web.ts /tmp/ui-shots
```

---

## 7. Still true from Sessions 1–3

- Feature-first layout; GetX only; `app_it.arb` is the template — run
  `flutter gen-l10n` after editing an ARB.
- `MatchLauncher` / `OnlineMatchLauncher` register `TableController`;
  `InitialBinding` runs before `runApp`.
- The engine is pure and deterministic; `seed` is private (enforced by
  `redact_game_state`).
- `test/tools/render_previews.dart` and
  `test/tools/generate_conformance_fixtures.dart` are tools, not tests.
- Session 3's auth/profile/rewards model and its 33/33 smoke matrix are
  unchanged (`tool/supabase_smoke.dart`).
- `android/gradle.properties` heap stays lowered on this machine.
