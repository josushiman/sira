Status: ready-for-agent

# Round Modifiers — Okey atmak, and correcting Çifte

## Problem Statement

Two things are wrong with how Sıra scores a doubled Round.

First, a rule the app has never known about: a player or team can finish a Round by **discarding the joker** — **Okey atmak**. When they do, everyone's points for that Round double. This applies to every Game and every Variant. Today there is no way to record it, so a table playing normally has to either mentally double every number before typing it, or accept a tally that disagrees with the sheet they'd have kept on paper. The whole point of the app is an unarguable total, and this is a routine outcome it cannot represent.

Second, the Çifte the app *does* implement is wrong twice over:

- **The rule is modelled backwards.** Sıra treats Çifte as a Round-wide switch that doubles everyone uniformly. In reality it is called by specific Entrants, and it resolves asymmetrically on the outcome: a caller who **wins** the Round doubles everyone *else*; a caller who **loses** doubles only *themselves*. A `Bool` on the Round cannot express this, because it doesn't record who called.
- **The arithmetic is applied twice.** The keypad entry screen multiplies the entered values by 2 before saving, and `FixedRoundsEngine` then multiplies the same Round by 2 again from `Round.cifte`. **Okey 101 Çifte Rounds currently score ×4.** Gonga escapes the bug only because it doesn't offer Çifte at all.

So a player who calls Çifte in Okey 101 today gets a wrong number, and every player at every table lacks a way to record the joker finish.

## Solution

Round modifiers become facts about **who did what**, recorded on the Round, with all multiplication done in one place — the Match Engines.

- **Okey atmak** is recorded per Round as the Entrant who finished on the joker. Every Entrant's delta for that Round doubles, uniformly. At most one Entrant per Round, and marking someone as the Okey atan implies they won the Round — a 0 in the keypad Variants, the winning team in Okey 21.
- **Çifte** stops being a Round-wide flag and becomes the set of Entrants who called it. Each Engine derives the per-Entrant multiplier from the callers and the Round's outcome. An Entrant doubles if any caller's rule says they do, capped at ×2 from Çifte however many people called.
- **They stack per Entrant.** A losing Çifte caller in a Round somebody finished on the joker takes ×4, while everyone else takes ×2. In Okey 21 both together take the loss from −2 to −8.
- **Gösterge is exempt from both**, as it already is from Çifte.
- **Entry screens** capture both. On the keypad screen (Gonga 101/151, Okey 101) the chip row gains per-Entrant `Çifte` and `Okey attı` chips that act on the active row, reusing the convention `Won the round · 0` already establishes; each row's live preview extends from `×2` to `×4`. The Okey 21 screen gains an `Okey attı` chip alongside its existing Çifte toggle.
- **The scoresheet says why.** A doubled Round is annotated with the modifiers that caused it, so "why is Ada's Round 120?" is answerable from the history rather than from memory.

The ×4 bug is fixed first, as its own step, before any of the new behaviour is built on top of it.

## User Stories

