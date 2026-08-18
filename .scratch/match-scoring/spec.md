Status: ready-for-agent

# Match Scoring — Sıra MVP

## Problem Statement

Groups playing Gonga or Okey currently keep score on paper or in their heads. Totals get disputed, someone forgets who's already Out, and nobody can quickly answer "who's winning" or "how many rounds are left." There's no trustworthy, shared source of truth for a Match in progress.

## Solution

A SwiftUI app (Sıra) where a group picks a Game (Gonga or Okey), picks a Variant, sets up Entrants (players or teams), and enters scores Round by Round. The app computes running totals, flags Entrants who've gone Out, offers Rejoin where the Variant allows it, and declares the Match over per its Win Condition — automatically, with no manual arithmetic.

This spec covers the domain logic (the Match Engines) and the screens that drive them, matching the flows already validated in the Claude Design prototype ("Card Game Score Tracker" — see `CONTEXT.md` and the `sira-domain-model`/`design-prototype` memory entries for the glossary and prototype location). It does not cover persistence.

## User Stories

1. As a player, I want to see a home screen listing my Matches, so that I can jump back into one in progress.
2. As a player, I want to filter my Matches by Active / All / Archived, so that finished or old Matches don't clutter my view.
3. As a player, I want to pick a Game (Gonga or Okey) from the home screen, so that I can start a new Match.
4. As a player, I want to see the Variants available for my chosen Game with a short rule summary for each, so that I can pick the right one before committing.
5. As a player, I want to choose whether my Match is Players or Teams of 2 when the Variant allows it, so that it matches how we're actually playing.
6. As a player, I want the mode locked to Teams of 2 when the Variant requires it (Okey standard), so that I can't set up an invalid Match.
7. As a player, I want to choose how many Entrants are in the Match (2–4 players, or teams), so that setup matches our table.
8. As a player, I want to name each Entrant (or accept a sensible placeholder), so that standings are readable at a glance.
9. As a player, I want to choose the number of Rounds (8 or 12) when setting up Okey 101, so that the Match has the length we agreed on.
10. As a player, I want to start the Match once setup is complete, so that I can begin entering Rounds.
11. As a player, I want to enter a Round's result using a keypad, one Entrant at a time, so that I can record raw tile/card counts quickly (Gonga, Okey 101).
12. As a player, I want quick-entry shortcuts for "won the round" (0) and, in Okey 101, "never laid down" (101), so that common outcomes don't require typing.
13. As a player, I want to toggle Çifte for a Round in Gonga or Okey 101, so that every Entrant's delta for that Round doubles when the rule calls for it.
14. As a player, I want to enter an Okey-standard Round by picking which team lost, so that the −2 penalty is applied without me computing it.
15. As a player, I want to record Gösterge finds per team for an Okey-standard Round, capped at one per Entrant per Round, so that the −1-to-the-other-team deduction is applied correctly and can't be over-counted.
16. As a player, I want to toggle Çifte for an Okey-standard Round, so that only the losing team's −2 penalty doubles — Gösterge deductions are never affected.
17. As a player, I want to see a live preview of what each Entrant's total will become before I save a Round, so that I can catch entry mistakes.
18. As a player, I want to save a Round and have standings update immediately, so that the table reflects reality without delay.
19. As a player, I want to undo the most recently saved Round, so that I can correct a mistake, with totals, Out status, and Rejoin state all recalculating correctly.
20. As a player, when an Entrant passes their Variant's limit and goes Out (Survival Win Condition), I want to be offered a Rejoin at the highest score still held by any Entrant still in, so that the Match can continue if we choose.
21. As a player, if I decline a Rejoin offer ("They're out"), I want that Entrant permanently excluded from the rest of the Match, so that the state stays unambiguous.
22. As a player, I want to see current standings ranked by score with each Entrant's Out/Leads status visible, so that I know who's winning without doing the math myself.
23. As a player, I want to see a full Round-by-Round scoresheet (one column per Entrant, one row per Round, totals row), so that I can review how we got here.
24. As a player, I want to see a clear "Match over" banner with the Win Condition's result stated in plain language once the Match ends, so that there's no ambiguity about who won.
25. As a player, I want entry of new Rounds disabled once a Match is over, so that I can't accidentally keep scoring a finished Match.
26. As a player, I want to archive a finished (or abandoned) Match, so that it's hidden from my Active list without deleting its history.
27. As a player, I want to restore an archived Match back to Active, so that archiving isn't a one-way trip.
28. As a player, I want an archived Match to remain fully scoreable if I reopen it, so that archiving never blocks legitimate corrections or continued play.
29. As a developer, I want each of the three Win Conditions (Survival, Elimination, Fixed Rounds) implemented as an independently testable engine, so that each Variant's rules can be verified in isolation and extended without risk to the others.
30. As a developer, I want Match Engines to be pure functions of `Match` → `Standings` with no UI or persistence dependency, so that scoring logic can be unit tested directly and reused across screens (Standings tab, Scoresheet tab, home-list summary line).

## Implementation Decisions

