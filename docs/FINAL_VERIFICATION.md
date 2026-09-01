# Final Verification — Session 6 (2026-08-30)

> **Superseded in part on 2026-08-31.** The client's change request of that
> date altered three rules (GAME_SPEC §6b, §12, §12a) and replaced the card
> artwork. Rows below that touch the +2 chain, the start of a round or the
> cards still describe Session 6's behaviour. The current evidence for those
> is **`docs/CLIENT_CHANGE_2026_08_31.md`**; everything else here stands.

What exists, how it was verified, and what was **not** verified. Every row
names the evidence; nothing here is a claim without one. Read with
`docs/SESSION_HANDOFF.md` (the run logs and numbers) and `docs/SECURITY.md`
(the attacks).

Columns: **Implemented** — the feature exists in the code base; **Automated
test** — a `flutter test` / Deno test / simulation pins it; **Real
Supabase** — exercised against the live `GiocoDel101-Dev` project by
`tool/online_matrix.dart`, `tool/progression_smoke.dart` or the
headless-Chrome driver; **Multi-client** — independent authenticated
clients (five in the matrix, two in the smoke, Chrome + supabase-js in the
driver); **Device** — a physical phone or emulator. **No Android device or
emulator and no macOS/Xcode were available on the build machine**, so the
Device column is honest: `—`.

Legend: ✅ yes · ⚠️ partial (see note) · — no · n/a not applicable

