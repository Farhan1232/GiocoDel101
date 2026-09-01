# Performance / crash audit

Two passes. **Session 9 below is the one that found the mechanism**; Session 7
(further down) fixed four real leaks that were not, on their own, enough.

---

# Session 9 (2026-09-01) — the root cause

## The client's second report

> "The game works at first. After about seven or eight minutes it starts
> slowing down, then it sticks and closes by itself. It happens on several
> phones. It's worse the longer I play and when the score gets high. When I
> open it again it carries on from where it stopped."

The developer could not reproduce it consistently on other phones. So it was
treated as a deterministic software defect, not a low-end-device problem.

## Verdict

| | |
|---|---|
| **Classification** | **E → C/D.** A UI-thread stall that grows without bound (ANR-shaped), with a matching unbounded backlog of platform-channel traffic and its buffers on both sides of the JNI boundary — which is what turns the stall into a process kill. Not a Dart exception, and not a Dart-heap OOM. |
| **Physical reproduction here** | **NO.** `adb devices` is empty; no phone or emulator is attached to this machine. |
| **Root cause** | Found, measured, and fixed. Not inferred from symptoms: the leak is reproduced by an automated test that counts it, at the rate the table actually produces it. |

## Root cause 1 — every sound effect stranded a frame-callback chain, forever

`lib/core/services/audio_service.dart` → `AudioService.play`

### The mechanism

`audioplayers` builds every `AudioPlayer` with a `FramePositionUpdater`, and
`AudioPlayer.play()` → `_resume()` starts it. That updater is this
(`audioplayers-6.8.1/lib/src/position_updater.dart`):

```dart
void _tick(Duration? timestamp) {
  if (_isRunning) {
    update();                                              // a platform call
    _frameCallbackId = SchedulerBinding.instance.scheduleFrameCallback(_tick);
  }
}

void start() {
  _isRunning = true;
  _tick(null);          // no "am I already running?" check
}

void stop() {
  _isRunning = false;
  if (_frameCallbackId != null) {
    SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallbackId!);
  }
}
```

Three facts compose into the failure:

1. **`start()` on an already-running updater forks a second chain.** It calls
   `_tick` again, which schedules another self-rescheduling callback and
   *overwrites* `_frameCallbackId`. The previous chain is now unreachable —
   `stop()` can only ever cancel the newest one — and it keeps rescheduling
   itself because `_isRunning` is still true.
2. **Nothing ever stops it.** The updater is stopped by `pause()`, `stop()`,
   or the `onPlayerComplete` event. The table calls neither of the first two,
   and the third never arrives: on Android in `PlayerMode.lowLatency` the
   backend is `SoundPoolPlayer`, which installs **no completion listener at
   all** — `setOnCompletionListener` appears only in `MediaPlayerWrapper`
   (`audioplayers_android-5.3.0`). SoundPool cannot even report a position:
   `SoundPoolPlayer.getCurrentPosition()` returns `null` unconditionally.
3. **So the count is one stranded chain per `play()` call** — not per player.

Each surviving chain, every frame, forever:

* keeps a transient frame callback registered, so **Flutter can never stop
  producing frames**;
* posts an **un-awaited** `getCurrentPosition` down the method channel, which
  allocates a completer and a message buffer on the Dart side and a task plus
  a buffer on the platform side.

### Why it matches every part of the report

The instrumented table (`test/session9_long_session_stress_test.dart`) makes
**≈1.2 sound effects per second** of ordinary 4-player play. So:

| Minutes played | Stranded chains | Platform messages/second at 60 fps |
|---|---|---|
| 1 | ~70 | ~4 200 |
| 4 | ~290 | ~17 400 |
| **7–8** | **~500–580** | **~30 000–35 000** |

* **Gradual slowdown** — frame cost grows linearly in chains: the scheduler
  walks every one of them per frame and each posts an IPC round trip.
* **Sticks, then closes** — the platform thread cannot service tens of
  thousands of messages a second, so the queue and its buffers grow without
  bound while frames stretch past any budget.
* **Several phones** — nothing here is device-specific.
* **Worse at a high score** — the count tracks total actions, and a high score
  means a long match with many rounds. The last effects to appear for the
  first time are the round-end ones (`scoreTick`, `reset101`, `eliminate`,
  `victory`), so late play adds chains that early play never could.
* **Resumes where it stopped** — autosave is untouched by any of this.
* **The developer could not reproduce it** — `play()` returns immediately when
  sound is off, and a short session never reaches the knee of the curve.

### Measured

In isolation (`test/session9_audio_stability_test.dart`, against a fake
audioplayers platform):

