# Security — the online game

Session 4, 2026-08-30; hardened in Session 6 (same day — see the last two
sections). Threat model, enforcement points, and the attacks that were
actually run. Session 3's `docs/SUPABASE_SECURITY.md` (identity, profiles,
rewards) still applies unchanged.

## Threat model

The phone is hostile. Assume a modified APK that can send any request with
its own valid JWT. It must not be able to:

1. see another player's cards, the deck order, the seed or the next card;
2. act for another seat, out of turn, with a card it does not hold, against
   the rules, or after the match ended;
3. apply an action twice, or apply it against a stale state;
4. decide a winner, a score, XP, rating, streaks, achievements or coins;
5. join a full room, start a room it does not own, or enter a match it is
   not seated at — including its Realtime channel;
6. flood others with messages or send free text.

## Enforcement points

| Concern | Where it is enforced | How |
|---|---|---|
| Identity | Edge gateway (`verify_jwt`) + `auth.getUser()` in the function | the user id comes from the JWT; the body's `playerId` is ignored |
| Membership / seat | `srv_load_match` (`not_a_participant`), `srv_room_for_deal` (`not_a_member`), RLS on every table | the seat is `match_players.engine_player_id` for `auth.uid()` |
| Turn, ownership, legality, pending +2, suit, draw | `GameEngine.validateAction` — the same code as offline, compiled | `notPlayersTurn`, `cardNotOwned`, `illegalCard`, `drawRequired`, `suitSelectionRequired`, … |
| Deck, shuffle, deal, draw | the engine, from a server-generated **52-bit** seed | the client never sees `drawPile` or `seed` (`redact_game_state`); a 31-bit seed (Session 4) could have been recovered by a modified client enumerating deals until one matched its own hand — 2⁵² cannot |
| Version | function (`expectedVersion`) + `srv_commit_action` (`FOR UPDATE`, `stale_version`) | two racers: one commit, one refusal |
| Idempotency | `match_action_receipts (match_id, action_id)`, looked up for the **caller** after the membership check | a repeat returns the receipt; nothing is re-applied; another seat reusing the id is judged afresh |
| Results, stats, rating, XP | `app_private.settle_match` → `record_match_result` | no client grant on any of those columns; `profiles_protect_columns` trigger |
| Achievements (Session 5) | `app_private.evaluate_achievements` at settlement, from `match_round_results` (written by `srv_commit_action` when a round ends) and the final engine state | `user_achievements` has no client write; there is no "unlock" RPC. Offline badges live in the phone's local record and never reach the server |
| Daily missions (Session 5) | progress only via `app_private.track_mission` from `srv_commit_action` (the actor's own accepted `playCard`) and `evaluate_achievements`; claims via `claim_mission_reward` judged on `now()` Europe/Rome | `user_daily_missions` / `daily_missions` refuse client writes (`42501`); `mission_expired` / `not_completed` / `already_claimed`; the phone's clock is never read |
| Leaderboard (Session 5) | `leaderboard(scope, limit, offset)` and `my_leaderboard_rank` are `security invoker` reads over `profiles` / `weekly_points` | paging is bounded (`limit ≤ 200`); rows are real `auth.users` only |
| Rooms | `join_room` (`FOR UPDATE`, `room_full`, `match_already_started`), `create_room` / `join_room` / `enqueue_quick_match` all refuse a seat at a live match (`already_in_match`), `srv_commit_match` (host / kind / seat-set / readiness checks under the room lock) | house rules are validated key by key (`sanitize_room_rules`) before they reach the engine |
| Result farming | `settle_match` skips `record_match_result` / `evaluate_achievements` when the match ended by forfeit before a single round was completed | a throw-away guest cannot hand out wins, XP, streaks or badges for three requests each (provisional policy — §Client questions) |
| Action log | `srv_record_rejection` stores no `card`; ≤ 100 refusals per seat per match | a refused play (still in the actor's hand) is never visible to the other seats; the log cannot be grown without bound |
| Queue | `enqueue_quick_match` under `pg_advisory_xact_lock`; RLS own row | no direct insert; one row per user |
| Channel | `realtime.messages` policies: members may receive; insert = presence only | outsiders refused at join; no client broadcast |
| Reactions | `send_reaction`: whitelist + 2 s gap + membership | server-sent broadcast only |
| Server API | `srv_*` functions: `REVOKE … FROM authenticated`, `GRANT … TO service_role` | callable by the Edge Function only |

Hidden information is enforced by **absence**: the bytes of another hand or
of the stock are not in any row the role `authenticated` can select. The
public state carries `handCount` and `drawPileCount`; the private row
carries one hand and, for the seat on turn, its own drawn card.

## What was attacked, and what happened

Run by `tool/online_matrix.dart` against `GiocoDel101-Dev` with five
independent authenticated users (results as of the run in
`docs/SESSION_HANDOFF.md`):

| Attempt | Outcome |
|---|---|
| read opponent's `match_private_state` row (explicit filter) | `[]` |
| read `app_private.match_engine_state` over REST | `PGRST106` — schema not exposed |
| public state contains `hand` / `drawPile` / `seed` / `drawnCard` / `history` | never — counts only |
| `update match_public_state`, `insert match_actions`, `update match_players.is_winner`, `update matches.winner_id` | `42501` |
| `update profiles.rating / xp / wins` | `42501` |
| `insert matchmaking_queue` directly | `42501` |
| `update match_private_state.hand` | `42501` |
| call `srv_load_match` / `srv_commit_action` as a user | `42501` |
| play outside turn | `notPlayersTurn` |
| play a card the other client holds | `cardNotOwned` |
| spoof `playerId` of the other seat | still judged as own seat → `notPlayersTurn` |
| malformed card id, invalid suit | HTTP 400 |
| stale `expectedVersion` | `staleState` + current version, nothing applied |
| same `actionId` twice, concurrently | one applied, one receipt; version +1 |
| same `actionId` later (network retry) | receipt replayed; version unchanged |
| two different actions at once on one version | one applied, one refused |
| play after finish | `gameFinished` |
| outsider: snapshot / public rows / private rows / action / timeout / rematch / reaction | denied (`not_a_participant`, `[]`, 403) |
| outsider subscribes to `match:<id>` | `Unauthorized … Channel topic` |
| outsider starts someone else's room | `not_a_member` |
| non-host starts a private room | `not_the_host` |
| start with a guest not ready / room not full | `not_everyone_ready` / `room_not_full` |
| start twice | same match, `created:false` |
| two joins for the last seat, concurrently | one seated, one `room_full` |
| join unknown code | `room_not_found` |
| duplicate queue entry | one row |
| client-side broadcast on the match channel | not delivered to members |
| non-preset reaction; second reaction inside 2 s | `invalid_reaction`; `rate_limited` |
| **Session 5** (`tool/progression_smoke.dart`): insert/update `user_daily_missions`, update `daily_missions` | `42501`, progress unchanged |
| call `app_private.track_mission` / a public `track_mission` | `PGRST106` (schema not exposed) / `PGRST202` (no such function) |
| claim a mission that is not complete / already claimed / not today's | `not_completed` / `already_claimed` / `mission_expired` |
| outsider reads `match_round_results` of a match it is not in | `[]` |
| **Session 6** (`hardening` area of `tool/online_matrix.dart`): `create_room` with an unknown key / hand size 40 / a string for a boolean / a 5 KB object | `invalid_rules` |
| join a room whose match started / create or join / queue while seated at a live match | `match_already_started` / `already_in_match` ×3; a member re-entering its own code gets the room |
| play out of turn, then read the action log | `notPlayersTurn`; the logged row has no `card` |
| another seat reuses a refused action id | not replayed: the first run of this check still returned the other seat's receipt from `srv_commit_action`'s own lookup — fixed by migration 11 (`action_id_taken`) and re-run |
| forfeited seat claims a timeout | `invalidPlayer`; the seat is out of the room (rematch never waits on it) |
| 2-player table forfeited before a round | finished, `is_winner` set, **no** win / XP / match counted for either seat |
| rematch on an unknown match id | a code (`match_not_found`), no SQL text in the reply |

## Session 6 findings that were fixed

- 31-bit deal seed → 52-bit (`seed52()` in the function, arithmetic mix in
  `_seededRandom`, two wide-seed conformance fixtures).
- Instant-forfeit result farming → no result before the first completed
  round.
- Refused actions logged the card → stripped; log capped.
- `rooms.rules` unvalidated and unbounded → `sanitize_room_rules`.
- A seat at a live match could open / join another room → `already_in_match`
  everywhere (observed on the dev project: one user at four stalled tables).
- Receipt lookup preceded the membership check and was not scoped → fixed.
- `timeout` accepted from a forfeited caller; a third-strike forfeit left the
  seat in the room and blocked the rematch vote → refused / removed.
- Unmapped database errors were echoed verbatim → `{error: "internal"}` and
  the function log.
- `handle_new_user` could produce a nickname ending in a space and fail the
  sign-up; invisible characters were accepted → fixed / refused.
- Stale `matched` queue row after leaving the lobby by another door → fixed.
- All-absent tables waited 24 h → abandoned after 1 h without action or
  heartbeat; receipts pruned after 7 days.
- `app_private` functions carried default `EXECUTE` → revoked.
- Release manifest lacked `INTERNET` → the release APK could not reach the
  backend at all.

## Known limits and next steps

- **Rate limiting the function itself.** Supabase's gateway does not rate
  limit Edge Functions per user; a hostile client can hammer `match` with
  valid requests (each is cheap and idempotent, but still). Add per-user
  quotas at the gateway or in `srv_commit_action` before production.
- **Anonymous accounts.** Guests can play online (a real `auth.users` row
  each); 30 anonymous sign-ins per hour per IP is Supabase's cap. Enable
  CAPTCHA/Turnstile for production.
- **Client collusion.** Two colluding players can share their hands out of
  band; nothing server-side can prevent that in any card game.
- **Timeout claims** are triggered by opponents' apps; the server verifies
  its own clock, so a claim can never be early — but if *every* opponent is
  offline too, only the 24 h sweep ends the match. A pg_cron job calling the
  `timeout` op through `pg_net` with a service token would close that gap.
- **Leaked-password protection** and email confirmation: still the
  Session 3 production checklist.
- `rating` never moves until the client confirms a formula (§12b): the hook
  is `app_private.rating_deltas`.
- **Guests on the boards.** Anonymous accounts play, claim mission XP and
  appear on the leaderboards like anyone else. Keeping them off the boards
  (or off online play) is a product decision, not a bug.
- **Retention.** Finished matches keep their engine state (seed, every hand)
  and their action log indefinitely; only receipts and queue rows are
  pruned. A weekly purge of old matches is one `DELETE` away when a
  retention period is chosen.
- **Room-code entropy.** Codes come from `random()` over a 32⁶ space with no
  per-user RPC quota; impractical to brute-force, but not cryptographic.
