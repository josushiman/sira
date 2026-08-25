Status: ready-for-agent

# Live roster edits — adding and renaming Entrants mid-Match

## Problem Statement

A Match's roster is welded shut the moment Setup ends. Entrants are seated once, their seats never change, and the only name an Entrant ever has is the one typed on the Setup screen.

Real tables do not sit still. A fifth person arrives at Gonga two Rounds in and there is a free seat at the table for them. A name gets typed wrong and stays wrong on every screen for the rest of the evening — on the Play screen, in the Standings rows, across every Scoresheet column, and in the "wins!" line at the end.

Today both situations have the same answer: abandon the Match and start it again. That throws away every Round already scored, which is the one thing the app exists to protect. The running, unarguable tally is the product; making people choose between an accurate roster and an accurate tally defeats it.

The domain already knows how to put an Entrant into a Match at a total other than zero — that is exactly what **Rejoin** does. Joining is the same shape of event as rejoining, so the mechanism exists and simply has no caller.

## Solution

Two capabilities on the Standings list of a **live** Match:

- **Rename** — tap any Entrant's Standings row to change their name.
- **Add** — a dashed row at the foot of the Standings list adds an Entrant to the Match.

A joining Entrant enters on **the highest total among Entrants still in**, the same rule a Rejoin uses. They take the next free seat, and they are scored from that Round onward exactly as everyone else is.

Add appears only where the Variant's table has a free seat. Gonga seats eight; Okey seats exactly two teams and Okey 101 exactly four, so on Okey the row never appears. This is structural rather than a product decision, so nothing in the code needs to name Gonga — the free-seat rule produces the right answer everywhere on its own.

Rename touches no scoring rule at all. It is a relabel of a stable identity: the new name appears everywhere immediately, including on Rounds played before the rename, and no record of the old name is kept.

## User Stories

