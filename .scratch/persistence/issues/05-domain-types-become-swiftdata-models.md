# 05 — The domain types become SwiftData models

**What to build:** Match, Round and Entrant become SwiftData models under a versioned schema. The app is backed by a database and behaves exactly as it does today — still seeded at launch, still losing everything on quit. Durability arrives in ticket 06.

This is the one ticket in the spec that cannot be sliced smaller: a type cannot be a value type and a model class at once, so there is no batch-by-batch migration that stays green. Splitting it would mean duplicating the domain under a temporary name across roughly 25 files and renaming later — more churn than the thing it would protect against. Its "no behaviour change" claim rests on the test suite rather than on the compiler, which is why tickets 02 and 03 land the risky semantics first.

**Blocked by:** 01, 02, 03, 04

**Status:** ready-for-agent

- [ ] Match, Round and Entrant become model classes; a Match's Entrants are owned by it and removed with it
- [ ] A Round's deltas, Çifte callers, Okey atan, losing Entrant, Gösterge finder and Rejoins stay inline on the Round rather than becoming relationships
- [ ] The schema is declared as a versioned schema at v1, with a migration plan in place even though it is empty
- [ ] Undoing a Round removes it and leaves no orphan behind
- [ ] The store's Match binding is gone, and with it the crash on an unknown Match id; screens hold the Match directly
- [ ] The store keeps ownership of mutations; Home reads through the framework's own query rather than a hand-maintained array
- [ ] The app runs on an in-memory container, seeded exactly as today, so a player would notice no difference whatsoever
- [ ] Engine, Scoresheet, Match summary, play-stats, Round-entry, filter and Match tests keep running with no container and no persistence setup, changing only how their fixtures are built
- [ ] Any of those tests needing a change beyond fixture construction is raised rather than patched — it means scoring behaviour has leaked into persistence
- [ ] Standings, Scoresheet rows, Home summaries, Out and Rejoin behaviour are unchanged for every Win Condition; full suite green with snapshots re-recorded only where nothing visual moved
