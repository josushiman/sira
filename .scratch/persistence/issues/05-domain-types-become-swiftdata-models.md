# 05 — The domain types become SwiftData models

**What to build:** Match, Round and Entrant become SwiftData models under a versioned schema. The app is backed by a database and behaves exactly as it does today — still seeded at launch, still losing everything on quit. Durability arrives in ticket 06.

This is the one ticket in the spec that cannot be sliced smaller: a type cannot be a value type and a model class at once, so there is no batch-by-batch migration that stays green. Splitting it would mean duplicating the domain under a temporary name across roughly 25 files and renaming later — more churn than the thing it would protect against. Its "no behaviour change" claim rests on the test suite rather than on the compiler, which is why tickets 02 and 03 land the risky semantics first.

**Blocked by:** 01, 02, 03, 04

**Status:** ready-for-human

- [x] Match, Round and Entrant become model classes; a Match's Entrants are owned by it and removed with it
- [x] A Round's deltas, Çifte callers, Okey atan, losing Entrant, Gösterge finder and Rejoins stay inline on the Round rather than becoming relationships
- [x] The schema is declared as a versioned schema at v1, with a migration plan in place even though it is empty
- [x] Undoing a Round removes it and leaves no orphan behind
- [x] The store's Match binding is gone, and with it the crash on an unknown Match id; screens hold the Match directly
- [x] The store keeps ownership of mutations; Home reads through the framework's own query rather than a hand-maintained array
- [x] The app runs on an in-memory container, seeded exactly as today, so a player would notice no difference whatsoever
- [x] Engine, Scoresheet, Match summary, play-stats, Round-entry, filter and Match tests keep running with no container and no persistence setup, changing only how their fixtures are built
- [x] Any of those tests needing a change beyond fixture construction is raised rather than patched — it means scoring behaviour has leaked into persistence
- [x] Standings, Scoresheet rows, Home summaries, Out and Rejoin behaviour are unchanged for every Win Condition; full suite green with snapshots re-recorded only where nothing visual moved

## Comments

**2026-08-20** — Landed. Full suite green at 203 tests with **no snapshot re-recorded**, which is the strongest available evidence that nothing visual moved.

Two things worth a reader's attention:

**One production change beyond the type conversion.** `Scoresheet` and `SurvivalEngine.newlyOutEntrantIDs` both scored a *prefix* of a Match by copying it and mutating the copy — `removeAllRounds()` then `addRound` per row in one, `undoLastRound()` on a copy in the other. A model class cannot offer that: the copy is the same object, so both would have emptied the real Match. `MatchEngine` now takes the Rounds explicitly (`standings(for:rounds:)`, with `standings(for:)` defaulting to the whole Match), and `Match.removeAllRounds()` is gone with its only caller. No Engine test changed, so this moved no scoring behaviour — but it is the one place the conversion was not purely a type change.

**Entrant order is now unguaranteed** — filed as ticket 11 rather than fixed here. `Match.entrants` is a relationship array, which is exactly what ticket 03 gave Rounds a sequence to avoid, and nothing was done for Entrants. It is invisible while the container is in memory and never reloaded, and it cannot corrupt a tally (every score is keyed by `Entrant.ID`), but it can change dot-badge colours across a reload. It has to land no later than 06.

Everything else went as the ticket predicted. The domain test suites changed by exactly `var` → `let` on Match fixtures and nothing else; `MatchStorageOrderFixture` now copies the Rounds it rearranges rather than handing the originals to a second Match, which would have moved them out of the first.
