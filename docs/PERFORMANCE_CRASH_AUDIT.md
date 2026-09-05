# Performance / crash audit — Session 7 (2026-08-31)

## The client's symptom

> "At first the game works well. While playing, it gradually starts slowing
> down and eventually it force-closes/crashes. I tested it on another phone
> too and the same thing happens."

Reproduced on at least two physical Android phones. Treated as a P0 release
blocker: a gradual slowdown ending in a force-close is the signature of
**memory that grows with play** (GC pressure → jank → the OS kills the
process), plus CPU cost that scales with session length.

## Reproduction status

**PHYSICAL DEVICE CRASH REPRODUCTION NOT VERIFIED** — no Android device or
emulator is attached to this machine (`adb devices` is empty). What follows
is a code-level audit (four parallel deep passes: timers/subscriptions/GetX,
audio/animations, image memory, state growth/rebuilds) with every finding
verified against the source, several of them proven by new automated tests.
The previous session's harness could not see these bugs, and §"Why the tests
were green" explains why.

## Root causes found (in order of impact)

### 1. Offline "Rivincita" retained one whole table per rematch — memory, unbounded

`MatchLauncher.launch(replace: true)` used `Get.offNamed(game)`, which
replaces only the result screen: the **previous `/game` route stayed mounted
underneath the new one**. Every rematch stacked a full retained table —
~900 elements, all card widgets, and a strong reference to the dead
`GameController` → `GameSession` → `GameState`. An evening of "Rivincita"
grows memory monotonically until the OS force-closes the app — exactly the
report. (The online launcher already did this correctly with
`offNamedUntil`.)

**Fix** `lib/features/game/application/match_launcher.dart` — pop to Home
before pushing the new table, mirroring the online path.
**Guard** `test/session7_stability_test.dart` drives three rematches through
the real route table and asserts exactly one `/game` route and a
non-growing element tree.

### 2. Card image decodes above the source resolution — memory, up to ~144 MB

The faces ship at **360×558**. `CardFaceImage.decodeWidth` stepped the decode
request by 64 px and clamped at **720** — but `ResizeImage` keeps the
*requested* width in the cache key while clamping the actual decode to the
source. On DPR ≥ 2.6 phones ordinary hand/table cards requested keys 384,
448, 512… — up to **seven byte-identical full-resolution bitmaps per card**
(785 KB each decoded). Reachable set: ~113 MB on a DPR 3.0 phone, ~144 MB on
DPR 3.5 — **against Flutter's default 100 MiB image-cache budget, which the
app never configured**. The cache runs permanently full and LRU-thrashes:
evict → re-decode WebP on the IO thread → evict. That is both halves of the
report at once (progressive jank + memory pressure).

**Fixes**
- `decodeWidth` now clamps at the 360-px source and snaps every request
  ≥ 256 straight to 360: one full-quality entry per card on every modern
  phone (whole deck ≈ 31 MB), small steps preserved for thumbnails.
- `main.dart` caps `imageCache.maximumSizeBytes` at **48 MiB** — the deck
  fits with headroom; runaway growth is now structurally impossible.
- `FilterQuality.medium → low` on card faces: `medium` makes Impeller build
  a mip chain per (card, size) — a raster-thread stall on first draw and
  ~+33 % GPU memory — for a ≤1.4× downscale where bilinear is identical.

**Guard** `session7_stability_test.dart` proves `decodeWidth` never exceeds
the source, that all ordinary phone sizes share the single 360 key, and that
at most 4 distinct keys exist per card across every size×DPR the app uses.

### 3. A stale `TableController` key silently captured the next online match — sockets + timers, unbounded

