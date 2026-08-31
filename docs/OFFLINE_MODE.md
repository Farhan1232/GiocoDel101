# Offline Mode

Session 5, 2026-08-30. How a match against the computer or around one
phone works without any network: the flow, pausing and resuming, what is
saved and when, the tutorial, and the presentation layer that rides on the
engine's events. Read with `docs/GAME_ENGINE.md` (the rules),
`docs/BOTS.md` (the opponents) and `docs/PROGRESSION.md` (what a local
match does and does not count for).

## The one sentence

**The same engine, the same table, no backend.** Offline play never
touches a backend seam: `BackendServices.none()` (every gateway reports
"unavailable", nothing is faked) is what the app runs with when Supabase is
not configured, and every offline path below is identical with or without a
signed-in session.

## Modes

| Mode | Seats | Built by |
|---|---|---|
| `GameMode.vsComputer` | 1 person + 1–3 bots (`BotRoster.pick`, distinct names, shuffled) | `MatchFactory.vsComputer(playerName, avatarId, playerCount, difficulty, rules)` |
| `GameMode.passAndPlay` | 2–4 people on one phone | `MatchFactory.passAndPlay(names, avatarIds, rules)` |

`SetupController` (`lib/features/game/application/setup_controller.dart`)
remembers the last choices under `StorageKeys.setupPreferences`: mode,
player count (2–4), difficulty, the Pass & Play names, and the advanced
rules — starting hand 3–10, stack 2s, wild 9, voluntary draw, elimination
above 101, exact-101 reset. `buildRules()` derives them from
`const GameRules()` so defaults live in one place. The human seat is always
`p0` (`MatchFactory.humanSeatId`).

## The flow

```
HomeScreen ─▶ SetupScreen ─▶ MatchLauncher.launch(setup)
                                 GameController registered (+ as TableController)
                                 GameScreen  ─ start() ─▶ DealCue → _animateDeal
                                 ─▶ play (human taps, bots think)
                                 ─▶ pause / resume (PauseOverlay)
                                 ─▶ RoundResultScreen (rows revealed one by one)
                                       ├─ next round: beginNextRound() → new DealCue
                                       └─ match over → MatchResultScreen
                                             ├─ Rivincita: same seats, same rules, new seed
                                             ├─ Nuova partita: home → setup
                                             └─ Home
```

`MatchLauncher` (`lib/features/game/application/match_launcher.dart`) is
the only place a local match is put on screen; it deletes any previous
`TableController`/`GameController`, registers the new one and pushes
`AppRoutes.game` (`replace: true` from a result screen or the CPU fallback).
`GameController` implements `TableController`
(`table_controller.dart`), the contract the table, round-result and
match-result screens draw from; `OnlineMatchController` and
`TutorialController` implement the same contract, so the screens cannot
tell the drivers apart.

### Engine events → table cues

`GameController` subscribes to `GameSession` and turns each `GameEvent`
into a `TableCue` through `TableCues.fromEvent` (`table_cue.dart`), the
one mapping shared with the tutorial: `PlayCardCue`, `DrawCue`
(with `isPenalty`), `SkipCue`, `ChainGrowCue`, `ChainBreakCue` (also for
a cancelling Cavallo block), `LastCardCue` (§16), `SuitChosenCue`,
`RecycleCue`, `InvalidCue`, `TurnCue`. `DealCue` is not an engine event: the engine deals in one step
and the controller queues the cue itself so a round opens with cards
leaving the stock. Cues drain in order; the view's `cuePlayer` animates
each one and reports back (3 s timeout so a stalled view never blocks the
match). `busy` is true while cues play, so input is refused and bots wait.

### Pass & Play

When the seat to act belongs to a different person than the one whose
cards are face up, the controller sets `handoverPlayerId`, hides the hand
behind the handover card and waits for `confirmHandover()` (§67).

## Pausing

`GameController.pause()` sets `paused`, opens a completer and saves.
Bots check `_whilePaused()` after their thinking delay and before acting,
so a bot never moves while the overlay is up; cues already queued finish.

## ULTIMA CARTA offline — §16

The same rule, the same engine, the same two actions, whoever is sitting
there. There is no offline variant of §16 and no local shortcut.

**A person** presses the button. `GameScreen._lastCardButton` is shown exactly
while `TableController.canDeclareLastCard` is true (which is
`GameEngine.canDeclareLastCard` plus "input is enabled"), and it sends
`GameController.declareLastCard()` → `GameSession.declareLastCard()` →
`DeclareLastCardAction`. Once declared it becomes a settled gold badge for the
rest of the turn. If the player taps a card first, `GameController.playCard`
refuses before touching the engine and banners *"Dichiara ULTIMA CARTA prima
di giocare"* — the card stays selected, so pressing the button and tapping once
more plays it.

