# Security — the online game

Session 4, 2026-08-30. Threat model, enforcement points, and the attacks
that were actually run. Session 3's `docs/SUPABASE_SECURITY.md` (identity,
profiles, rewards) still applies unchanged.

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
| Deck, shuffle, deal, draw | the engine, from a server-generated seed | the client never sees `drawPile` or `seed` (`redact_game_state`) |
| Version | function (`expectedVersion`) + `srv_commit_action` (`FOR UPDATE`, `stale_version`) | two racers: one commit, one refusal |
| Idempotency | `match_action_receipts (match_id, action_id)` | a repeat returns the receipt; nothing is re-applied |
| Results, stats, rating, XP | `app_private.settle_match` → `record_match_result` | no client grant on any of those columns; `profiles_protect_columns` trigger |
| Rooms | `join_room` (`FOR UPDATE`, `room_full`), `srv_commit_match` (host / kind / seat-set / readiness checks under the room lock) | |
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