GetX's `Get.put` **keeps the existing instance when the key is already
registered** — the new one is dropped. Two ordinary exits leaked a
registration: leaving the tutorial via its "Home"/"Play now" buttons (the
tutorial controller is linked to the never-disposed home route), and exiting
a local match from the round-result sheet (`_exit` dismissed only the online
driver). After either, the next **online** launch created a live
`OnlineMatchController` — 2 Realtime channels, 1 s clock, 6 s poll, 10 s
heartbeat, lifecycle observer — that **no screen could reach and no
`dismiss()` could ever delete** (the dismiss guard read the stale
registration's type). One invisible live match per launch, forever.

**Fixes**
- `OnlineMatchLauncher.launch` force-deletes any stale `TableController`
  before `Get.put`.
- `TutorialLauncher.dismiss()` added and called from both tutorial exits and
  the game screen's tutorial exit.
- `RoundResultScreen._exit` gained the missing `else MatchLauncher.dismiss()`.
- Sign-out now dismisses all three launchers.

**Guards** `session7_stability_test.dart`: a planted stale registration must
lose to the next launch; tutorial dismiss must clear both keys with zero
tickers left.

### 4. Card-flight awaits stranded on teardown — memory per exit

`await controller.forward()` never resumes when the ticker is disposed
(the primary `TickerFuture` completer is simply never completed), so every
card airborne at teardown left a suspended continuation retaining the whole
disposed `_GameScreenState` — up to ~28 per mid-deal exit, accumulating
across a session of many matches. The `_hidden` set also leaked ids on any
failed flight (`Future.wait` rejects on the first error), leaving cards
permanently invisible.

**Fixes** in `game_screen.dart`: `.orCancel` with a `TickerCanceled` branch
and `try/finally` around every flight; `_hidden` released in `finally` on
every path and cleared at each deal; `mounted` checks in the stagger loops
(the deal's inner `break` now exits both loops).

### 5. Whole-table rebuilds per flight — CPU, scales with hand size

Every flight add/remove was a `setState` on the screen root: one deal =
~64 full-table rebuilds in ~2 s, each reconstructing every `PlayingCard` —
and the hand can legitimately grow to 25+ cards (§6b penalty chains), so
this cost grows as a round progresses. The flight layer now listens to its
own `ValueNotifier` (`_flightsVersion`); flights repaint one layer instead
of the whole table. (The `_hidden` updates, ~10 per deal, still rebuild the
hand — they change it.)

### 6. Online: work that outlived its usefulness

- **Finished match kept re-subscribing**: `_maybeFinish` cancelled the
  timers but not `_reconnect` or the subscription — a socket drop on the
  result screen re-opened channel pairs forever, and an app resume
  re-subscribed a finished match. Both closed now; `_resubscribe` refuses
  after finish. (Rematch has its own 3 s poll; unaffected.)
- **The 6 s poll rebuilt the table on unchanged versions**: `_adoptSnapshot`
  now returns early on `version == current` (clock skew still recalibrated).
- **Channel close was sequential**: on a half-open socket each unsubscribe
  waits out the leave timeout; paying it twice serially left 4 channels
  alive ~20 s after every app resume. Closed in parallel now.

### 7. Audio: unbounded native bookkeeping — memory, slow

The round-robin pool of 5 players re-assigned a source on almost every
effect, and audioplayers' Android backend (`SoundPoolPlayer.urlSource`)
**appends a native map entry per source change, removed only on release()**
— which was never called (`ReleaseMode.stop`). One entry per sound played,
forever. Replaced with one dedicated player per effect (bounded at the 16
`Sfx` values): a player whose source never changes appends exactly once.
`init()` also gained a coalescing guard (two concurrent calls would each
have built a player set) and a retry path.

### 8. Smaller confirmed items

- `HandFan._reject`: rapid taps cancelled the previous `TickerFuture`, whose
  `whenComplete` then never fired — `_shakingCard` pinned. Now
  `whenCompleteOrCancel` with a staleness check.
- `CardFacePainter._labelCache`: the 120-entry flush now disposes the
  `TextPainter`s (native paragraphs) instead of abandoning them to the GC.
- Matchmaking: a vanished queue row during `_matchedInto` left the screen
  frozen "searching" with all timers dead (`_searching` was never cleared,
  so `_search()` refused to run). Fixed.
- Room lobby: a failed match launch left the lobby with no poll and no
  heartbeat — the seat silently expired server-side. Timers re-armed on
  failure.
- Online rematch: the unawaited `launch` could throw an unhandled async
  exception. Caught.

## Why the previous tests were green

`test/long_session_performance_test.dart` runs with **`devicePixelRatio =
1.0`** (where the whole image problem collapses to ~4 MB), **Reduce Motion
on**, a host with **no route table** (so the round-result → match-result →
rematch path — the leak — never executes), no audio init, and it never
asserted on `imageCacheBytes`. Its ticker/element/history assertions are
genuinely useful and all still pass; the new `session7_stability_test.dart`
covers the blind spots that map to real phones.

## Measurements

Baseline (before fixes) and after, same machine, same seeds:

| Gate | Before | After |
|---|---|---|
| `flutter test` | 687/687 | **712/712** (25 new: 7 stability + 18 IAP) |
| long-session harness | 12 windows, ticks ≤4, elements flat, no wall-clock growth | same (unchanged assertions still pass) |
| bot simulation | 270 matches / 72 488 actions / 0 violations / 0 hangs | 270 matches / 0 violations / 0 hangs |
| deno (match) | 68/68 | 68/68 |
| rematch route stack | *(not measured — the leak)* | 1 `/game` route after 3 rematches; elements < 2× first |
| decode keys per card | up to 7, keys to 720 px | ≤ 4, hard cap at 360 px |
| image-cache budget | 100 MiB (default) vs ~113–144 MB reachable | 48 MiB vs ~31–35 MB reachable |

## What remains open

- **Physical-device verification.** The fixes target mechanisms proven in
  code, several of which mathematically explain the symptom, but the
  client's phones are the only true test. Ask the client to re-test the new
  APK with the exact pattern that failed before: several consecutive
  matches using "Rivincita", the tutorial followed by an online match, and
  long rounds with big penalty chains. If it still degrades, capture
  `adb logcat` around the crash — the audit doc's suspect list is now short.
- The round-result route is deliberately non-opaque (the sheet floats over a
  dimmed table), so both screens render while it is up — a bounded,
  per-round cost, kept for the design.
- Per-event SharedPreferences writes in `StatsController.noteMissionEvent`
  are uncoalesced (a few per turn worst-case) — a minor jank suspect left
  alone deliberately; persistence semantics are load-bearing for tests.