1. As a Gonga player, I want to add someone who arrives mid-Match, so that they can play the rest of the evening without us throwing away the Rounds we have already scored.
2. As a Gonga player, I want a late arrival to start on the highest score still in play, so that joining late is neither an advantage nor a punishment.
3. As a Gonga player, I want to see what score a new player would join on before I commit, so that I can explain the number to the table before anyone is added.
4. As a Gonga player, I want that previewed number to be current, so that it still tells the truth after we have scored another Round with the sheet open.
5. As a Gonga player, I want a new player to take the next free seat, so that their dot-badge colour is stable for the rest of the Match.
6. As a Gonga player, I want to be stopped from adding a ninth player, so that the app never lets me build a Match the Variant cannot be played at.
7. As a Gonga player, I want the Add affordance to disappear once the table is full, so that I am not looking at a control that cannot do anything.
8. As an Okey player, I want no Add affordance at all, so that the screen does not offer me something my Variant can never support.
9. As a player of any Game, I want to rename any Entrant, so that a name typed wrong at Setup does not follow us all evening.
10. As a player of any Game, I want a rename to apply to Rounds already played, so that the Scoresheet reads as one consistent history rather than a record of what someone used to be called.
11. As a player of any Game, I want to rename an Entrant who is **Out**, so that a typo is fixable even for someone no longer accumulating score.
12. As a player of any Game, I want renaming to leave every total untouched, so that I never have to wonder whether fixing a name cost someone points.
13. As an Okey player, I want the rename copy to say "team", so that the app speaks about my Match the way I do.
14. As a Gonga player, I want the rename copy to say "player", so that the same screen reads correctly for individuals.
15. As a player of any Game, I want two Entrants to be prevented from sharing a name, so that I can always tell whose column is whose on the Scoresheet.
16. As a Turkish-speaking player, I want "ALİ" and "ali" treated as the same name, so that the duplicate check behaves the way Turkish actually works rather than the way English does.
17. As a Turkish-speaking player, I want the duplicate check to be right on an English-language phone, so that the app's behaviour does not depend on a setting that has nothing to do with the game.
18. As a player of any Game, I want leading and trailing spaces ignored when names are compared, so that "Ali " and "Ali" are not allowed to sit side by side.
19. As a player of any Game, I want to be told which name clashes and be asked to change it, so that I can resolve it without guessing what the app objected to.
20. As a player with an old Match that already contains two Alis, I want that Match to keep working untouched, so that a new rule does not retroactively break history I cannot edit.
21. As a player editing one of those two Alis, I want to be required to resolve the clash then, so that the rule is enforced from the moment I touch it.
22. As a player of any Game, I want to leave a name blank and get a sensible default, so that adding someone is fast when I do not care what they are called.
23. As a player of any Game, I want that default to be based on the seat, so that two people who both left their name blank never end up with the same one.
24. As a player of any Game, I want long names truncated rather than allowed to break the layout, so that the Standings rows and Scoresheet columns stay readable.
25. As a player of any Game, I want the dot-badge to stay visible next to a truncated name, so that I can still tell two similar names apart.
26. As a Gonga player, I want the Scoresheet to show nothing for Rounds played before someone joined, so that it is obvious they were not at the table rather than that they scored zero.
27. As a Gonga player, I want a join to render the way a Rejoin does, so that the two events look the same on the sheet because they are the same kind of thing.
28. As a Gonga player, I want Undo to reverse a join along with the Round it happened on, so that a mistaken add is as recoverable as a mistaken score.
29. As a Gonga player, I want a joiner to appear in Standings from the Round they joined, so that the running order reflects who is actually playing.
30. As a Gonga player, I want **Closest to out** to name everyone who is tied, so that the tile does not pick one person arbitrarily and state something untrue.
31. As a Gonga player, I want to add someone before the first Round is scored, so that a person who arrives during Setup does not force me to start over.
32. As a player of any Game, I want these controls only on a Match still being played, so that a finished Match's result cannot be reopened.
33. As a player of any Game, I want an Archived Match to still accept these edits, so that archiving stays a way of tidying my list rather than a way of locking a Match.
34. As a player of any Game, I want the roster edits where I already am — the Standings list — so that I do not have to go hunting through menus mid-game.
35. As a player of any Game, I want no way to delete an Entrant, so that the Rounds they scored in cannot be silently rewritten.
36. As a player whose friend leaves the table, I want them to go **Out** instead, so that the app has an honest way to record someone stopping without erasing them.
37. As a player of any Game, I want my roster edits to survive closing the app, so that the Match I come back to is the Match I left.

## Implementation Decisions

### The Engine is the primary seam

Every visible consequence of a join is derived by `SurvivalEngine.standings(for:rounds:)`. The Scoresheet, the Play screen's stat tiles and the Standings list all read from Standings, so getting the Engine right makes the rest follow with no special-casing — the same property the Scoresheet's existing comment claims for Rejoins.

### Join is a Round-attached event

A join is recorded as a `JoinEvent` carrying the Entrant's id and the total they enter on, appended to the Match's **latest** Round. This mirrors `RejoinEvent` exactly:

- It is stored inline on its Round rather than as a relationship of its own, per ADR 0006 — the Engines read a whole Round and derive from it, and nothing queries into these events.
- Undo comes for free: undoing the Round that carries the join reverses the join with it, because the Engine's replay is the only source of totals.
- `Match` gains a `recordJoin` mutator alongside `recordRejoin`, with the same contract.

The alternative — appending to `storedEntrants` and mutating a total directly — was rejected because it would put a second source of truth for totals next to the Engine's replay, and would leave Undo with nothing to reverse.

### An Entrant is invisible until they have joined

The Engine seeds totals for every Entrant in the Match up front, which means a joiner would otherwise appear in Standings from Round 1 sitting on zero — and the Scoresheet, which derives its cells by diffing Standings between prefixes, would render zeros for Rounds they were not present for.

So: **an Entrant is omitted from `Standings.ranked` entirely until the Round their `JoinEvent` sits on.** Entrants seated at Setup are present from the start; a joiner appears from their join Round onward. Two consequences follow that the implementation must handle deliberately:

- The Scoresheet's per-Round delta dictionary simply has no key for an Entrant who had not joined yet, which is what makes the em-dash possible. Absence, not zero.
- The Match-over check must count **joined** Entrants, not every Entrant in `storedEntrants`. A Match with one Entrant still in and one never-joined orphan is over.

### Undo leaves a seated orphan, and that is accepted

Undoing the Round a join sits on removes the `JoinEvent` but leaves the `Entrant` in `storedEntrants`. That Entrant then holds a seat, counts toward the Variant's maximum, and is invisible in Standings.

This is accepted deliberately. The alternative — deleting a never-scored Entrant on undo — would require weakening ADR 0006 from "Entrants cannot be removed from a Match" to "cannot be removed once they have scored." That invariant is load-bearing for `Round.deltas`, `cifteCallers` and `RejoinEvent`, all of which key on `Entrant.ID` with no referential integrity behind them; making it conditional turns every one of those key-safety arguments from a flat rule into a proof about scoring history. A held seat is a much cheaper problem than that.

### The join total reuses the Rejoin target

A joiner enters on the highest total among Entrants **still in**, computed by the existing `rejoinTarget(for:)` rather than a parallel implementation. Entrants who are Out are excluded from that maximum: an Out Entrant has passed the limit and typically holds the highest total on the table, so inheriting it would start the newcomer beyond everyone actually playing — possibly born Out. The existing cap at the Match's limit, and the existing everyone-busted fallback, both apply unchanged.

### Adding with no Rounds played

With zero Rounds there is no Round to attach a `JoinEvent` to. The Entrant is appended to the Match's Entrants directly, entering on zero. This is not a second rule: with no Rounds played, the highest total among Entrants still in *is* zero, so the two coincide. It is also indistinguishable from having typed one more name at Setup.

### Seats

A joiner is stamped with the next free seat through the same mechanism Setup uses. Seats are assigned once and never renumbered, which is what keeps dot-badge colours stable across launches. Because seats are unique and immutable, anything derived from a seat is automatically unique too.

### Name validation is a pure seam

A new pure function takes a candidate name and the Match's existing Entrants and returns whether it is acceptable, and why not if it is not. It needs no Match, no store and no view, which is what makes it cheap to test exhaustively. Both Add and Rename call it — the same validation on the same field, so the two paths cannot drift.

The rules it encodes:

- **Uniqueness is within the Match.** Entrants are not shared between Matches (ADR 0007), so there is nothing wider to be unique against.
- **Comparison is on the trimmed name, case-insensitively, using an explicit Turkish locale.** The default locale is wrong here: Turkish dotted and dotless i mean that `I`/`ı` and `İ`/`i` must fold the way a Turkish speaker expects, and the default case-folding maps `I` to `i` instead. The locale must be pinned rather than inherited from the device, so behaviour does not change with a phone's language setting.
- **A rename is excluded from clashing with itself.** Re-saving an Entrant under their own existing name is a no-op, not a duplicate.
- **Legacy duplicates are grandfathered.** Validation runs on the candidate at the point of editing, never as a sweep over stored data, so an existing Match containing two Alis stays valid and openable. Editing either one must resolve the clash.
- **Empty input is allowed** and materialises the seat-derived fallback the Setup screen already produces — a literal string baked into the name rather than a value resolved at display time. Post-Setup the number comes from the Entrant's own **seat**, not their position in a list.
- **The fallback is not exempt from uniqueness.** Nothing distinguishes a baked-in fallback name from a hand-typed identical one after creation, so a hand-typed name that collides with an existing fallback is a duplicate and is rejected. Exempting it would let two Entrants render identically in Standings, which is the exact outcome the rule exists to prevent.

### Standings: Closest to out becomes plural-capable

A joiner enters on the highest total still in and therefore instantly ties the current Closest to out. The stat tile currently selects a single at-risk Entrant by maximum total; it must instead report **all** Entrants tied at that total. Picking one by seat order would display a fact that is not true.