1. As a player, I want to record that someone finished the Round by discarding the joker, so that the doubling that follows is applied for me instead of computed in my head.
2. As a player, I want every Entrant's score for that Round doubled when someone Okey attı, so that the tally matches what we'd have written on paper.
3. As a player, I want Okey atmak available in Gonga 101, Gonga 151, Okey 21 and Okey 101 alike, so that the app matches the rule as we actually play it across every Game.
4. As a Gonga player, I want the control labelled "Jokeri attı", so that it reads in the language we use at a card table rather than in Okey's tile vocabulary.
5. As an Okey player, I want the control labelled "Okey attı", so that it matches what we say at the table.
6. As a player, I want marking someone as the Okey atan to set their score for the Round to 0, so that I don't have to separately record that they won the Round they just finished.
7. As a player, I want only one Entrant to be the Okey atan in a Round, so that an impossible Round can't be recorded.
8. As a player, I want marking a different Entrant as the Okey atan to move the marker rather than add a second one, so that correcting a mis-tap is one action.
9. As a player, I want to clear the Okey atan marker if I set it by mistake, so that a mis-tap isn't baked into the Round.
10. As an Okey player, I want to record *which* Entrants called Çifte rather than flipping a Round-wide switch, so that the asymmetric rule can be applied correctly.
11. As an Okey 101 player, I want a Çifte caller who wins the Round to double everyone *else's* score, so that the rule works the way it does at the table.
12. As an Okey 101 player, I want a Çifte caller who loses the Round to double only *their own* score, so that they carry the cost of a call that didn't come off.
13. As an Okey 101 player, I want more than one Entrant to be able to call Çifte in the same Round, so that the app doesn't forbid a Round that's legal at the table.
14. As an Okey 101 player, I want an Entrant to double at most ×2 from Çifte no matter how many people called it, so that multiple callers don't inflate a score beyond what we'd score by hand.
15. As an Okey 101 player, I want Çifte and Okey atmak to stack per Entrant, so that a losing caller in a joker-finished Round correctly takes ×4 while everyone else takes ×2.
16. As an Okey 21 player, I want a joker finish to take the losing team from −2 to −4, so that the countdown reflects the Round properly.
17. As an Okey 21 player, I want Çifte and a joker finish together to take the loss to −8, so that both events are counted.
18. As an Okey 21 player, I want Gösterge deductions left alone by both Çifte and Okey atmak, so that a find is always worth exactly 1 off the other team.
19. As an Okey 21 player, I want both the Çifte and the Okey attı controls shown even though either alone produces −4, so that the history records which event actually happened.
20. As a player, I want the Çifte chip to apply to whichever Entrant row I have selected, so that recording a caller is the same gesture as entering their score.
21. As a player, I want the chip to light up when the row I'm on is a caller, so that I can see at a glance who I've already marked.
22. As a player, I want to un-mark a Çifte caller by tapping the chip again, so that a mis-tap is correctable without starting the Round over.
23. As a player, I want each row's preview line to show its final multiplied value before I save, so that I can catch a mistake while the Round is still in front of me.
24. As a player, I want the preview to show ×4 where an Entrant is doubled twice, so that a surprising number is explained rather than just large.
25. As a player, I want Gonga's entry screen to keep hiding Çifte while still offering the joker finish, so that I'm not shown a control for a rule my Game doesn't have.
26. As a player, I want modifiers to reset between Rounds, so that a Çifte call in one Round never silently carries into the next.
27. As a player, I want the scoresheet to annotate a Round with the modifiers that applied to it, so that a disputed total can be traced to the event that caused it.
28. As a player, I want the scoresheet annotation to name the Entrant responsible, so that "who called it" is part of the record and not just "this Round doubled."
29. As a player, I want Undo of a doubled Round to reverse the modifiers along with the scores, so that correcting a Round leaves no residue.
30. As a Gonga player, I want an Entrant who goes Out because of a doubled Round to be offered their Rejoin exactly as they would from an ordinary Round, so that doubling doesn't create a special case in the rest of the Match.
31. As a player, I want a Çifte Round in Okey 101 to score ×2 and not ×4, so that the total the app shows is the total we actually played.
32. As a developer, I want the Round to record raw entered counts and never pre-multiplied ones, so that a change to the rules doesn't require reinterpreting data that was saved under the old reading.
33. As a developer, I want every multiplier derived in the Engines and nowhere else, so that there's a single place to look when a score is wrong and no way for a view to double something a second time.
34. As a developer, I want the modifier composition expressed once and shared by all three Engines, so that Çifte and Okey atmak can't drift apart between Win Conditions.
35. As a developer, I want the entry screen's doubling to be presentation-only, so that the preview can be as elaborate as it needs to be without ever affecting what's stored.
36. As a developer, I want the corrected rules covered by tests at the Engine seam, so that the ×4 bug and its class of successors are caught by the suite rather than at a table.

## Implementation Decisions

### Step order

The ×4 fix lands **first and alone**, before any new modelling. Building Okey atmak on top of a live scoring bug makes it impossible for the tests to say which of the two a wrong number came from. Issue 01 is therefore a pure bug fix under the existing `cifte: Bool` model, and everything else is blocked by it.

### Where multiplication happens

