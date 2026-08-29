# Online Multiplayer

Session 4, 2026-08-30. How a real, server-authoritative match of Gioco del
101 works between 2, 3 or 4 phones. Read with `docs/REALTIME.md` (the live
feed) and `docs/SECURITY.md` (what a client can and cannot do).

## The one sentence

**Flutter asks; the server decides; Postgres remembers; Realtime tells
everyone.** The phone never applies a rule, never shuffles, never draws a
card, never scores, never awards anything. It renders a redacted snapshot
plus its own hand and sends *requests*.

## Where the rules run

The same `GameEngine` that drives the offline table (`lib/features/game/
domain/`, see `docs/GAME_ENGINE.md`) is compiled with `dart compile js` into
`supabase/functions/match/engine.js` and executed by the `match` Edge
Function (Deno). There is no port and no second implementation:

```
tool/engine_js/engine_bridge.dart   thin JSON-in / JSON-out exports
tool/build_engine_js.sh             dart compile js -O2 → supabase/functions/match/engine.js (committed)
supabase/functions/match/engine.ts  typed loader
supabase/functions/match/engine_conformance_test.ts
                                    runs test/fixtures/game_conformance/*.json through the bundle
```

`deno test --allow-read supabase/functions/match/` replays the 41
conformance fixtures against the compiled engine: identical states and
identical event lists to the Dart VM. The only engine change this required
was the shuffle seed mix (`_seededRandom`), which now keeps both XOR operands
below 2³¹ because dart2js truncates bitwise operators to 32 bits — the VM and
the JS build now agree on every deal and reshuffle.

Rebuild and commit `engine.js` after **any** change under
`lib/features/game/domain/` (`tool/build_engine_js.sh`), then redeploy
(`supabase functions deploy match --use-api`).

## The pieces

| Layer | Owns |
|---|---|
| **Postgres** (`supabase/migrations/…online_multiplayer.sql`, `…realtime_topic_helper.sql`) | rooms, seats, the queue, the authoritative state (`app_private.match_engine_state`), the redacted/private views, the action log, idempotency receipts, the turn clock, results, RLS |
| **Edge Function `match`** (`supabase/functions/match/index.ts`) | authenticating the caller, loading state, running the engine, committing through the `srv_*` functions, the timeout policy, dealing, rematch |
| **Realtime** | `postgres_changes` on the tables (RLS per subscriber), one private channel per match for presence and server-sent reactions |
| **Flutter** | `OnlineMatchController` renders snapshots, sends requests, reconciles; `RoomLobbyScreen`, `MatchmakingScreen`, `MatchResultScreen` and `HomeScreen` do the rest |

## One action, end to end

```
tap card  ──▶  OnlineMatchController.playCard
                 · engine.validateAction on the local view (instant feedback only)
                 · MatchActionRequest{matchId, actionId (uuid), expectedVersion, action}
               POST /functions/v1/match {op:"action", …}   (user JWT)
                 · authenticate → auth.users.id
                 · srv_find_receipt(match, actionId)      → replay if seen
                 · srv_load_match(match, user)            → full state, my seat, clock
                 · expectedVersion == version ?           → else {failure:"staleState"}
                 · action.playerId := MY seat (client value ignored)
                 · engine.applyAction(state, action, now)
                 · rejected → srv_record_rejection → {accepted:false, failure}
                 · srv_commit_action(match, user, actionId, baseVersion, newState, [action], 'action')
                       FOR UPDATE on the engine row
                       version == baseVersion ?  → else stale_version (caller re-judges)
                       match_actions += row
                       publish_match_state → engine + public (redacted) + private (hands, drawn card)
                       matches.current_user_id / turn_started_at / turn_deadline_at / last_action_at
                       receipt (match, actionId) := accepted, version
                       finished ? settle_match → placements, record_match_result
               ◀── {accepted:true, version, publicState, hand, drawnCard, events, turnDeadlineAt}
               controller adopts the reply; the other seats get Realtime row changes
               and re-read match_snapshot(); a 6 s poll and app-resume do the same.
```