- **Domain model types** (Swift structs/enums, matching `CONTEXT.md`): `Game` (`.gonga`/`.okey`), `Variant` (id, label, rule text, Win Condition, starting score/limit, `teamsOnly`, round count where applicable), `Entrant` (id, name), `Round` (per-Entrant deltas, optional Rejoin event), `Match` (Game, Variant, mode, Entrants, ordered Rounds, archived flag, created/updated timestamp-equivalent to the prototype's `when`).
- **Three Match Engines**, one per Win Condition, each conforming to a shared protocol (e.g. `MatchEngine { func standings(for match: Match) -> Standings }`):
  - `SurvivalEngine` (Gonga 101/151): accumulates deltas; an Entrant whose running total exceeds the Variant's limit becomes Out; Match ends when exactly one Entrant remains not-Out.
  - `EliminationEngine` (Okey standard): counts down from the Variant's starting score; applies −2 to the Round's losing team, doubled by Çifte if set; applies −1 per Gösterge find (capped at 1 per Entrant per Round) to the *other* team, never doubled; Match ends when any Entrant's total reaches 0.
  - `FixedRoundsEngine` (Okey 101): accumulates deltas, optionally doubled by Çifte, no elimination; Match ends after the Variant's configured Round count; lowest total wins.
  - `Standings` output type: per-Entrant total, Out flag, ranked order, delta-from-last-Round, and an `isOver: Bool` / `result: String?` pair describing the Win Condition outcome in the terms of story 24.
- **Variant → Engine mapping** is static and derived from the Variant's declared Win Condition — not user-selectable.
- **Rejoin resolution**: when `standings(for:)` reports a newly-Out Entrant this call that wasn't Out on the prior call, the UI surfaces the Rejoin sheet; accepting appends a Rejoin event to that Round (mirroring the prototype's `{id, to}` shape) rather than mutating history, so Undo remains correct.
- **Gösterge cap**: enforced at the entry-UI layer (stepper clamps 0–1 per Entrant per Round) and defensively in `EliminationEngine` — this corrects the prototype's cap of 3.
- **Çifte in Okey standard**: new entry-UI control (doesn't exist in the prototype) that flags the Round as doubled; `EliminationEngine` applies the doubling only to the −2 penalty, per the confirmed rule.
- **Screens**: Home (list + filter), Variant Picker, Setup, Play (Standings/Scoresheet tabs), Round Entry (keypad and Okey-standard forms), Rejoin sheet — one-to-one with the prototype's `sc-if` branches (`isHome`/`isVariant`/`isSetup`/`isPlay`/`isEntry`, `entryIsKeypad`/`entryIsOkeyStd`).
- **State ownership**: each screen reads Match state and calls into the appropriate Engine to render Standings; no screen re-implements scoring math independently — this is the seam.
- Persistence, theming beyond what's needed to render, and app navigation architecture (NavigationStack vs. custom) are implementation details for the agent to choose, not specified here.

## Testing Decisions

- Good tests here exercise `Match → Standings` through each Engine's public interface only — no reaching into private accumulation state, no UI involved. A test is a fixture Match (a sequence of Rounds) in, an expected `Standings` out.
- Each Engine gets its own unit test suite:
  - `SurvivalEngineTests`: accumulation past the limit → Out; last-one-standing → Match over with correct winner text; Rejoin event correctly resets an Out Entrant's total and clears Out.
  - `EliminationEngineTests`: −2 to losing team; Gösterge −1 to the other team, capped at 1 per Entrant per Round even if the UI somehow sends more; Çifte doubles only the −2, never Gösterge; reaching 0 ends the Match with correct result text.
  - `FixedRoundsEngineTests`: Çifte doubles every delta; Match doesn't end before the configured Round count; lowest total wins at the end; ties (if reachable) produce a defined, tested result.
- Undo is tested by asserting `Standings` before and after appending-then-removing a Round are identical, across all three Engines.
- No prior art exists in this repo yet (currently a blank SwiftUI template with no test target) — the agent should add a standard XCTest (or Swift Testing) target as part of this work, there being no existing convention to match.

## Out of Scope

- Persistence/storage of Matches (SwiftData, CoreData, files, or otherwise) — Matches may be in-memory for this spec, as in the prototype's `seed()`.
- Multi-device sync or sharing a Match between players' phones.
- Adding any Game or Variant beyond Gonga (101/151) and Okey (standard, 101).
- Theming system beyond rendering whatever theme tokens are chosen (the prototype's 4-theme swatcher is a visual nice-to-have, not scoring logic).
- Localization beyond the Turkish domain terms already fixed in `CONTEXT.md` (Gösterge, Çifte, Sıra).
- Watch app, widgets, notifications.

## Further Notes

- Full glossary and rule definitions: `CONTEXT.md` at the repo root.
- Reference UI/flow: the Claude Design prototype — see the `design-prototype` memory entry for the project URL and file breakdown. Treat its screen flow as the spec for layout/interaction; treat its scoring code as reference *except* where this spec explicitly corrects it (Gösterge cap, Çifte-in-Elimination scope).
- The `sira-domain-model` memory entry tracks the two rule corrections vs. the prototype so they aren't silently reverted.