| | Before | After |
|---|---|---|
| Frame callbacks left by 48 effects | **48** | **0** |
| Frame callbacks left by 500 effects | **500** (532 against a 32 baseline) | **0** |
| Native position polls between effects | 1 per player per frame | **0** |

And end to end, on the real route table with the sound on
(`test/session9_long_session_stress_test.dart`, 170 windows = **504 effects
≈ 7.4 minutes of table time**, 13 rounds, 2 matches — the client's failure
window, reproduced):

| At 504 effects | Client's build | Fixed |
|---|---|---|
| Stranded frame callbacks | **506** | **2** |
| Platform-channel position polls, cumulative | **1 218 044** | **0** |
| Wall clock per window | **747 ms** | **129 ms** |
| Live routes | `{/home: 1, /game: 1}` | `{/home: 1, /game: 1}` |
| Elements | 1 794 | 1 746 |

One stranded chain per effect played, to the unit. **1.2 million** platform
round trips in a single session. The same window of play costs **5.8× more**
wall clock at the end of the session than after the fix — and that ratio is
still climbing when the run stops. Route depth, the widget tree and the saved
state are identical in both columns: the *only* thing that grew was this.

### The fix

`AudioService` detaches the poller from every player it builds
(`positionUpdater = null`, one line behind a documented helper). Nothing in
the game listens to `onPositionChanged`, and on Android's low-latency backend
the poller could never have produced a value. Audio behaviour is unchanged.

## Root cause 2 — sound effects were audible only once per app run

`lib/core/services/audio_service.dart` → `AudioService.play`

Session 7 gave each effect a dedicated player that is never released — right,
because the old round-robin pool appended a native bookkeeping entry per
source change. But a player that is never *stopped* is one Android believes is
still playing:

* `WrappedPlayer.play()` is `if (!playing && !released) { … }` — an
  already-playing player starts nothing;
* setting the *same* source again does not clear `playing`
  (`WrappedPlayer.source` returns early and only re-signals "prepared");
* SoundPool never reports completion, so nothing else clears it either;
* and even past that, `SoundPoolPlayer.start()` would `resume()` the finished
  stream instead of starting a new one, because `streamId` is still set.

`test/support/fake_audio_platform.dart` carries `AndroidSoundPoolFake`, a
line-for-line transcription of that state machine. Playing the card-slide
twelve times reached `soundPool.play(...)` **once**. The table went quiet after
its first few seconds and stayed quiet.

**Fix** — stop before playing, with one effect's calls chained so a rapid
repeat cannot interleave. Safe only because the release mode is `stop`: under
`release` the same call would drop the source and re-register it, which is the
native-map growth the dedicated player exists to prevent. Now 12 of 12.

**Please confirm on a phone:** do the card sounds keep playing after the first
minute? This one is diagnosed from the plugin's source and pinned by a fake
that models it, not observed on hardware.

## Root cause 3 — the round result mutated reactive state during a build

`lib/features/game/presentation/round_result_screen.dart`

`initState` called `stats.recordRound(...)`. Although `unawaited`, it runs
synchronously to its first `await`, and `StatsController._commit`'s first
statement is `_stats.value = update.stats` — a global `Rx` assignment.
`initState` runs inside a build, so that marked every `Obx` watching lifetime
statistics dirty in the middle of the build that was mounting the sheet. The
home screen sits mounted under the table and keeps two of them.

Flutter raised **`setState() or markNeedsBuild() called during build` on every
round that ended** — caught in the instrumented run, twice in two rounds. In
release the assert is compiled out and the dirty element is picked up late
rather than lost, so this is a correctness and debuggability defect rather
than the crash; it is on the same path the client's high score walks, and it
was hiding in plain sight on the one screen a long match visits repeatedly.

**Fix** — defer the write to the end of the frame, capturing the match and the
seat *now* so the round is still scored against the table it was shown for. No
`mounted` guard: the round is recorded whether or not the sheet survives.
`test/session9_round_transition_test.dart` holds both halves — no build-phase
mutation, and exactly one settlement per round. All three of its cases fail
without the fix.

## What was measured and found innocent

Every hypothesis in the brief was tested, not assumed. These are clean:

**Engine state and autosave — flat.** 6 000 actions, 156 rounds, 17 matches:

| Actions | 200 | 1 000 | 3 000 | 5 000 | 6 000 |
|---|---|---|---|---|---|
| State JSON | 4 422 B | 4 877 B | 4 390 B | 4 572 B | 4 625 B |
| `jsonEncode` | 1 280 µs¹ | 216 µs | 133 µs | 137 µs | 142 µs |
| `history` | 40 | 33 | 40 | 40 | 40 |
| `playedCards` | 6 | 18 | 5 | 23 | 15 |

