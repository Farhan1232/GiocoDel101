# Roadmap

Six sessions. This is Session 1.

## Session 1 — Foundation ✅

Audit, feature-first restructure, design system, localization, the full screen
and navigation shell, reusable components, docs, tests.

Delivered. See `SESSION_HANDOFF.md`.

## Session 2 — Game engine and the outstanding rules

The offline engine already exists and passes its suite. This session closes the
gaps between it and the brief.

1. **§6a — the Cavallo against a pending +2.** Blocked on the client (see
   `GAME_SPEC.md` §14.1). Get the answer first; then one flag on
   `GameRulesConfig` plus one case in `CardRuleResolver`.
2. Turn-timer semantics: what expiry actually does (auto-play / auto-draw /
   forfeit). Undefined today.
3. Simultaneous-elimination tie-break (§12a).
4. Drive the table from `TableSessionStatus` for the online case — the shell
   already reads it.
5. Extend the engine so a match can be **replayed from an ordered action log**,
   which is what makes server-authoritative play possible in Session 3.

Do not start 1–3 without client answers. Nothing in this session should invent
a rule.

## Session 3 — Supabase

1. Project, schema, row-level security. Nothing client-writable that decides an
   outcome.
2. Flip `OnlineStatus.availability` from a constant to a real check.
3. Auth behind `AuthController.submit()` — email/password first, social after.
4. `profiles` table; `ProfileSummary` moves off `fromLocal`.
5. Rooms: create, join by code, realtime lobby, ready state, host start.
6. Server-authoritative match state. The client must never be the referee.
7. Leaderboard — **blocked on the §12b points formula.**

Guard rail: every screen this session touches already exists and is already
tested. If a screen needs restructuring to fit the backend, the model was
wrong, not the screen.

## Session 4 — Online gameplay end to end

Matchmaking, reconnection, disconnect handling, spectator-safe state,
turn timers running for real, anti-cheat review.

## Session 5 — Progression and polish

Real XP and levels, achievements synced, daily rewards with a real balance,
sound and haptics pass, animation polish, accessibility audit on device.

## Session 6 — Release readiness

Store assets, privacy policy and terms with real destinations, crash
reporting, performance pass on low-end Android, signed builds, QA on physical
devices.

## Explicitly out of scope until asked

AdMob, IAP and subscriptions, store publishing. None of these appear anywhere
in the codebase.