This is a pre-existing gap rather than one this feature introduces — a Rejoin creates the identical tie today — so it is worth fixing on its own terms.

### UI

- Both controls live on the **Standings list**, which is where the player already is during play. Rename is a tap on an Entrant's row; Add is a dashed row at the foot of the list.
- The Add row previews the total the joiner would enter on, phrased as **"joins on 61"**. The number is live and must be derived at render time, not cached when the screen opens — it moves as Rounds are scored and as Entrants go Out.
- The Add row is **hidden entirely**, never shown-and-disabled, when the table is full, when the Game is Okey, or when the Match is not live. A dashed affordance that can never activate is noise on a screen people stare at mid-game, and on Okey it would be permanently dead.
- Copy is **mode-aware**: "team" where the Match's mode is teams, "player" otherwise, derived from state that already exists. The Add affordance reads "Add player" unconditionally, which is correct precisely because Add only ever appears on player-mode Variants.
- **Long names truncate with a tail ellipsis on a single line**, in Standings and on the Scoresheet. Standings row height is fixed by the progress bar and "N left" block beneath the name, so wrapping is not available; Scoresheet headers truncate to a fixed column width rather than letting one long name widen its column. The dot-badge disambiguates names that truncate alike.

### Liveness

Both capabilities are offered only on a Match not yet decided by its Win Condition. **Archived does not affect this** — Archived is defined as purely a visibility flag and an Archived Match still accepts Rounds, so refusing a rename on a Match that will happily take another Round would be an inconsistency with nothing behind it.

### Persistence

`JoinEvent` is `Codable` and stored inline on its Round, exactly as `RejoinEvent` is, so it needs no schema relationship of its own. Entrants added mid-Match persist through the existing Entrant storage with their stamped seat. Both must survive a full store round-trip.

## Testing Decisions

A good test here asserts on **external behaviour** — the Standings a Match produces, the cells a Scoresheet renders, the string a stat tile shows, whether a validator accepts a name. It does not reach into how totals are accumulated, when the Engine iterates, or what a view's internal state holds. Every test below can be written against a value returned from a seam, which is what keeps them from breaking on refactors that change nothing a player can see.

Preference throughout is for **existing seams** over new ones. Exactly one new seam is introduced: the name validator.

**`SurvivalEngine.standings(for:rounds:)`** — the primary seam, and the one that carries most of the risk. Prior art: `SurvivalEngineTests`, which already covers Rejoin replay in the same shape.

- A joiner is absent from `ranked` for Rounds before their join Round, and present from it onward.
- A joiner's total after their join Round equals the highest total among Entrants still in at that point.
- Out Entrants are excluded from that maximum, including the case where an Out Entrant holds the highest total on the table.
- A joiner accumulates normally from their join Round, and can go Out like anyone else.
- The Match-over determination counts only joined Entrants, so a never-joined orphan does not keep a decided Match alive.
- Replaying without the Round that carries the join produces Standings with no joiner at all — the assertion that Undo works, tested at the Engine rather than through the UI.
- The everyone-busted fallback and the cap at the Match's limit still hold for a join.

**`Match` mutators** — seat stamping, the Variant maximum, and the zero-Rounds case. Prior art: `MatchTests`, alongside the existing `recordRejoin` coverage.

- A joiner is stamped with the next free seat, and existing seats do not move.
- Adding is refused at the Variant's maximum.
- With no Rounds played, the Entrant is added directly and enters on zero.
- With Rounds played, the event lands on the latest Round.

**Name validator** — the one new seam, a pure function over a candidate and the existing Entrants. Prior art for pure-validation tests: `VariantParameterTests`.

- Exact duplicates rejected; distinct names accepted.
- Case-insensitive rejection using Turkish folding, covering dotted and dotless i in both directions.
- Behaviour is identical regardless of the device's locale — the pinned-locale assertion, which is the whole point of the rule.
- Trimming: surrounding whitespace does not create a distinct name.
- Renaming an Entrant to their own current name is accepted.
- Empty input yields the seat-derived fallback.
- A hand-typed name colliding with an existing fallback is rejected.
- A Match already containing duplicates is not made invalid by their existence.