Two racing actions serialise on the row lock: the second one is refused as
stale and the client re-reads. A retry with the same `actionId` (double
tap, flaky network) gets the stored receipt back and applies nothing. These
paths are exercised for real by `tool/online_matrix.dart` (see
`docs/SESSION_HANDOFF.md` for the run).

## Rooms

`create_room(name, max_players 2–4, is_private, turn_timer 0/15/30/60, rules)`
seats the host at 0 and returns a six-character code. `join_room(code)`
takes the lowest free seat under `FOR UPDATE` on the room row, so two people
racing for the last seat get one `room_full`. `set_ready`, `leave_room`,
`room_heartbeat` as in Session 3; `leave_room` now refuses while a match is
in progress (`match_in_progress`) — leaving a live table is a forfeit
(below).

**Start** is `match {op:"start", roomId}`: host only for private rooms, any
member for quick-match rooms; the room must be full and every guest ready.
The function deals with the engine (random 31-bit seed and random opening
seat from `crypto.getRandomValues`, rules = the room's house rules plus
`turnTimeLimitSeconds` from the room's timer) and calls `srv_commit_match`,
which re-checks the seat set under the room lock, creates `matches`,
`match_players`, publishes the state and flips the room to `in_progress`.
A second start (double tap, two members, a retry) returns the same match
(`created:false`).

## Quick match

`enqueue_quick_match(player_count, turn_timer)` upserts the caller's queue
row (one per user — no duplicates), then, under a single advisory lock,
looks for `player_count` compatible rows seen in the last 90 s. When it
finds them it builds a `kind = 'quick'` room, seats everyone ready, marks
the rows `matched` with the room id, and everybody's next heartbeat
(`quick_match_heartbeat`, every 3 s from the app) or Realtime hint carries
them to the lobby, which starts itself. `cancel_quick_match` removes the row
(and the seat, if already matched). A player in a live match cannot queue
(`already_in_match`). Nobody is ever invented: a seat exists only for a
real `auth.users` row that asked to play.

## The turn clock and timeouts

Only the server writes `turn_started_at` / `turn_deadline_at`
(`matches`). With a timer, the engine stamps the deadline when the turn
changes; between rounds the server allows **30 s** for someone to press
"next round"; with timer `0` there is no deadline. The app draws the ring
from the deadline minus the server clock (`serverNow` from the snapshot
corrects local skew).

**Policy (documented here because the client has not chosen one — see
`docs/GAME_SPEC.md` §14.4):**

1. When the deadline passes, any participant's app calls
   `match {op:"timeout"}`. The function checks the **database** clock and
   `turn_deadline_at`; a claim before the deadline is `deadlineNotReached`.
2. The server then moves for the idle seat, choosing the least harmful legal
   move (`supabase/functions/match/timeout.ts`): a pending suit → the suit
   it holds most of; a pending +2 chain → draw the penalty; otherwise draw
   and, if the turn is still theirs, pass. Between rounds it deals the next
   round. Every move is validated by the engine like any other.
3. The seat's `consecutive_timeouts` grows; any accepted action of its own
   resets it. On the **third** consecutive timeout the server forfeits the
   seat instead (below).
4. With no timer, a seat that has not sent a heartbeat for **90 s while it
   is its turn** counts as timed out (abandonment) — same escalation.
5. A match nobody touched for **24 h** is marked `abandoned` and its room
   `finished` by `app_private.expire_stale_matches()` (pg_cron, every
   10 min, alongside the Session 3 lobby sweep).

So no table can stay stuck: a live opponent always has a lever, and the
sweep closes the rest.

## Forfeit and leaving

`ForfeitAction` is a rules-level action (`GameEngine`, GAME_SPEC §15): the
seat is eliminated, its cards go to the bottom of the stock (conservation
holds), a chain aimed at it dies, an unnamed suit stays whatever was active,
and if only one seat is left the match ends with that seat as winner.
`match {op:"forfeit"}` applies it for the caller, records `forfeited_at` /
`abandoned_by`, and removes the seat from the room. The table's exit dialog
online says plainly that leaving is a forfeit.

## Rounds, results, rematch

- Round over: `lastRoundResult` reaches every client in the public state;
  any seat may send `startNextRound` (the first wins; the others see it
  arrive and the results sheet closes itself). The server deals it after
  30 s if nobody does.
- Match over: `settle_match` writes `final_score`, `placement`, `is_winner`
  on `match_players`, `winner_id` on `matches`, flips the room to
  `finished`, and calls Session 3's `record_match_result`: matches / wins /
  losses / streaks / XP / weekly points / `online_matches` /
  `prima_vittoria`, all server-side. **Rating deltas are 0** —
  `app_private.rating_deltas()` is the single hook for the still-unconfirmed
  formula (§12b); nothing was invented.
- Rematch: `match {op:"rematch"}` records a vote; when every seat still in
  the room has voted the last voter's call deals a fresh match (new seed) on
  the same room, `rooms.match_id` moves, and the result screen launches it.
  Voting again returns the same new match.

## Reconnect and resume

- The socket drops → `TableSessionStatus.connection = connecting`, the top
  bar shows the dot and the banner says **Riconnessione…**; the controller
  re-subscribes with backoff (1.5 s → 15 s) and re-reads the snapshot on
  reconnect. Data still flows through the 6 s poll meanwhile.
- App resume (`AppLifecycleState.resumed`) → re-subscribe + snapshot +
  heartbeat.
- Restart: `my_active_match()` tells the home screen a seat is waiting;
  **Rientra nella partita** (`OnlineMatchLauncher.launch`) restores auth
  (supabase_flutter), reads `match_snapshot` (public state + own hand +
  version + clock + seats), subscribes, and continues. Nothing is assumed
  about events missed while away.

## Reactions

Eight presets (`public.reaction_presets`): `ciao`, `bravo`, `bella_mossa`,
`mamma_mia`, `ahahaha`, `che_fortuna`, `rivincita`, `gg`. Only the key
travels; the phrase is looked up locally in the player's language.
`send_reaction(match, key)` checks membership, the whitelist and a 2 s
minimum gap, then broadcasts from the database (`realtime.send`) on the
private channel. Clients cannot broadcast on that channel at all (insert
policy = presence only). There is no free-text chat.

## The client

- `TableController` (`lib/features/game/application/table_controller.dart`)
  is the contract the table, round-result and match-result screens draw
  from. `GameController` (local) and `OnlineMatchController` (online) both
  implement it; the screens cannot tell them apart.
- `OnlineMatchController` (`lib/features/online/application/`): holds the
  redacted `GameState` merged with the own hand (`GameState.isRedacted`,
  `GamePlayer.concealedCount`, `GameState.drawPileCount` — Session 4
  additions so the server's wire format is a first-class state), derives
  legality with the same engine for highlighting, sends requests with
  `actionId` + `expectedVersion`, adopts replies, and turns state *diffs*
  into the table's cues (opponents' draws animate face-down stand-ins — the
  real cards are never on the device).
- `OnlineMatchRepository` / `MatchmakingRepository` wrap the RPCs, the Edge
  Function and the channels; `NoBackend…` versions keep the widget tests
  offline and honest.
- `OnlineMatchLauncher` registers the driver **`permanent: true`** and
  tears it down explicitly (`dismiss()`) when the player leaves the table.
  The launch replaces the lobby route, and a route-scoped GetX controller
  is deleted the moment its route is popped — the first Chrome run showed
  exactly that: a table frozen on its first frame while the server waited
  for a seat whose timers had been cancelled.

## Verification

`tool/online_matrix.dart` — five independent authenticated clients against
the dev project, playing complete 2/3/4-player matches and every attack in
this document. `test/session4_online_test.dart` — the controller against an
in-process fake server that runs the real engine. Results, with what did and
did not run, are in `docs/SESSION_HANDOFF.md`.