**A bot** goes through `GameSession.autoPlayCard`, which asks the engine
whether the announcement is due and, if so, sends the very same
`DeclareLastCardAction` before the play. Bots do not bypass the engine and do
not get a private rule: `tool/bot_simulation.dart` drives them through this
path, and a bot that skipped the announcement would show up there as an
illegal proposal.

**Pass & Play** is the person path for every seat, so each player at the
device declares their own last card, and the handover card (§67) hides
nothing else.

The announcement is public: every seat sees *"{name}: ULTIMA CARTA!"* over
the table (`LastCardCue` → `_announceLastCard`), respecting the sound and
Reduce Motion settings like every other cue.

## Bots and the post-penalty continuation — §6b

A bot must not draw a chain and then hand the turn away while the engine still
says it has a move. `GameController._takeBotTurn` therefore asks the bot to
decide **again** after a penalty draw (`round.penaltyResolvedThisTurn`), on the
same `BotViewFactory.forCurrentPlayer` view every other decision comes from —
so a bot's continuation is chosen by the same legality the engine gives a
person, never by a rule written into the driver.

The loop's anti-stall guard changed with it: "did the bot actually move?" is
now `round.version`, not `round.turnNumber`, because since §6b a bot can move
legitimately without the turn number changing. `tool/bot_simulation.dart`
re-runs 270 matches across every difficulty and seat count as the guard on
all of it.
`resume()` completes the completer. `PauseOverlay`
(`presentation/widgets/pause_overlay.dart`) offers Riprendi, Regole (the
rules screen with this table's house rules), toggles for sound, music and
haptics, and Esci. Only local drivers can pause (`canPause`): online the
server clock keeps running and the base class returns a constant false.

`lib/app/app.dart` observes the lifecycle: on `paused` / `detached` /
`hidden` the app pauses audio, calls `persistNow()` and `pause()` on a
registered `GameController` — the bots must not play on while nobody is
watching; on `resumed` music resumes.

## Quitting

The table's back gesture and the pause sheet's Esci both go through
`_confirmExit` in `game_screen.dart`: offline it is `showExitDialog`
(`exit_dialog.dart`, "what happens to the match" copy, Continua / Esci);
online it is the forfeit dialog; in the tutorial a lighter one. Leaving an
offline table calls `abandon()`, which is `persistNow()` — the match stays
resumable. The same happens from the round-result sheet.

## Persistence — §49

`GameStorageService` (`lib/core/storage/game_storage_service.dart`) writes
`GameState.toJson()` under `StorageKeys.savedMatch`: the whole state,
including hands, stock order, seed, history, `playedCards`, `voidSuits`,
`drawsByPlayer`, `stats`, and — since 2026-08-31 — `dealerSeat` (§12a),
`penaltyResolvedThisTurn` (§6b) and `lastCardDeclaredBy` (§16).

All three are written and read back, so a match saved with the dealer three
seats round, in the middle of the continuation a player earned by paying a +2
chain, or with an ULTIMA CARTA already announced, resumes exactly where it
was. **Older saves still load**: a missing `dealerSeat` reads back as seat 0,
which is what dealt round 1 of every match, and an out-of-range one is treated
the same way rather than throwing, so a corrupt dealer can never cost somebody
their saved match. A missing `penaltyResolvedThisTurn` reads back false, the
state any pre-existing save was actually in. A missing `lastCardDeclaredBy`
reads back as "nobody has declared", which is always a playable position: the
seat to act can still press the button and carry on, so no restore can leave a
player stuck.

**The 2026-08-31 price change and old saves.** `GameState.schemaVersion` is
now **3**. A save written under schema 2 or earlier carries a `scoreValues`
table that still prices the Fante at 8 and the Cavallo at 9; resuming it
unchanged would score the very cards the client re-priced at the old rate. So
`GameState._migrateRules` drops that table when — and only when — it matches
the old printed defaults exactly, and `GameRules.defaultScoreValues` (Fante
25, Cavallo 25) takes over. A table the *client* customised is left alone.

| When | How |
|---|---|
| after every drained cue batch, every time the loop hands control to a person, on pause | `_persist()` — coalesced through a 350 ms timer so a burst of penalty draws writes once |
| leaving the screen, app going to background | `persistNow()` — immediate |
| match finished | `storage.clear()` — a finished match never offers "Continua" |
| corrupt JSON on load | discarded and cleared, never surfaced (§52) |

**Resume.** `HomeScreen` shows the "Continua partita" card (`resumeMatch`)
while `hasSavedMatch` is true; it calls `MatchLauncher.resume()`, which
loads the snapshot, drops it if finished, and — if it was taken in the
instant between rounds (`roundOver`) — deals the next round first, then
launches with `MatchFactory.humanIdsOf(saved)`. A resumed match is not
re-dealt on screen: `_startFlow` only queues a `DealCue` when
`version == 0`.

**The Suit-Ritual fix.** A save taken while `status == awaitingSuitChoice`
(the person had just played a Cavallo) used to restore a table waiting on
a choice nobody was asked for. `GameController.onInit` now reopens the
ritual: the Cavallo that asked is the top of the discard pile, so
`pendingSuitChoice = round.topCard` when the seat to act is human.
`test/session5_offline_test.dart` "a save taken during the Suit Ritual
reopens it" covers it; `test/gameplay_widget_test.dart` "the match is
written and restorable" covers the round trip.

## The tutorial — `lib/features/tutorial/`

Eight lessons, each a *real* `GameState` the real engine plays
(`TutorialLessons`, `domain/tutorial_lessons.dart`): hands, top card and
any pending chain are fixed; the cards not placed fill the stock so the
40-card invariant holds. The opponent is Marco (`BotRoster.all.first`) and
the scripted reply is the ordinary `NormalBot` on a hand chosen so its move
is the one the lesson wants — a quiet hand with no Asso, no 2, no Cavallo
and nothing in Coppe. The opener is Coppe 5 unless stated.

| # | Lesson | Table | The player must |
|---|---|---|---|
| 1 | `firstCard` — seme o valore | hand has Coppe 7 (suit) and Spade 5 (rank) among five | play any legal card |
| 2 | `drawing` | nothing playable; Coppe 6 on top of the stock | draw, then play the drawn Coppe 6 |
| 3 | `ace` | Coppe Asso in hand | play it; heads-up the skip returns the turn at once (no opponent reply) |
| 4 | `two` | Coppe 2 in hand | play it; Marco draws two |
| 5 | `chain` | top Coppe 2, +2 pending, chain 1; Spade 2 and Coppe 7 in hand | answer with Spade 2 (+4); Coppe 7 is not legal inside a chain |
| 6 | `cavallo` | Spade Cavallo in hand | play it, then name a suit (any of the four) |
| 7 | `block` | top Coppe 2, +2 pending; Bastoni Cavallo in hand | block with the Cavallo, then name a suit |
| 8 | `centouno` | round 3, scores 40 / 92; one card each: Coppe 7 vs Bastoni Cavallo (value 9) | play the last card: 92 + 9 = 101, Marco resets to zero |

`TutorialController` implements `TableController`: only the asked-for card
lights up (`playableForViewer`) — or every legal card in lesson 1 — and
`accepts()` still defers legality to `session.canPlay`; a wrong card gets
`InvalidCue` and a hint. Phases: `waiting → busy → lessonDone → finished`;
"Avanti" loads the next lesson through `session.restore()` with a fresh
`DealCue`. No statistics, no save, no XP, no coach marks (`isTutorial`).
`lastRoundResult` is never set, so the Centouno lesson ends the round
without the results screen: the overlay shows the `CentounoFlourish`
itself. `TutorialLauncher.launch()` seats it exactly like `MatchLauncher`.
`test/session5_tutorial_test.dart` proves every lesson holds 40 distinct
cards and every step is legal by the engine's own judgement, then walks the
whole course with the scripted opponent.

## Animations — `game_screen.dart`

| Moment | What happens | Duration (`AppDurations`) |
|---|---|---|
| deal | `_animateDeal`: cards leave the stock one at a time, round-robin, 70 ms apart; the viewer's turn face up as they land | per card |
| play | `_animatePlay`: the card flies from the seat to the discard | `cardPlay` 340 ms |
| draw | `_animateDraw`: from the stock to the seat; penalty cards staggered | `cardDraw` 300 ms, `penaltyStagger` 90 ms |
| Asso skip | the skipped seat flashes (`_skippedSeat`) | `aceFlash` 700 ms |
| +2 Chain Storm | `chainLevel`/`chainTotal` drive the storm; `Sfx.chain1…4` rise with the level | `chainPulse` 460 ms |
| 9 Suit Ritual | `SuitRitual` opens for a human Cavallo; ambient shift after the choice | `suitRitual` 520 ms, `ambientShift` 500 ms |
| reshuffle | `_animateRecycle`: a handful of cards sweep back under the stock | — |
| CENTOUNO! | `CentounoFlourish` on the round-result sheet when a row `hitExact101`: the word rises, the Fate Ring completes and resets, the score counts down; `Sfx.reset101` | 2400 ms hold |
| victory | `VictoryFlourish` on the match-result screen, `Sfx.victory` | — |

Every duration goes through `Motion.scale` (`lib/core/utils/motion.dart`):
the animation-speed setting multiplies it; **Reduce Motion** collapses it
to at most 120 ms (28 % of the authored length), drops ambient motion
(`Motion.allowAmbient`), zeroes screen shake, and the flourishes simply
appear. Bot thinking delays are scaled the same way.

## Audio and haptics

`AudioService` (`lib/core/services/audio_service.dart`) plays sixteen
effects plus `music_loop.wav` from `assets/audio/` — all synthesized, all
bundled, nothing streams (`docs/ASSET_INVENTORY.md`). A pool of five
low-latency players lets card sounds overlap; every failure is swallowed.
Music is off by default and sits at volume 0.22. `SettingsController`
pushes the sound / music / haptics toggles into `AudioService.configure`
and `HapticService.configure`; the pause sheet flips the same toggles.

## Reactions — §23

Eight preset lines (`reaction1…8` in the ARB files, `Strings.s.reactions8`);
only the index travels, the phrase is looked up in the player's language.
`GameController.sendReaction` enforces one reaction per **2 s**
(`reactionCooldown`, the same gap `send_reaction` applies online) and shows
`reactionRateLimited` as a banner otherwise. Bot reactions come from
`_maybeBotReaction` (`docs/BOTS.md`). Bubbles last 1.8 s.

## Settings — `lib/features/settings/`

`SettingsModel`: language (it / en), sound, music, haptics, animation speed
(normal / fast), default difficulty, Reduce Motion, high contrast, large
cards (the hand's card width goes from 20 % to 23.5 % of the table),
theme, card back, plus the unlocked cosmetics and seen coach marks. The
account panel shows who is signed in; a guest who signs out is warned
first (`settingsGuestLogoutBody`: the anonymous account and its online
progress are gone for good).

## Rules with the active settings

The rules button on the table and the pause sheet open `HowToPlayScreen`
with `{'rules': state.rules, 'turnTimer': …}`; `_ActiveRulesPanel` lists
the house rules this table is playing by — starting hand, stack 2s, wild
9, nine-block mode, voluntary draw, elimination, exact reset, turn timer
(off for local matches).

## Statistics and progression offline

`RoundResultScreen` calls `StatsController.recordRound` and, when the match
is over, `recordMatch` — **only when `!c.isOnline`**. The local
`StatisticsModel` gets rounds, matches, streaks, suit counts, offline XP
(20 per match, +45 per win) and offline achievements; the human's own card
plays advance today's offline missions as they happen (`noteCardPlayed`,
`noteChainBlocked` from the engine feed). None of this touches the online
rating, `profiles` or the leaderboard — see `docs/PROGRESSION.md`.

## "Continua contro CPU"

`MatchmakingScreen` (`lib/features/rooms/presentation/matchmaking_screen.dart`)
offers the button after `cpuOfferAfterSeconds` = **30 s** in the queue
without a match. `_continueAgainstCpu` cancels the queue for real
(`matchmaking.cancel()`, tolerating "already out"), then launches
`MatchFactory.vsComputer` with the same seat count and the default
difficulty, `replace: true`. The copy says it plainly
(`matchmakingCpuHint`: offline, against the computer, does not count for
the leaderboard). Bots are never presented as people.
`test/session5_screens_test.dart` "after 30 s of waiting: leave the queue,
play offline bots" covers it.

## Verification

- `test/session5_offline_test.dart` — Suit-Ritual resume, fresh-vs-resumed
  deal, bots frozen while paused and moving after resume, the 2 s reaction
  gap, offline missions and XP, the pre-XP save migration, `isBot` driving
  only the thinking indicator.
- `test/session5_tutorial_test.dart` — every lesson's state and steps, the
  whole course, the Centouno ending.
- `test/session5_screens_test.dart` — CPU fallback, pause overlay, tutorial
  overlay, missions and leaderboard screens.
- `test/gameplay_widget_test.dart` — tapping, refusal, the Suit Ritual, the
  reshuffle, the save round trip, the penalty button, and §16: the button
  appearing at two cards, the card refusing to be played until it is pressed,
  and the play going through afterwards.
- `test/ultima_carta_test.dart` — §16 end to end on the engine and on
  `GameSession`: refusal and acceptance, every case where declaring means
  nothing, the resets, the JSON round trip, the legacy save, and a full
  bot-vs-bot match per difficulty that reaches a last card and never has a
  play refused.
- `test/large_hand_layout_test.dart` — the hand at 5/10/15/20/25 cards on four
  device sizes: no overflow, every card reachable and tappable, no card drawn
  below the readable minimum, and a selected card raised and on top.

On 2026-08-30 `flutter test` over `bot_test.dart`, `bot_simulation_test.dart`,
`session5_offline_test.dart` and `session5_tutorial_test.dart` passed
(49 tests); the screen tests were not re-run for this document.