**`Scoresheet`** — that absence renders as absence. Prior art: `ScoresheetTests`.

- Rounds before a join carry no entry for the joiner, distinguishable from a zero delta.
- The join Round carries the joiner's entering total, matching how a Rejoin renders.
- Rounds after a join carry ordinary deltas.

**`PlayStats`** — the Closest to out tie. Prior art: `PlayStatsTests`.

- Two Entrants tied on the highest total still in are both reported.
- The single-Entrant case is unchanged, guarding against a regression in the common path.

**Snapshot tests** — the visual decisions that prose cannot pin down. Prior art: `RejoinSheetSnapshotTests` is near-exact, and `PlayViewSnapshotTests` covers the surrounding screen.

- The Add row with its live "joins on N" preview.
- The Add row absent: table full, Okey, and a decided Match.
- The rename sheet in both player and team copy.
- A duplicate-name error state.
- Truncation of a long name in a Standings row and in a Scoresheet column header.

**Persistence** — prior art: `MatchStorePersistenceTests`.

- A Match with a join round-trips through the store with the event and the added Entrant intact, including the Entrant's seat.

## Out of Scope

- **Removing an Entrant from a Match.** ADR 0006's invariant stands. An Entrant who leaves the table goes **Out** and declines Rejoin, which the domain already models; deleting them would silently rewrite the Rounds they scored in.
- **Adding an Entrant to Okey or Okey 101.** Not a decision, a consequence: neither Variant has a free seat. If a future Variant seats a variable number of teams, the free-seat rule already covers it with no new code.
- **Adding to a decided Match**, which would reopen a settled result. Rename remains unavailable there too, by the same liveness rule.
- **Reordering seats.** Seats are stamped once; dot-badge colour stability depends on it.
- **Entrant identity shared across Matches.** ADR 0007 records why two Matches with a player called Ali hold two separate Entrants, and nothing here changes that. Uniqueness is within a Match only.
- **A history of previous names.** Rename is a relabel, not a substitution of one person for another.
- **Deleting the orphan Entrant left by undoing a join.** Accepted above; revisiting it means revisiting ADR 0006.
- **`CONTEXT.md` and ADR updates**, which are deferred until the implementation lands and are listed below.

## Further Notes

### Documentation to follow, applied in one pass after implementation

- **`CONTEXT.md` is stale independently of this feature.** It still documents four Variants — Gonga 101, Gonga 151, Okey 21, Okey 101 — while the code has carried three since the Customisable Variants change: Gonga, Okey, Okey 101. Worth fixing in the same pass, since this spec's glossary edits touch neighbouring entries.
- **New glossary entry: Join** — an Entrant added to a live Match after Setup, entering on the highest total among Entrants still in, recorded against a Round so Undo reverses it. Distinguish from Rejoin, which returns an Entrant who was already in the Match.
- **Amendments:** *Rejoin* gains a sibling and should point at it; *Closest to out* stops being singular; *Entrant* may now be added but still never removed; *Archived* is explicitly orthogonal to liveness.
- **New ADR:** Join is a Round-attached event mirroring Rejoin rather than a direct mutation of the Match's Entrants, so that Undo and Engine replay both fall out for free. The ADR should also record the accepted orphan and why ADR 0006 was left intact.

### Risks worth watching during implementation

- The Engine's omit-until-joined change touches the code path every Gonga Match already depends on. The Match-over check and the everyone-busted tiebreak both iterate all Entrants today and both need auditing, not just the obvious loop.
- The Scoresheet builds its per-Round deltas by diffing Standings between prefixes and seeds previous totals at zero for every Entrant. That seeding needs the same omit-until-joined treatment, or a joiner's first cell will read as their entering total minus zero in a place that expects a Round delta.
- Turkish case folding is the detail most likely to be got wrong quietly, because the default folding produces plausible-looking results in English and wrong ones in Turkish. The locale must be pinned explicitly, and a test must assert that it is.