| Feature | Implemented | Automated test | Real Supabase | Multi-client | Device | Notes |
|---|---|---|---|---|---|---|
| Splash | ✅ | ✅ `widget_smoke_test`, `session1_screens_test` | n/a | n/a | — | Boot with and without credentials (`BackendServices.none()` path) |
| Onboarding | ✅ | ✅ `session1_screens_test` (IT + EN, 3 sizes) | n/a | n/a | — | |
| Guest sign-in | ✅ | ✅ `session3_auth_test` | ✅ anonymous users signed up by the UI driver and matrix | ✅ | — | Guests: no daily reward, may play online (product decision) |
| Login / Signup / Forgot password | ✅ | ✅ `session3_auth_test`, screens at 5 sizes × 2 text scales (audit run) | ✅ e-mail sign-up of every matrix / smoke user; password sign-in of the UI host | ✅ | — | Nickname trim bug at 16 chars fixed in migration 10 |
| Home | ✅ | ✅ smoke + audit sizes; XP-bar overflow fixed (`session6_release_test`) | ✅ `my_active_match`, `my_daily_missions` reads | n/a | — | |
| Profile / Edit profile | ✅ | ✅ `session3_auth_test`, `session5_screens_test` | ✅ column-level update of nickname/avatar; other columns refused | ✅ RLS: other profile update refused | — | |
| Online mode screen | ✅ | ✅ `session4_online_test` | ✅ | n/a | — | Not-configured / not-signed-in / unreachable states |
| Quick Match | ✅ | ✅ `session5_screens_test` (CPU offer after 30 s) | ✅ matrix QUICK MATCH area (15 checks) | ✅ 5 clients, incompatible sizes wait, cancel, sweep | — | Vanished-row re-enqueue fixed in the client |
| Create Room | ✅ | ✅ | ✅ matrix PRIVATE ROOM + hardening (rules validation, `already_in_match`) | ✅ | — | |
| Join Room | ✅ | ✅ | ✅ join by code, unknown code, full room race, started room | ✅ two racers for the last seat | — | `room_not_found` / `match_already_started` / `room_full` messages |
| Lobby | ✅ | ✅ 4-seat lobby renders at 320–1024 px (audit run) | ✅ ready / start / non-host refused / start twice | ✅ | — | Raw error text removed; poll coalesced |
| 2-player match | ✅ | ✅ `session4_online_test` (fake server), bot simulation | ✅ matrix 2 PLAYER: full game to 101 | ✅ two independent clients | — | see handoff for the run's numbers |
| 3-player match | ✅ | ✅ bot simulation (Easy/Normal/Hard × 3p) | ✅ matrix 3 PLAYER to 45 | ✅ three clients | — | |
| 4-player match | ✅ | ✅ bot simulation × 4p; 4-seat table at 5 sizes | ✅ matrix 4 PLAYER to 45, 8-card hands | ✅ four clients | — | |
| Game table | ✅ | ✅ `gameplay_widget_test`, `widget_smoke_test` | ✅ headless-Chrome host played a full 4-player match through the UI (driver 19/19) | ✅ Chrome + 3 supabase-js guests | — | 1 Hz rebuild scoped to the timer ring; stale round-result sheet fixed (Session 6) |
| Suit selector (Rituale dei Pali) | ✅ | ✅ `gameplay_widget_test`, tutorial lesson 6 | ✅ Cavalli played by both sides in every matrix game | ✅ | — | |
| Reconnect | ✅ | ✅ `session4_online_test` | ✅ matrix RECONNECT (auth from refresh token, snapshot) | ✅ | — | Reconnect churn loop fixed (`session6`) |
| Result screen | ✅ | ✅ smoke (3 sizes) | ✅ matrix MATCH RESULT (placements, `is_winner`, XP); the Chrome host reached it after 8 rounds | ✅ | — | |
| Rematch | ✅ | ✅ | ✅ matrix REMATCH (vote, new deal, same room) | ✅ | — | Forfeited seats no longer block the vote |
| Offline (bots, pass & play, pause, resume) | ✅ | ✅ `session5_offline_test`, `bot_simulation_test` (270 matches) | n/a | n/a | — | Launcher permanence fixed (`session6`) |
| Bots | ✅ | ✅ `bot_test` (fairness), `bot_simulation_test` | n/a | n/a | — | 0 violations, 0 hangs, 0 illegal proposals |
| Tutorial | ✅ | ✅ `session5_tutorial_test` (19) | n/a | n/a | — | |
| Rules screen | ✅ | ✅ | n/a | n/a | — | Active-rules panel from a table |
| Leaderboard | ✅ | ✅ `session5_screens_test` (paging, own rank) | ✅ smoke: pages, own rank, weekly points | ✅ | — | Guests appear (product decision) |
| Achievements | ✅ | ✅ | ✅ smoke: server-evaluated badges, union with offline | ✅ | — | No client write path |
| Daily reward | ✅ | ✅ `session3_auth_test` | ✅ claim / already claimed / guest refused (Session 3 run) | ✅ | — | Race-safe (advisory lock + PK) |
| Missions | ✅ | ✅ `session5_offline_test` (rotation) | ✅ smoke: progress ticks, claim, double claim, expired | ✅ | — | |
| Settings | ✅ | ✅ | n/a | n/a | — | Row tap toggles the switch (48 px target) |
| Loading / error / success / empty / disabled states | ✅ | ✅ `state_views`, screens tests | ✅ error copy verified against the brief's Italian lines | n/a | — | No raw exception text reaches a widget |
| Rule matrix (normal / invalid / wrong turn / ownership / Asso / Due / stacked Due / Nove / Nove block / draw / reshuffle / winner / 101 / rematch) | ✅ | ✅ 59 conformance fixtures (Dart VM **and** the JS engine), `rules_test`, `edge_cases_test`, `scoring_test` | ✅ same engine.js on the server; matrix "0 app-engine moves refused" | ✅ | — | Offline and online agree by construction |
| Scoring: Fante 8 / Cavallo 25 / Re 10 (client correction 2026-09-01, §1 §10) | ✅ | ✅ `scoring_test`, `engine/score_policy_test`, `engine/serialization_test` (migration), `round_end_figure_prices` fixture on VM **and** JS, all 62 fixtures carry the corrected table | ⚠️ not re-run against the live server for this patch — the same `engine.js` is rebuilt and passes all 62 fixtures | ✅ | — | Penalty only — gameplay unchanged; schema 4 migrates both superseded price lists |
| ULTIMA CARTA declaration (client final change, §16) | ✅ | ✅ `ultima_carta_test` (28), 8 `ultima_carta_*` fixtures on VM **and** JS, `gameplay_widget_test` (button), `session4_online_test` (2 tamper cases) | ✅ `online_rule_check` at 2/3/4 seats and the matrix, live: declarations accepted, undeclared plays refused by the SERVER | ✅ independent authenticated users | — | Enforced by the engine, not the button; `lastCardDeclaredBy` is public, hands are not |
| Clockwise sequential dealing (§3, client follow-up 2026-09-01) | ✅ | ✅ `engine/dealing_order_test` (32) — the engine's own card assignment at 2/3/4 seats for every dealer, eliminations, rotation, save/resume; 2 conformance fixtures on VM **and** compiled JS | ✅ `online_rule_check` §3 at 2/3/4 seats: the lap recomputed from the server's `dealerSeat` | ✅ independent authenticated users | — | The 2026-08-31 rotation was cosmetic: `_deal` never read `dealerSeat` |
| Large hands remain visible and playable (client final change) | ✅ | ✅ `large_hand_layout_test` — 5/10/15/20/25 cards × 4 device sizes | n/a | n/a | — | Fixed two real defects: taps landed on the wrong card, and "selection lift" moved cards down |
| Security: own wins / rating / XP / achievement / winner writes | ✅ refused | ✅ Deno tests (policy), SQL review | ✅ matrix RLS + hardening areas (`42501`) | ✅ | — | |
| Security: play twice / opponent card / out of turn / stale / replay / duplicate id / after finish | ✅ refused | ✅ conformance | ✅ matrix CONCURRENCY & ATTACKS | ✅ | — | Receipts now per caller |
| Security: join full / start other's / read opponent cards / read deck / unrelated channel / edit other profile | ✅ refused | ✅ | ✅ matrix PRIVATE HAND SECURITY, RLS, REALTIME | ✅ outsider client | — | Seed widened to 52 bits |
| Network: no internet at start / lost on home / lobby / on turn / opponent's turn / Realtime drop / session expiry / background / foreground / restart / duplicate reconnect | ✅ | ✅ `session4_online_test`, `session6_release_test` (expiry, status dedupe) | ⚠️ reconnect and resume paths in the matrix; socket loss simulated by unsubscribe/resubscribe, not by pulling the cable | ✅ | — | No device to toggle airplane mode on |
| Cleanup: stale rooms / abandoned queue / duplicate members / unfinished matches / duplicate results / duplicate daily reward / orphan state | ✅ | — (SQL) | ✅ inspected on the live project; 4 stalled tables from the UI driver found and closed; sweep re-run manually | n/a | — | Migration 10 |
| Performance: table rebuilds, timer scope, painters, channels, subscriptions, query volume | ✅ | ✅ `session6_release_test` (status equality) | ✅ two channels per match confirmed in the matrix | n/a | — | Audit report in the handoff |
| Cards: 40 unique, suits, ranks, mapping, aspect ratio, no stretch | ✅ | ✅ `deck_test`, `deck_preview_test`, aspect measured at 5 sizes | n/a | n/a | — | Vector art, one `CardMetrics.aspect` |
| Responsive: 320×568 / 360×780 / 430×932 / 800×1280 / 1024×1366, text scale 1.0 / 1.3 | ✅ | ✅ 154-case audit run + `widget_smoke_test` sizes; 0 overflows after the XP-bar fix | n/a | n/a | — | Keyboard: login form scrolls, button reachable |
| Palette / typography / no Material defaults | ✅ | ✅ theme review | n/a | n/a | — | Only Cinzel + Manrope; explicit `ColorScheme` |
| Italian copy (incl. "Scegli il palo") and English locale | ✅ | ✅ `session1_domain_test` (IT≠EN), IT/EN screens | n/a | n/a | — | 20 hardcoded literals localised |
| Accessibility: suits by shape + colour, tap targets, semantics, contrast, large cards, reduce motion, text scaling | ✅ | ✅ `session6_release_test` (card / discard semantics, OS reduce motion) | n/a | n/a | — | Contrast fixes: muted text, danger buttons |
| Android APK (debug, release) and AAB | ✅ | — | n/a | n/a | — | Built on this machine; **not installed anywhere** — no device |
| Large-hand layout on a real device | ⚠️ | ✅ widget tests at four sizes | n/a | n/a | **not run** | No physical device here; the sizes above are the simulated ones |
| iOS | ⚠️ project files only | — | n/a | n/a | — | **Not compiled**: no macOS/Xcode here |