¹ first call, JIT warm-up.

`history` is hard-capped at `GameState.historyLimit` (40); `playedCards`,
`drawsByPlayer` and `voidSuits` reset every deal; `MatchStats`' maps are keyed
by player or suit. **No collection in `GameState` grows with the match**, so
neither the saved payload nor the cost of producing it depends on the score or
the number of rounds. The save is ~4 KB, written at most once per settled
action (350 ms coalescer), and one key: measured at 83 writes over 90 s of
play, ~4 KB each.

**Score itself is not a cost.** Nothing in scoring, settlement or presentation
is O(score) or O(rounds). `ScorePolicy` reads the current hands. The score
correlates with the failure only because a high score means a long match — and
what grows with a long match was the audio chains. The one thing that does key
off the score is the Fate Ring's danger pulse at ≥ 99 (§17), one repeating
controller per seat, inside a `RepaintBoundary` — by design, and bounded.

**Routes, controllers, the widget tree — flat.** 22 windows of continuous play
through the real route table, taking the round-result sheet and "Prossima
Mano" exactly as a person does: routes stayed `{/home: 1, /game: 1}` for the
whole session, elements went 1 764 → 1 597 (down), frame callbacks stayed
between 1 and 10 with no trend, and per-window wall clock went 310 ms → 146 ms.

**Image memory — no regression from the shop.** The deck is 40 WebP faces at
360×558 and nothing else; the Session 8 cosmetics add **no bitmaps at all**
(the special deck is `CardFacePainter`, the tables and the Sigillo are
painters). `decodeWidth` still clamps at the 360-px source, and the cache
budget is still 48 MiB against a ~32 MB reachable set.

**No path exits the app.** `SystemNavigator.pop`, `exit(`, `killProcess`,
`moveTaskToBack`, `finishAffinity` — none present anywhere in `lib/` or the
Android sources. The "resumes where it stopped" clue is autosave working, not
a deliberate exit.

**SharedPreferences is not on the UI thread.** `shared_preferences_android`
2.4.28 does use blocking `commit()`, but the generated Pigeon channels run on
`makeBackgroundTaskQueue()`, so those fsyncs never touch the main thread. Left
alone.

**Session 7's fixes all still hold** — rematch route (`offNamedUntil`), decode
clamp, stale-`TableController` force-delete, `.orCancel` on card flights, the
flight layer's own notifier, the online resubscribe guards, the dedicated
audio players, the disposing label cache.

## Why every previous test was green

`long_session_performance_test.dart` asserts on `transientCallbackCount` — the
exact number that gave this away. It passed because **it played in silence**:
`AudioService.init()` cannot reach a platform under `flutter test`, so `_ready`
stayed false and `play()` returned before building a single player. **No test
in the suite had ever executed one line of the sound path.** It also ran with
no route table, so the round-result → next-round loop never ran either.

Both blind spots are now closed: `test/support/fake_audio_platform.dart`
stands the platform up, and `session9_long_session_stress_test.dart` drives
the real route table with the sound on.

## Long-session result, after the fixes

170 windows of a continuous self-playing 4-player table — **498 effects, 13
rounds, 2 matches** (one match played out and a rematch launched), through the
real route table with the sound on, DPR 2.0:

| | window 1 | window 170 |
|---|---|---|
| Frame callbacks | 2 | 2 |
| Native position polls | 0 | **0** |
| Live routes | `{/home: 1, /game: 1}` | `{/home: 1, /game: 1}` |
| Elements | 1 700 | 1 746 |
| Saved state | 2 595 B | 3 433 B |
| `history` | 0 | 16 (cap 40) |
| Encode | 653 µs | 295 µs |
| Wall clock | 721 ms¹ | 129 ms |

¹ window 1 includes the opening deal.

Nothing grows monotonically, across a match boundary and a rematch. Closing
the table returns `transientCallbackCount` to zero. Run against the pre-fix
code the same harness fails at **window 12** — about thirty seconds in — so it
would have caught this long before a phone did.

## Still open

**Physical-device verification.** The mechanism is proven in code and
reproduced by a test that counts the leak at the rate the real table produces
it, but the client's phones are the only true confirmation. Ask for the same
pattern that failed before — one long sitting, several rounds, a high score,
**with the sound on**, which is the condition the defect needs.

No diagnostic build was added. The brief asks for one only if the root cause
cannot be proven; it is proven and measured, and adding a bounded telemetry
path would change release behaviour for no remaining question.

---

# Session 7 (2026-08-31) — the first pass

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