Per ADR 0005: `Round` stores **facts**, `Round.deltas` stores **raw** entered counts, and every multiplier is derived in the Engines. This is the decision that makes the ×4 bug structurally impossible to reintroduce — there is exactly one place in the codebase where a Round's scores get scaled.

`RoundEntryState` keeps its doubling logic strictly for the on-screen preview. What it hands to `onSave` is raw. The distinction should be visible in the naming so the next reader can't confuse the two.

### The `Round` model

`Round.cifte: Bool` is replaced by the set of Entrants who called Çifte, and a new optional field records the Entrant who finished on the joker. Both default to empty/nil so existing construction sites and test fixtures stay readable. There is no persistence in this app — `MatchStore` is in-memory with no `Codable` anywhere — so this is a free change with no migration.

Nothing prevents the Okey atan from also being a Çifte caller; they won, so their doubled 0 is still 0. No validation is needed for that combination.

### Multiplier composition

One shared, internal derivation takes a Round plus the Match's Entrants and produces a per-Entrant multiplier. It is consumed by all three Engines so the two modifiers cannot drift apart between Win Conditions. The rules it encodes:

- Base ×1.
- Çifte: an Entrant is doubled if *any* caller's rule applies to them — a caller who lost doubles themselves; a caller who won doubles everyone else. Contribution from Çifte is capped at ×2 regardless of caller count.
- Okey atmak: if set, every Entrant is doubled.
- The two contributions multiply, so the ceiling is ×4 for a single Entrant.

"Winning the Round" for the purposes of Çifte's asymmetry means, in the keypad Variants, an entered value of 0; in Okey 21, being the team that isn't the recorded loser.

### Per Win Condition

- **Survival (Gonga 101/151)**: Çifte is not offered, so only Okey atmak applies — a uniform ×2 on every delta. Out and Rejoin resolution is unchanged and operates on the already-multiplied totals, so a doubled Round can push someone Out exactly as a large ordinary Round would.
- **Fixed Rounds (Okey 101)**: the full composition applies, per-Entrant. This is the only Win Condition where Çifte's asymmetry is observable.
- **Elimination (Okey 21)**: the modifiers scale the losing team's −2 penalty only. Çifte's two branches collapse to the same result here — with one loser, "everyone else doubles" and "the caller doubles" both land on the loser — so Okey 21 does not need to record who called, and its screen keeps a plain toggle. Okey atmak also takes the penalty to −4; both together take it to −8. **Gösterge deductions are never scaled by either modifier.**

### Keypad Round Entry

The chip row gains two chips that follow the screen's existing convention of acting on the **active row**:

- `Çifte` — toggles the active Entrant's caller status; lit when the active row is a caller. Shown only where the Variant supports Çifte, so Gonga continues not to see it.
- `Okey attı` / `Jokeri attı` — marks the active Entrant as the Okey atan and sets their entered value to 0. Exclusive: applying it to another row moves the marker. Tapping it on the current atan clears it. Shown for every Variant.

The label is chosen from the Match's Game. Each row's meta line already reads `now 34   ×2 → 68`; it extends to express ×4 and to mark which rows are callers or the atan. `RoundEntryState` grows the selection state and the preview arithmetic; its saved output stays raw.

Rejecting the alternative of a separate "who called Çifte?" picker section: it would be more explicit but breaks the active-row convention the screen already teaches, adds a second place to look, and pushes a four-player Okey 101 Round into scrolling.

### Okey 21 Round Entry

Gains an `Okey attı` chip next to the existing Çifte toggle. Both are Round-level here, not per-Entrant. The screen's state stays in the view rather than being extracted into a `RoundEntryState`-style struct — its logic is a loser pick, a 0–1 clamp and two flags, which the snapshot and Engine seams already cover.

### Scoresheet

`ScoresheetRow` gains the Round's modifiers so a row can be annotated with what happened and who did it. The row-delta derivation — Standings diffs, no Engine-specific logic — is untouched; this is purely additive data carried alongside.

### Vocabulary

`CONTEXT.md` already carries the corrected **Çifte** entry and the new **Okey atmak** entry. Use those terms: the head-word is the infinitive *Okey atmak*, the Entrant who did it is *the Okey atan*, and the surface labels are per-Game.

