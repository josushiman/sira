Status: ready-for-agent

# Persistence — Matches that survive the app closing

## Problem Statement

Every Match in Sıra is lost the moment the app stops running.

`MatchStore` holds a single in-memory array of Matches, created fresh by `ContentView` at launch. Nothing is written anywhere: there is no `Codable` conformance in the app, no SwiftData, no Core Data, no `UserDefaults`, no file access of any kind. iOS reclaims backgrounded apps without warning and without running any code, so a table that starts a Gonga 151 Match, switches to a messaging app between Rounds, and comes back an hour later can find the whole tally gone.

This defeats the app's premise. Sıra exists to keep a running, unarguable tally — and a tally that can vanish mid-Match is worse than a paper sheet, because paper does not silently reset itself.

What every launch *does* show is two fictional Matches: Alice/Bob and Alice/Carol, hard-coded with fixed 2026 dates so the snapshot suites don't drift day to day. Those are development fixtures presented to the player as their own history.

There is also no way to remove a Match. `MatchStore` only ever appends or edits, and `binding(for:)` `fatalError`s on an id it can't find — an invariant that is currently true and that persistence makes false. Archived is purely a visibility flag, so a Match created by mistake would sit in the history forever.

## Solution

Matches, their Entrants and their Rounds are stored in SwiftData, saved after every mutation, and loaded at launch. A Match survives being backgrounded and reclaimed, force-quit, crashed, restarted and restored to a new device. The player never thinks about saving.

The domain types themselves become the SwiftData models rather than being mapped onto a parallel set of persistence records, so there is one description of a Match in the codebase and not two.

A Match no longer stores a copy of its Variant. It stores the Variant's id plus the Round count chosen at Setup, and resolves the Variant from the constants shipped in the app. A rule correction — the kind this project has shipped in three consecutive commits — therefore reaches Matches that are already saved, instead of leaving them scoring by rules that no longer exist anywhere in the code.

First launch is empty. The seeded Alice/Bob fixtures move to previews and tests, where they were always meant to live.

And a Match can be deleted: a context menu on the Home card, a confirmation, and it is gone along with its Entrants and Rounds. Delete joins Archived in the glossary as the destructive counterpart to a visibility flag.

## User Stories