## Rule verification matrix

Every rule below is one or more conformance fixtures
(`test/fixtures/game_conformance/*.json`), replayed on the Dart VM by
`test/engine/*` and on the compiled JavaScript engine by
`deno test supabase/functions/match/`. The server applies the very same
bytes, so offline and online cannot disagree.

| Rule | Fixture(s) | Expected |
|---|---|---|
| Normal card (suit or value) | `play_same_suit`, `play_same_rank` | accepted, turn passes |
| Invalid card | `reject_illegal_card` | `illegalCard` |
| Wrong turn | `reject_wrong_turn`, `reject_unknown_player` | `notPlayersTurn` / `invalidPlayer` |
| Card ownership | `reject_card_not_owned` | `cardNotOwned` |
| Asso (skip) | `asso_two_players`, `asso_three_players`, `asso_four_players_wraps` | next seat skipped, wraps around the table |
| Due (+2) | `due_plus_two`, `due_reject_non_two_under_chain`, `due_reject_pass_under_chain` | chain opens; only a 2 (or a blocking Nove) answers; no pass |
| Stacked Due (+4/+6) | `due_stack_to_four`, `due_stack_to_six`, `due_draw_resolves_four` | penalty accumulates; the draw resolves it |
| Nove / Cavallo (wild, suit change) | `nove_requires_suit_selection`, `nove_choose_suit`, `nove_inline_suit`, `nove_reject_choose_when_not_pending`, `nove_reject_draw_while_choosing` | `suitSelectionRequired`; the chosen suit becomes active |
| Nove block | `nove_blocks_chain_cancel`, `nove_blocks_chain_pass_on`, `nove_cannot_block_when_disabled` | chain cancelled / passed on / refused per `nineBlockMode` |
| Draw | `draw_playable_keeps_turn`, `draw_unplayable_passes_turn`, `pass_after_draw`, `reject_second_draw_same_turn`, `reject_pass_without_draw` | one draw per turn; a playable drawn card keeps the turn |
| Reshuffle | `draw_reshuffles_when_exhausted`, `draw_reshuffles_wide_seed` | discard recycled under the top card; nothing lost; identical on the VM and in JS |
| Winner / round end | `round_ends_and_scores`, `reject_play_during_round_over`, `reject_next_round_mid_round` | scores from opponents' hands; nothing playable between rounds |
| 101 exact / over | `round_end_exact_101_resets`, `round_end_over_101_eliminates_and_finishes` | reset to 0 / eliminated, last seat standing wins |
| Stale state / after finish | `reject_stale_version`, `reject_action_after_finish` | `staleState` / `gameFinished` |
| Next round / rematch deal | `start_next_round_previous_winner_leads`, `start_next_round_wide_seed` | deterministic deal from the seed (31-bit and 52-bit) |
| Forfeit | `forfeit_two_players_ends_match`, `forfeit_off_turn_three_players`, `forfeit_on_turn_clears_chain_and_advances`, `reject_forfeit_when_already_out` | seat out, cards to the stock, chain dies, last seat wins |

