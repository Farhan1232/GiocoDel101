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
   `GameRules` plus one case in `CardRuleResolver`.
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

## Session 5 — Offline game, bots, progression and player features ✅

Delivered 2026-08-30: offline 1 + 1–3 bots on the same engine, pause/resume,
"Continua partita", interactive tutorial on controlled engine states,
server-validated achievements, seven-day missions with server-time claims,
paged leaderboard with own rank, offline vs online statistics kept apart,
deal / CENTOUNO! animations, reaction cooldown, CPU fallback from
matchmaking. See `docs/OFFLINE_MODE.md`, `docs/BOTS.md`,
`docs/PROGRESSION.md` and `docs/SESSION_HANDOFF.md`. The on-device
accessibility audit still needs a device.

## Session 6 — Release readiness ✅ (audit, test, break, fix, verify, polish)

Full audit of security (server + client), performance, accessibility,
localisation and hygiene; migration 10 and a redeployed `match` function;
52-bit deal seeds; release manifest and signing config; the verification
matrix in `docs/FINAL_VERIFICATION.md`. Still open for the client: the
rating formula, the XP economy, a signing keystore, store assets, privacy
policy and terms, physical-device QA (no device was available here), and
the production Supabase checklist.

## Explicitly out of scope until asked

AdMob, IAP and subscriptions, store publishing. None of these appear anywhere
in the codebase.