1. As a player, I want my Match to still be there when I reopen the app, so that a tally isn't lost because iOS reclaimed the app between Rounds.
2. As a player, I want a Match to survive being force-quit from the app switcher, so that a habitual swipe-up doesn't destroy the evening's scores.
3. As a player, I want a Match to survive the app crashing, so that a bug costs me a moment rather than the whole Match.
4. As a player, I want a Match to survive restarting my phone, so that an update installed overnight doesn't wipe an unfinished Match.
5. As a player, I want my Match history to come back when I restore my phone from a backup, so that switching devices doesn't erase my games.
6. As a player, I want a Round to be saved the instant I enter it, so that there is never a window in which recent Rounds are at risk.
7. As a player, I want to never see a save button or a saving indicator, so that scorekeeping stays as fast as writing on paper.
8. As a player, I want the Home list to show exactly the Matches I created, so that the app's history is mine and not a demo's.
9. As a first-time player, I want to open the app to an empty Home rather than to two strangers' games, so that I'm not confused about whether those are mine.
10. As a player, I want an Archived Match to still be archived after a relaunch, so that a tidied Home stays tidy.
11. As a player, I want the Rounds of a restored Match to be in the order I entered them, so that the Scoresheet reads as the history it is.
12. As a player, I want the running totals of a restored Match to be identical to what I saw before quitting, so that I can trust the number.
13. As a player, I want an Entrant who was Out before the app closed to still be Out afterwards, so that Survival Matches resume correctly.
14. As a player, I want a Rejoin I accepted before quitting to still be recorded, so that the Entrant's score isn't recomputed from the wrong base.
15. As a player, I want a Çifte call I recorded to survive a relaunch, so that the doubled Round scores the same after reopening as it did when I entered it.
16. As a player, I want an Okey atmak I recorded to survive a relaunch, so that the joker finish isn't quietly lost from the history.
17. As an Okey 21 player, I want a Gösterge find to survive a relaunch, so that the countdown resumes from the right place.
18. As an Okey 101 player, I want the 8-or-12 Round count I chose at Setup to survive a relaunch, so that the Match still ends when it should.
19. As a player, I want Undo of the last Round to work after a relaunch exactly as it does mid-session, so that reopening the app doesn't freeze a mistake in place.
20. As a player, I want to delete a Match I created by mistake, so that my history isn't permanently cluttered by a mis-tap at Setup.
21. As a player, I want deletion to ask me to confirm, so that I can't lose an evening's scores by brushing a menu item.
22. As a player, I want deleting a Match to remove it and its Rounds completely, so that "deleted" means deleted and not merely hidden.
23. As a player, I want deleting one Match to leave every other Match untouched, so that removing a mistake can never damage real history.
24. As a player, I want to delete an Archived Match too, so that tidying and removing aren't mutually exclusive.
25. As a player, I want Archive to keep meaning "hide from Active", so that the safe action and the destructive one stay clearly different.
26. As a player, I want to be returned to Home if the Match I was looking at gets deleted, so that the app never shows me a Match that no longer exists.
27. As a player, I want the app to open normally even if its stored data can't be read, so that a corrupt file doesn't leave me with an app that won't start.
28. As a player, I want unreadable data to be set aside rather than destroyed, so that there is a chance of recovering it.
29. As a player, I want to be told if a Round couldn't be saved, so that I don't keep playing against a tally that isn't being recorded.
30. As a player who installs an update that changes the rules of a Variant, I want my saved Matches to score by the corrected rules, so that the app and my history don't disagree.
31. As a player, I want my data to stay on my device, so that keeping score doesn't involve an account or a network.
32. As a developer, I want the domain types to be the stored types, so that there is one description of a Match and no mapping layer to drift out of sync with it.
33. As a developer, I want a Match to hold its Variant's id rather than a copy of the Variant, so that shipping a rule fix doesn't split the data into Matches scored by old rules and new.
34. As a developer, I want Variant ids to be frozen once shipped, so that renaming a constant can't orphan saved Matches.
35. As a developer, I want the `okey-standard` id renamed to `okey-21` before any data exists, so that the one confusing id is fixed in the only window where renaming is free.
36. As a developer, I want a Match naming an unknown Variant id to be skipped rather than deleted, so that a downgrade or a bad write is recoverable rather than terminal.
37. As a developer, I want Round order carried by an explicit sequence rather than by relationship array order, so that scoring can't change between launches.
38. As a developer, I want saving to be explicit after every mutation rather than left to autosave, so that durability doesn't depend on when the framework decides to flush.
39. As a developer, I want a single place that mutates and then saves, so that no screen can forget the save half.
40. As a developer, I want the schema versioned from the first release, so that the first migration isn't also the migration that introduces versioning.
41. As a developer, I want Entrants owned by their Match, so that deleting a Match can never damage another Match's history.
42. As a developer, I want the Engines, Scoresheet and RoundEntryState tests to keep running without a database, so that pure scoring logic stays fast to test and free of persistence setup.
43. As a developer, I want one test that writes through the store, discards it, and reads it back, so that persistence is verified end to end rather than inferred from the schema.
44. As a developer, I want `updatedAt` removed before the schema exists, so that a dead field doesn't become a migration.
45. As a developer, I want the two decisions here recorded as ADRs, so that a future reader knows why the domain types are SwiftData models and why the Variant is stored by id.

## Implementation Decisions

### Step order

Four independent pieces land first, none blocking any other. Two are free cleanups that exist only while no schema and no stored data do — the `okey-standard` → `okey-21` id rename and the removal of the dead `updatedAt` field, both of which become migrations after the first release. Two are prefactors that move this spec's riskiest semantics out of the conversion and land them while the domain is still made of value types: the Variant resolved from a stored id, and Round order carried by an explicit sequence. The ADRs are written alongside them, before the code, while the reasoning is current.