All 43 fixtures are listed; `tool/online_matrix.dart` additionally counts
every Asso, Due, Cavallo, block, chain length and reshuffle that occurred
in the real 2/3/4-player games (numbers in the handoff).

## What "verified" means here, and what it does not

- **Verified**: every automated gate is green (`flutter analyze`, 515
  Flutter tests, 50 Deno tests, 270 simulated bot matches with invariants),
  and the live project answered every scripted check listed in the handoff.
- **Not verified**: behaviour on a physical Android or iOS device, an iOS
  build of any kind, real airplane-mode toggling, Play Store / App Store
  packaging, and the client's still-open rule and economy decisions (rating
  formula, XP amounts). The APK/AAB built here are debug-signed until a
  keystore is supplied.

---

# Session 8 addendum (2026-09-01) — the five cosmetic products, legal, delivery

| Feature | Implemented | Automated test | Real Supabase | Device |
|---|---|---|---|---|
| Five non-consumable products, one entitlement each (`ShopCatalog`) | yes | `session7_iap_test.dart` catalog + per-product grant cases | migration 13 + `verify-purchase` v2 on dev | — |
| No cross-grant / no global premium | yes | "owning one item does not own the others" | drill: two entitlements coexist per user | — |
| Store-metadata prices only, no hard-coded price | yes | shop widget test: fake-store string rendered, `€` absent | — | pending consoles |
| Purchase → server verify → complete ordering; failed verify leaves txn open | yes | retry cases (unchanged from S7, re-run) | function answers `verification_unconfigured` until credentials exist | pending sandbox |
| Restore none/one/multiple/all, duplicate callback, never charges | yes | restore group, `buys == 0` asserts | idempotent grant re-run in drill | pending sandbox |
| Entitlement-gated cosmetics; revoke falls back to free defaults | yes | `session8_shop_legal_test.dart` gating group | scoped `srv_revoke_entitlement` drill | — |
| Paid cosmetics render (gold/classic tables, gold back, gilded deck, sigillo) | yes | deck preview + shop previews render clean | n/a | visual check on device pending |
| Client cannot INSERT/UPDATE entitlements or call `srv_*` | yes (RLS + revoked EXECUTE) | — | drill 2026-09-01: 42501 on all four attempts | — |
| Replay another user's transaction refused | yes | fake-server case | drill: `transaction_owned_elsewhere` | — |
| Terms & Privacy screens, IT + EN, placeholders honest | yes | legal group renders both locales at 360px, placeholder assert | n/a | — |
| Hostable legal HTML generated from the same text | yes | `dart run tool/generate_legal_html.dart` reproducible | n/a | — |
| Crash-fix regressions (S7) still hold | yes | `session7_stability_test.dart` + `long_session_performance_test.dart` in the 737 | — | client re-test still pending |

- Full suite after Session 8: **737 Flutter tests, 68 + 6 Deno tests, 0
  failures**; `flutter analyze` clean; bot simulation 270 matches / 72 488
  actions / 0 violations / 0 hangs.
- **Not verified** (unchanged in kind): physical-device behaviour, iOS
  compilation, and REAL store purchases — the five products do not exist in
  any console yet, so the honest status is CODE + SERVER ARCHITECTURE
  COMPLETE, STORE PRODUCT CONFIGURATION PENDING, SANDBOX PURCHASE TEST
  PENDING.
