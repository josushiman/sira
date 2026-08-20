# 03 — The domain types become SwiftData models

**What to build:** `Match`, `Round` and `Entrant` become `@Model` classes under a versioned schema, with Round order carried explicitly and the Variant resolved from a stored id. The app keeps behaving exactly as it does today — still seeded at launch, still losing everything on quit — because this ticket runs on an in-memory container. Durability arrives in ticket 04.

Splitting it this way keeps the largest diff in the spec reviewable as one thing: a type-system change with no behaviour change.

**Blocked by:** 02 — Record the two persistence ADRs

**Status:** ready-for-agent

- [ ] `Match`, `Round` and `Entrant` become `@Model` classes; `Entrant` is a relationship owned by its Match and cascade-deleted with it
- [ ] `RejoinEvent` stays a `Codable` value type stored inline; `deltas`, `cifteCallers`, `okeyAtanID`, `losingEntrantID` and `gostergeFinderID` stay as attributes, not relationships
- [ ] `Round` gains an integer sequence assigned at append, and Rounds are read back sorted by it — relationship array order is never relied on
- [ ] `Match` stores its Variant's id and the Setup-chosen Round count instead of a copy of the Variant
- [ ] `Match.variant` becomes a computed property resolving that id against `Variant.all(for:)` and applying the stored Round count; an unresolvable id yields no Variant rather than a substitute
- [ ] Setup records the id and Round count for Okey 101's 8-or-12 choice; `choosingRoundCount(_:)` either moves to the resolution path or goes away
- [ ] Schema declared as a versioned schema at v1, with a migration plan in place even though it is empty
- [ ] `undoLastRound()` removes the last Round and deletes the Round object, leaving no orphan
- [ ] `MatchStore.binding(for:)` is removed; screens hold the Match object directly. The `fatalError` on a missing id goes with it
- [ ] `MatchStore` keeps ownership of mutations and gains the container; `HomeView` reads via `@Query`
- [ ] The app runs on an in-memory container for now, seeded exactly as today, so this ticket changes no observable behaviour
- [ ] Engine, `Scoresheet`, `MatchSummary`, `PlayStats`, `RoundEntryState`, `MatchFilter` and `Match` tests build unregistered model instances and otherwise stay as they are — no container, no persistence setup
- [ ] Any of those tests needing a change beyond fixture construction is raised rather than patched: it means scoring behaviour has leaked into persistence
- [ ] Standings, Scoresheet rows and Home summaries are unchanged for every Win Condition; full suite green with snapshots re-recorded only where nothing visual moved
