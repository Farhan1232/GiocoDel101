# Realtime

Session 4, 2026-08-30. What travels live, over which channel, and why a
client never trusts a single event.

## Principle

Realtime is a **hint**, not the truth. Every live signal below tells a
client "something changed — re-read"; the truth is always a row it can
`select` (RLS-filtered) or the `match_snapshot()` RPC. Missing an event
costs latency, never correctness: the online controller also polls every
6 s, re-reads on app resume, and adopts the authoritative reply to its own
requests directly.

## Publication

Migration 6 adds these tables to `supabase_realtime` (all `REPLICA IDENTITY
FULL` so filtered updates carry the whole row):

| Table | Who is told | Used by |
|---|---|---|
| `rooms` | members, and anyone for public lobbies (RLS) | lobby: status → `in_progress`, `match_id` |
| `room_players` | members | lobby: seats, ready, host, heartbeat |
| `matches` | participants | table: clock/status changes without a version bump |
| `match_public_state` | participants | table: "version N is out" |
| `match_private_state` | **the row's owner only** | table: "your hand changed" |
| `matchmaking_queue` | the row's owner | queue: matched → room id |

RLS applies to `postgres_changes` per subscriber: a user subscribed to
`match_private_state` only ever receives their own row's changes, because
the policy is `user_id = auth.uid()`.

## Channels

### `room:<uuid>` — lobby (public channel, RLS on the rows)

`SupabaseRoomsRepository.watch(roomId, onChanged)` subscribes to
`room_players` (filter `room_id`) and `rooms` (filter `id`). Every callback
→ `load(roomId)`. The lobby keeps a 5 s poll and an 8 s `room_heartbeat`
underneath; "connected / away" per seat is derived from `last_seen_at`
(20 s), never trusted from a flag the client could set.

### `match:<uuid>` — table (PRIVATE channel)

`SupabaseOnlineMatchRepository.subscribe(matchId, …)` joins
`match:<matchId>` with `RealtimeChannelConfig(private: true)`. Joining is
itself an authorisation check: `realtime.messages` policies (migration 7)
allow

- `SELECT` (receive broadcast + presence) when
  `public.is_match_member(public.match_topic_id(realtime.topic()))`;
- `INSERT` **only for `extension = 'presence'`** for members.

so a non-participant is refused at join (`Unauthorized`) and a participant
cannot publish a broadcast from the client at all. On the channel:

| Signal | Producer | Client reaction |
|---|---|---|
| `postgres_changes` on `match_public_state` / `match_private_state` (`match_id` filter) | the commit | if `version > mine` → `match_snapshot()` |
| `postgres_changes` UPDATE on `matches` | clock / status / forfeit bookkeeping | re-read (no version to compare) |
| broadcast `reaction` `{userId, seat, key, sentAt}` | **the database** — `send_reaction()` → `realtime.send(…, private = true)` | bubble over that seat (own echo ignored) |
| presence `{userId}` | each member tracks itself after subscribing | available for "connected" badges; the abandonment policy uses the DB heartbeat instead |

Subscribe status → `TableSessionStatus.connection`: `subscribed` → online;
`closed` / `channelError` / `timedOut` → **connecting** ("Riconnessione…"),
re-subscribe with backoff 1.5 s doubling to 15 s, then re-read on success.

## Why not broadcast the state?

Because a broadcast is fire-and-forget: a client that was reconnecting,
backgrounded, or simply slow would be out of sync with nothing to catch up
from. Every change here is a row first; Realtime only announces it. The
reactions are the one thing that is broadcast-only — and losing a "Bravo!"
is harmless.

## Heartbeats and presence policy

- Lobby: `room_heartbeat` every 8 s → `room_players.last_seen_at`.
- Table: `match_heartbeat` every 10 s → `match_players.last_seen_at`.
- Queue: `quick_match_heartbeat` every 3 s → `matchmaking_queue.last_seen_at`
  (rows unseen for 90 s are not matched; unseen for 10 min are swept).

The server's abandonment rule (docs/ONLINE_MULTIPLAYER.md, "The turn clock
and timeouts") reads `last_seen_at`, so a dead socket cannot freeze a table.

## Operational notes

- The `realtime.messages` policies must reference only objects the
  `authenticated` role can execute — migration 6 first used an
  `app_private` helper and members were refused (Realtime reported it as
  `MissingPartition` on the write check); migration 7 moved the parser to
  `public.match_topic_id`.
- Private channels need the Realtime authorisation feature, on by default
  on current projects. `realtime.send()` swallows delivery errors with a
  warning (`ErrorSendingBroadcastMessage`) — check Postgres logs if
  reactions stop arriving.
- Free-plan Realtime limits (concurrent connections, messages/s) are far
  above a card game's needs; each table is one channel per phone.
