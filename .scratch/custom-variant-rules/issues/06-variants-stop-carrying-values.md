# 06 — Variants stop carrying values

**What to build:** Nothing a player can see. This is the contract half of the expand–contract that ticket 01 opened: every Match now stores the number it is played at, so the Variant constants that used to supply one are dead weight, and the accessor's fallback to them is a path nothing takes.

`limit`, `startingScore` and `roundCount` become `nil` on all three Variants. A Variant is left describing **shape** only — Win Condition, Entrant mode, maximum Entrants, Çifte support, entry style, and Okey 101's "never laid down" value — and nothing about how far a Match runs.

The accessor drops its constant fallback. A number that cannot be resolved now returns `nil`, and such a Match is skipped at the `scorable` / `scorableMatch` gate exactly as a Match naming an unknown Variant id is today — skipped, never scored against a substitute, and never deleted. Its data stays where it is, so a bad write or a downgrade stays recoverable (ADR 0007).

This narrows ADR 0007 rather than contradicting it. The Variant id remains the frozen persistence contract and still resolves everything about how a Match is *scored*; what it no longer resolves is how far the Match runs, which was never a rule the app could correct on a player's behalf. A limit is a table decision, not a bug a later release might fix — which is also why every Match stores its number even at the preselected value, so nothing ever has to reason about whether a stored value means "the player chose this" or "nothing was chosen".

**Blocked by:** 02, 03, 05.

**Status:** done

- [x] `limit`, `startingScore` and `roundCount` are `nil` on all three Variants
- [x] The accessor on `Match` resolves only from the Match, with no fallback to a constant, and returns `nil` when it cannot
- [x] A Match with an unresolvable number is skipped by `scorable` and `scorableMatch`, is never handed to an Engine, and is not deleted
- [x] `VariantTests` asserts the three frozen ids explicitly and that no Variant carries a value
- [x] `MatchTests` covers a Match with no stored number resolving `nil`, and the `scorable` gate skipping it
- [x] No Engine is ever reached by a Match without a number — asserted at the gate, not by giving an Engine a substitute
- [x] Full suite green

## Comments

**2026-08-24** — Landed. Full suite green at 326 tests, with **no snapshot re-recorded** — which is the evidence for "nothing a player can see". The Release build is green too, per the rule persistence 06 established: `#Preview` bodies compile in every configuration, so Release is part of what green means on this branch.

Four things worth a reader's attention:

**The number became a required argument, and the compiler found the callers.** `Match.init(game:variant:number:…)` took `number: Int? = nil` and fell back to the Variant's constant. With the constants `nil`, leaving it optional would have made every fixture that omitted it silently unscorable — an Engine returning empty Standings, a card missing from Home, and nothing raised anywhere. It is now `number: Int`, so the ~80 fixtures and previews that had been quietly inheriting a constant each had to say what their table played at. Every one was given the value it was already inheriting (Gonga 101, Okey 21, Okey 101 8), which is why no snapshot moved.

**`Variant`'s three number fields are `let … = nil` rather than parameters passed `nil` at each constant.** They stay declared because "no Variant carries a number" is a contract, and a contract nothing states is one nothing can assert — `VariantTests.test_noVariantCarriesANumberToBePlayedAt` loops over every shipped Variant, so a fourth cannot arrive carrying one. Giving them a `nil` default instead of accepting them in the memberwise init makes that unbreakable rather than merely currently-true, and drops nine lines of `nil` from the constants. `roundCount` also stopped being `var`: the overlay in `Match.variant` that wrote the Setup-chosen count onto the resolved Variant is gone, so nothing mutates a Variant any more.

**One bug, caught by the suite, in a test fixture.** `Match.withEntrantsAndRoundsStoredOutOfOrder()` copied `roundCount` but not `limit` or `startingScore` — harmless while the constants supplied what was missing, and an unscorable Match the moment they didn't. Five tests went red on it. The copy now carries all three, which is what "differs from the original in storage order and in nothing else" always meant.

**`FixedRoundsEngine` joined the other two.** It was the last Engine reading its number off the Variant — `?? .max`, a Match that could never end — and now reads `match.variantNumber` and says nothing at all about a Match with none, the same shape as `SurvivalEngine`'s ex-`?? .max` and `EliminationEngine`'s ex-`?? 0`. What keeps a player from meeting that blank screen is the `scorable` gate, asserted in `MatchTests.test_noWinConditionsMatchesReachAnEngineWithoutANumber` — at the gate, rather than by handing an Engine a substitute to be scored against.

Left alone deliberately: `Match.init(game:variantId:limit:startingScore:roundCount:)` still accepts a Match with no number at all. That is the initialiser SwiftData loads through, and refusing a number there would mean refusing to *load* a bad row rather than skipping it — the opposite of what ADR 0007 asks for.

Note for ticket 07: `CONTEXT.md`'s **Variant** entry is now false in one more way than 07 records — a Variant no longer carries a limit or starting score *at all*, rather than merely not determining them.

**2026-08-24 (review)** — `/code-review high` run over the branch plus this ticket's working tree. Suite re-verified at 326 tests, 0 failures. One finding taken, one argued down, the rest belong to other tickets.

**Taken: Play's gate was weaker than the Engines' precondition.** `PlayView.body` guarded on `match.variant` alone. A Match with a resolvable Variant and no number would have got empty Standings from every Engine — `isOver == false` — so Play would have drawn an empty card *with a live "Add round 1 scores" button*, letting a player append Rounds to a Match that can never end. Unreachable today (both routes in guarantee a number), but that line calls itself the last word on a Match Play cannot score, so it now asks both questions.

**Not taken: delete `Variant.limit` / `startingScore` / `roundCount` outright.** The reviewer is right that `let … = nil` keeps `variant.limit` compiling and answering `nil`, and that `VariantTests.test_noVariantCarriesANumberToBePlayedAt` cannot fail while the declarations carry that default — the test documents rather than defends. Kept anyway, because this ticket and the spec both say the fields *become `nil`* rather than that they go, and because the fields are what the accessor's `switch` is written against. Deleting them is a real cleanup with a real argument behind it and it should be its own ticket, not a silent widening of this one.

**Belongs to ticket 07, and now known to be worse than 07 records:** `CONTEXT.md`'s Variant/Gösterge/Win Condition/Room left entries, and ADR 0007 — whose decision statement still says a Match stores "the id plus the Round count where the Variant has one", and whose frozen-id bullet still records the `okey-standard` → `okey-21` rename that ticket 04 reverted. A reader consulting the ADR for the frozen-id contract currently gets three wrong ids.

**Belongs to tickets 03/04, still open on the branch:** `HomeView`'s `GameGlyphCard` subtitles read "101 / 151" and "21 / 101" — Home still advertises the four retired Variants by name, and the re-recorded Home snapshots have pinned that copy as correct. Player-visible, and the only thing on this branch that still names Okey 21. Also `Navigator`'s type doc still routes Gonga through the Picker.

**Housekeeping:** `.scratch/match-scoring/issues/09-gonga-151-variant.md` is still open and instructs an agent to add `Variant.gonga151` with `limit: 151`. It should be closed `wontfix` pointing at ticket 03, or it will be re-added.