The conversion to SwiftData models then follows as one atomic step, on an in-memory container so that it changes no observable behaviour. Durability on disk comes next, then recovery from unreadable data, then deletion.

The conversion cannot be sliced further. A type cannot be a value type and a model class at once, so no batch-by-batch migration stays green, and duplicating the domain under a temporary name across roughly 25 files would be more churn than the risk it hedges. Prefactoring is the lever that shrinks it instead: by the time it lands, Variant resolution and Round ordering are already proven by the existing tests, so the conversion is a type change and nothing else.

### The domain types become the models

`Match`, `Round` and `Entrant` become `@Model` classes. There is no parallel set of persistence records and no mapping layer: the alternative was considered and rejected because it means maintaining two descriptions of a domain that has changed in three consecutive commits, which is where drift bugs breed.

The cost is accepted deliberately: these types stop being value types. `Match.undoLastRound()` becomes a removal from the relationship plus a delete of the Round object rather than a `removeLast()` on an array of structs, and `MatchStore.binding(for:)` disappears — a reference type needs no `Binding` to be mutated in place, and its `fatalError` was safe only while nothing could be removed. The risk this introduces is small in this codebase specifically: Rounds are append-only, the only removal is the last Round, and the Engines remain pure functions that read a Match's properties without mutating it.

`RejoinEvent` stays a `Codable` value type stored inline on its Round. `Round.deltas`, `Round.cifteCallers`, `Round.losingEntrantID`, `Round.okeyAtanID` and `Round.gostergeFinderID` likewise stay as attributes. Nothing queries into them — per ADR 0005 the Engines read a whole Round and derive from it — so making them relationships would buy query power that is never used and cost a join and a lifecycle to manage. The known consequence, to be recorded in the ADR: a UUID-keyed dictionary gets no referential integrity from SwiftData, so a removed Entrant would orphan keys. Entrants cannot be removed from a Match, and this spec keeps that true.

`Entrant` is a relationship owned by its Match and cascade-deleted with it. Entrants are **not** shared across Matches: two Matches with a player called Alice hold two separate Entrants, exactly as today. Introducing a cross-Match identity is a product decision about who "the same Alice" is, and it is out of scope — see Further Notes for what would make it cheap later.

### Round order

Round order is load-bearing across the whole app: cumulative totals, the delta from the last Round, Scoresheet row numbering, and Undo all depend on it. SwiftData's to-many relationship arrays are not a dependable ordering guarantee, so order is carried by an explicit integer sequence on `Round`, assigned at append and used to sort on read. Because the only removal permitted is the last Round, the sequence never needs renumbering — Undo frees the highest number and the next append takes it again.

A timestamp on the Round was rejected: it ties correctness to clock resolution and gains nothing over an integer.

### Variant is stored by id and re-resolved

A Match stores its Variant's id and, where the Variant has one, the Round count chosen at Setup. `Match.variant` becomes a computed property resolving that id against the Variant constants shipped in the binary and applying the stored Round count.

This is what makes rule corrections reach saved Matches. Under the alternative — encoding the whole Variant — each of this project's recent rule fixes would have split the data in two, with older Matches scoring by rules that exist nowhere in the code and no way for a player to tell.

The cost is that the id becomes a persistence contract. Two consequences follow:

- **`okey-standard` is renamed to `okey-21` before any data exists**, resolving the existing mismatch between that Variant's id and its label. After that, ids are frozen: renaming one would orphan every Match that names it. The constraint is documented at the declaration so the next reader doesn't tidy it away.
- **A Match naming an unresolvable id is skipped, never deleted.** Its stored data is left untouched, so a downgrade or a bad write is recoverable when the app is updated again. Loading it in a degraded read-only form was rejected as inventing an "unsupported Match" concept in the domain for a case that should not occur.

### Saving