## Testing Decisions

A good test here asserts an **observable score**, not the shape of the code that produced it. It builds a Match with a known set of Rounds, asks the Engine for Standings, and checks the totals. It does not reach for the multiplier helper directly, and it does not assert which internal type holds the caller set — both of those are implementation detail that should be free to change.

**`MatchEngine.standings(for:)` is the primary seam.** Every rule in this spec is verifiable there, and it's the highest point at which they're all observable. Prior art: `FixedRoundsEngineTests`, `SurvivalEngineTests`, `EliminationEngineTests`, which already construct Matches from `Round` fixtures and assert per-Entrant totals. `FixedRoundsEngineTests.test_cifteDoublesEveryEntrantsDeltaForThatRound` asserts the *wrong* rule and must be rewritten rather than extended.

Coverage required at that seam:

- A Çifte Round in Okey 101 scores ×2, not ×4 — the regression test for the bug, written in issue 01 under the old model and carried forward.
- Çifte caller wins: everyone else doubles, the caller doesn't.
- Çifte caller loses: only the caller doubles.
- Two callers, one winning and one losing: the loser is ×2, not ×4.
- Okey atmak alone: every delta ×2, in Survival and in Fixed Rounds.
- Okey atmak stacked with a losing Çifte caller: that Entrant ×4, everyone else ×2.
- Okey 21: joker finish → −4; Çifte → −4; both → −8; Gösterge unscaled in all three.
- Survival: a Round doubled by a joker finish pushes an Entrant Out, and the Rejoin target is computed from the doubled totals.

**`RoundEntryState` is the seam for entry behaviour** (`RoundEntryStateTests`, which already drives the struct directly with no view involved). Coverage: the atan is exclusive and clears on re-tap; marking an atan zeroes that Entrant's value; Çifte toggles per Entrant; the preview reports ×2 and ×4 correctly; and — the load-bearing one — **the deltas handed to `onSave` are raw**, never pre-multiplied, for every combination of modifiers.

**`Scoresheet(match:engine:)`** (`ScoresheetTests`) covers that a row carries the modifiers of its Round and that the existing delta derivation is unchanged by their presence.

**Snapshot suites** (`RoundEntryViewSnapshotTests`, `OkeyStandardRoundEntryViewSnapshotTests`, both per ADR 0004) get new cases for the new chips in both themes — including a Gonga Round showing `Jokeri attı` without a Çifte chip, and a row previewing ×4. Existing snapshots will need re-recording where the chip row's layout shifts. These assert appearance only; no rule is verified by a snapshot.

No new seam is introduced. The multiplier composition is tested through the Engines, and `OkeyStandardRoundEntryView` is not given an extracted state struct.

## Out of Scope

- **Persistence and migration.** `MatchStore` is in-memory with no `Codable`; changing `Round`'s shape costs nothing and nothing needs migrating. Persistence remains out of scope for the app as a whole.
- **New Games or Variants.** The four existing Variants are the whole surface.
- **Editing a Round after it's saved.** Correction remains Undo-and-re-enter, as today.
- **Any change to Gösterge**, beyond confirming with tests that both modifiers leave it alone.
- **Any change to Rejoin, Out, or Win Condition resolution.** They consume the multiplied totals and need no awareness of the modifiers.
- **Localisation infrastructure.** The per-Game labels are chosen from `Game` at the point of use; this is not the moment to introduce a string catalogue.

## Further Notes

The ×4 bug has a traceable origin: ticket `04-cifte-gonga` in the `match-scoring` spec specified that entered values be "doubled in the Round that gets saved," while the Engines were independently written to apply `round.cifte` themselves. Both halves were built to their own spec and neither was wrong in isolation. ADR 0005 exists to prevent the recurrence rather than just the instance — the fix is that only one layer is *allowed* to multiply.

The rules in this spec were confirmed directly by the user across two grilling sessions (2026-08-18 and 2026-08-19). Where this spec and the older `match-scoring` spec disagree about Çifte, **this one is correct** — the earlier description of uniform doubling was a simplification that the user has since corrected.
