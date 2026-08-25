# The domain types are the SwiftData models

> **Still current; its no-removal constraint was re-examined by [0009](0009-a-join-is-a-round-attached-event.md) and left intact.** Live roster edits made Entrants addable mid-Match and produced a case — a joiner whose Round has been undone — where removing one would have been convenient. 0009 records why the flat rule below was kept rather than weakened to "cannot be removed once they have scored," and accepts a seated, unscored Entrant instead.

Matches must survive the app closing, so `Match`, `Round` and `Entrant` have to be stored. We decided these domain types *become* the persistence types — `@Model` classes, with no parallel records and no mapping layer — so there is one description of a Match in the codebase rather than two.

## Considered Options

Keeping the value types and mapping them to and from separate persistence records was rejected: it means maintaining two descriptions of a domain that changed in three consecutive commits, and a mapping layer only ever drifts towards the description nobody is testing.

## Consequences

These types stop being value types, which is accepted deliberately:

- `Match.undoLastRound()` becomes removing the Round from the relationship and deleting the object, not a `removeLast()` on an array of structs.
- `MatchStore.binding(for:)` disappears entirely, taking its missing-id `fatalError` with it — a reference type needs no `Binding` to be mutated in place, and that crash was only safe while no Match could be deleted.
- Previews and view tests need a container rather than a bare array of fixtures.
- The risk is bounded by this domain's shape: Rounds are append-only, the only removal permitted is the last Round, and the Engines stay pure functions that read a Match without mutating it.

A Round's `deltas`, `cifteCallers`, `losingEntrantID`, `okeyAtanID`, `gostergeFinderID` and `RejoinEvent`s stay inline attributes rather than becoming relationships. Per [`docs/adr/0005`](0005-round-modifiers-stored-as-facts-multiplied-in-engines.md) the Engines read a whole Round and derive from it, and nothing queries into these fields, so relationships would buy query power that is never used at the cost of a join and a lifecycle. The consequence is that a UUID-keyed dictionary gets no referential integrity from SwiftData — a removed Entrant would orphan its keys — which is safe **only** while Entrants cannot be removed from a Match. Entrants are a relationship owned by their Match and cascade-deleted with it; keeping removal impossible is a constraint this decision depends on.

Storage is local-only — no CloudKit, no account, no network — and this is a one-way door worth knowing before someone reaches for sync: adopting CloudKit later would require unique constraints to be dropped and stored properties to become optional or defaulted throughout the schema.