Saving is explicit after every mutation, with autosave left enabled as a backstop. A Match sees a handful of writes per minute, so there is no performance argument for batching, and relying on autosave is precisely the behaviour that looks correct in the simulator and loses a Round to a real reclaim on a real device.

`MatchStore` survives as the single place that mutates and then saves, so no screen can perform half of that pair. Reads move to `@Query`, which is the framework's job and does it better than a hand-maintained array. When a save fails — a full disk being the realistic case — the in-memory state is kept, the failure is surfaced to the player, and the app does not crash mid-Match.

### The container, and what happens when it won't open

The container is constructed explicitly rather than through the `.modelContainer(for:)` convenience, which `fatalError`s on failure — an unopenable app with no path forward is not an acceptable response to a corrupt file.

If the store cannot be opened, the unreadable store is moved aside to a timestamped name and a fresh one is opened. The app launches, and the old data still exists for recovery. Falling back to a silent in-memory container was rejected as the worst outcome available: an app that looks like it is working while saving nothing.

The schema is versioned from the first release, with a migration plan in place even while it is empty. Retrofitting a version onto a store that is already on devices is the expensive case, and this domain has changed in three consecutive commits.

### First launch, previews and tests

First launch is empty. `MatchStore.seeded()` stops being what the app shows and becomes the fixture builder for previews and view tests, keeping its fixed 2026 dates so snapshots stay stable.

### Deletion

A Match can be deleted from Home, from both the Active and Archived filters, via a context menu on the card, confirmed by a dialog. Deletion is immediate and permanent: cascade removes the Match's Entrants and Rounds.

Swipe-to-delete was rejected because Home's cards are custom surfaces rather than `List` rows, and adopting `List` semantics for one gesture would disturb layout the redesign settled deliberately — including the tap-target problems tracked in the `ui-redesign` effort. A context menu is additive and is also where Archive and Restore belong when they move off their current control.

An undo affordance for deletion was rejected: a "deleted but restorable" Match is a third durability state, and this spec deliberately persists exactly one thing — Match data.

Deletion makes `binding(for:)`'s missing-id `fatalError` unsafe, so it goes with the conversion to reference types. `Navigator` is cleared when it names a Match that has been deleted, so the app can never present a Match that no longer exists.

### What is deliberately not persisted

Navigation position is not restored: the app opens on Home, never back inside the Match that was open. In-flight Round entry is not persisted either — `RoundEntryState` is still built fresh each time the entry screen is pushed, and a half-typed Round is discarded if the app closes. Persisting a half-entered Round would require a Round draft as a first-class domain concept, with its own answers about what happens when a draft is reopened after the Match has ended. Neither is part of this spec.

### Storage stays local

No CloudKit, no account, no network. This is recorded as a one-way door in the ADR: adopting sync later would require unique constraints to be dropped and stored properties to become optional or defaulted, so the decision is worth knowing about before someone reaches for it.

### Vocabulary

`CONTEXT.md` gains one term: **Delete**, defined against the existing **Archived** entry so the difference between hiding and destroying is unmissable in the glossary. Nothing else in this spec is player-facing vocabulary — storage is implementation and does not belong in the glossary.

## Testing Decisions

A good test here asserts **what the player would observe** — a Match that comes back, Rounds in the right order, a total that matches, a deleted Match that is gone — not the shape of the schema that produced it. Tests should not assert which properties are attributes versus relationships, nor reach into the container's internals; both must stay free to change.

**`MatchStore` is the primary seam, and the only one this spec adds behaviour to.** It already exists with `MatchStoreTests` as prior art. Because the store owns its container, one test can exercise the entire feature from the top: write through a store, discard it, build a new store over the same storage, and assert what comes back. Coverage required:

- A Match written through the store is present after the store is rebuilt, with its Game, Variant, Entrant mode, Entrants and Archived flag intact.
- Rounds come back in the order they were added, for a Match with enough Rounds that an accidental reordering would be visible.
- A Round's Çifte callers, Okey atan, losing Entrant, Gösterge finder, raw deltas and Rejoins all survive the round trip.
- Standings computed after reloading equal the Standings computed before the store was discarded — the test that actually proves a player's tally is safe, across all three Win Conditions.
- Okey 101's Setup-chosen Round count survives, so a Fixed Rounds Match still ends when it should.
- Undo after a reload removes the last Round and nothing else.
- A save failure is surfaced rather than swallowed, and does not discard in-memory state.
- Deleting a Match removes it and its Rounds, and leaves every other Match's Rounds and Entrants intact.
- A store whose underlying storage cannot be opened yields a working, empty store, and the unreadable data is still present under its moved-aside name.
- A stored Match naming an unknown Variant id is skipped, and its data is still on disk afterwards.

Tests that need real storage use a temporary location per test; tests that only need a database use an in-memory configuration.

**Existing domain seams keep their tests and gain no database.** `SurvivalEngineTests`, `EliminationEngineTests`, `FixedRoundsEngineTests`, `ScoresheetTests`, `MatchSummaryTests`, `PlayStatsTests`, `RoundEntryStateTests`, `MatchFilterTests` and `MatchTests` construct their fixtures directly and must continue to do so, now building unregistered model instances rather than structs. Making pure scoring logic wait on a container would add setup and verify nothing. Any of these tests that has to change beyond fixture construction is a signal that the conversion has leaked scoring behaviour into persistence, and should be raised rather than patched.

**`VariantTests`** covers the frozen-id contract: each Variant's id is asserted explicitly, including `okey-21`, so a future rename fails the suite rather than silently orphaning data.

**Snapshot suites** (per ADR 0004) gain cases for the delete context menu and its confirmation in both themes, and for an empty Home on first launch — a state the app has never been able to show. `HomeViewSnapshotTests` is the prior art. These assert appearance only; no persistence behaviour is verified by a snapshot.

**`NavigatorTests`** covers that a Navigator naming a deleted Match is cleared.

## Out of Scope

- **Restoring navigation position.** The app opens on Home. Reopening into the Match that was on screen is a separate, smaller piece of work once Matches persist.
- **Persisting in-flight Round entry.** A half-typed Round is discarded when the app closes. This would require a Round draft as a domain concept and is deliberately not modelled here.
- **iCloud sync and multi-device.** Local-only, with the constraints that sync would later impose recorded in the ADR.
- **Cross-Match player identity.** Entrants remain owned by their Match. No Persona, no name matching, no aggregate player records.
- **Editing a saved Round.** Correction remains Undo-and-re-enter, as today.
- **Changing how Home sorts or titles Matches.** `createdAt` remains the sort key and the card title. A "last played" ordering would need `updatedAt` reinstated and a UI decision, and is its own issue.
- **New Games or Variants.** The four existing Variants are the whole surface; the only change to them is one id rename.
- **Exporting or sharing a Match.** Nothing leaves the device.
- **Bulk operations.** Deletion is one Match at a time.

## Further Notes

The `okey-standard` id has always disagreed with its label, Okey 21. It is harmless today because ids are only used to identify constants in memory. This spec is the moment it stops being harmless, and the last moment the rename is free — which is why it lands in the first ticket rather than being tidied up later.

`updatedAt` has been dead since it was introduced: set in the initialiser, never read and never mutated anywhere in the app or the tests. Home has always sorted by `createdAt`. It is removed here for the same reason as the rename — after the first release it would be a migration rather than a deletion.

On adding cross-Match player identity later: it stays cheap provided the eventual link runs from Entrant to a shared identity, is optional, nullifies rather than cascades on delete, and is never inferred automatically from names — two players called Alice may be two different people, and a silent merge has no undo. The trap worth remembering is Okey 21: its Entrants are teams of two, so the relationship is not one-to-one, and any model assuming one person per Entrant breaks on the one Variant that has teams. Choosing Match-owned Entrants now is the cheap direction; the reverse would mean splitting one identity retroactively and guessing which Matches belong to whom.

The decisions in this spec were settled with the user in a grilling session on 2026-08-20, working the design tree to an empty frontier across five rounds.
