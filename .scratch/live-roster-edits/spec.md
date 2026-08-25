Status: ready-for-agent

# Live roster edits — adding and renaming Entrants mid-Match

## Problem Statement

A Match's roster is welded shut the moment Setup ends. `Entrant.sequence` is stamped once and never changed, `Match.entrants` is never appended to, and the only name an Entrant ever has is the one typed on the Setup screen.

Real tables do not sit still. Someone arrives at Gonga two Rounds in and there is a free seat for them; a name is typed wrong and stays wrong on every screen for the rest of the evening. Today both cases force the same answer — abandon the Match and start again — which throws away the Rounds already scored, and scoring already-played Rounds is the entire point of the app.

The domain already knows how to put an Entrant into a Match at a total other than zero. **Rejoin** does exactly that: a `RejoinEvent { id, to }` recorded against a Round, replayed by `SurvivalEngine` as `totals[id] = rejoin.to`. Joining is the same shape of event as rejoining, so the mechanism exists and only lacks a caller.

## Solution

Two capabilities on the Standings screen of a **live** Match:

- **Rename** any Entrant — a tap on their Standings row.
- **Add** an Entrant — a dashed row at the foot of the Standings list, shown only where the Variant's table has a free seat.

Add is therefore Gonga-only, and structurally so rather than by a feature flag: Okey seats exactly two teams and Okey 101 exactly four, so neither ever has a free seat. Nothing in the code needs to name Gonga.

A joining Entrant enters at **the highest total among Entrants still in** — the same rule Rejoin uses, reusing `SurvivalEngine.rejoinTarget(for:)`. Entrants who are **Out** are excluded from that maximum: an Out Entrant has passed the limit and typically holds the highest total on the table, so inheriting it would start the newcomer beyond everyone actually playing, possibly born Out.

## Rules

### Liveness

Both capabilities are offered only on a **live** Match — one not yet decided by its Win Condition.

**Archived** does not affect this. `CONTEXT.md` defines Archived as purely a visibility flag, and an Archived Match still accepts Rounds; refusing a rename on a Match that will happily take another Round would be an inconsistency with nothing behind it.

### Joining

- The join is recorded as a `JoinEvent` appended to the **latest Round**, mirroring `RejoinEvent` exactly, so undoing that Round undoes the join with it and the Engine's replay stays the single source of totals.
- With **zero Rounds played** there is no Round to attach to. In that case the Entrant is appended to `Match.entrants` directly at 0 — which is indistinguishable from editing Setup, and is the same rule rather than a second one: with no Rounds, the highest total among Entrants still in *is* 0.
- The new Entrant takes the next free seat, stamped via `withSequence(_:)` as at Setup. Seats are never renumbered.
- Capped at the Variant's `maxEntrants`, the same limit Setup enforces. Mid-Match is not a backdoor around table size.
- **Removal remains impossible.** `docs/adr/0006` records that `Round.deltas` and `cifteCallers` being keyed on `Entrant.ID` with no referential integrity is safe *only* while Entrants cannot be removed; that invariant is untouched. An Entrant who leaves the table goes **Out** and declines Rejoin — the domain already has the concept, and deleting them would silently rewrite the Rounds they scored in.

### Renaming

A pure relabel of a stable Entrant identity. The new name appears everywhere immediately, including on past Rounds; no history of the old name is kept, and no scoring rule is touched. Available for Entrants who are **Out** — they still appear on Standings and the Scoresheet, so a typo in their name is just as wrong.

### Names

- **Uniqueness within a Match.** Duplicates are rejected and the user must resolve the clash. The rule applies identically to Add and Rename — the same validation on the same field.
- Comparison is on the **trimmed** name, **case-insensitively using an explicit Turkish locale** (`lowercased(with: Locale(identifier: "tr"))`). The default locale is wrong on an English phone: Turkish dotted/dotless i means `I`/`ı` and `İ`/`i` must fold the way a Turkish speaker expects, and `lowercased()` folds `I`→`i` instead.
- **Legacy duplicates are grandfathered.** A Match created before this rule keeps its two Alis; any *edit* to one of them must resolve the clash.
- **Empty input is allowed** and materialises the existing Setup fallback (`SetupView.swift:216`), which bakes a literal name into `Entrant.name` rather than resolving one at display time. Post-Setup the number comes from `sequence + 1`, the Entrant's own seat — not list position. Because seats are unique and immutable, a seat-derived fallback can never collide with another fallback.
- The fallback is **not exempt** from uniqueness: nothing distinguishes a baked-in "Player 3" from a hand-typed one after creation, so typing "Player 3" against an existing seat-3 fallback is a duplicate and is blocked. The alternative would let two Entrants render identically on Standings, which is what the uniqueness rule exists to prevent.
- **Mode-aware copy**: "team" where the Match's mode is `.teams` (Okey), "player" otherwise. Derived from state that already exists. The Add affordance reads "Add player" unconditionally, which is correct precisely because Add only ever appears on player-mode Variants.

### Display

- **Long names truncate with a tail ellipsis, on one line**, on both Standings and the Scoresheet. Standings row height is fixed by the bar and "N left" block beneath the name, so wrapping is not available; Scoresheet headers truncate to a fixed column width rather than one long name widening its column.
- The **dot-badge** disambiguates names that truncate alike — which is a further reason its colour stays tied to seat, as `Entrant.sequence` already guarantees.
- The Add row previews the total the joiner would enter on: **"joins on 61"**. The number is **live** — it moves as Rounds are entered and as Entrants go Out — so it cannot be a value cached at screen load.
- The Add row is **hidden entirely**, not disabled, when the table is full, when the Game is Okey, or when the Match is not live. A dashed affordance that never activates is noise on a screen stared at during play, and on Okey it would be permanently dead.

### Standings

**Closest to out** becomes plural-capable. A joiner enters on the highest total still in and therefore instantly *ties* the current Closest to out; `CONTEXT.md` defines it as a singular. All tied Entrants are shown, rather than one being picked by seat order — an arbitrary tie-break would display a fact that is not true. This is a pre-existing gap: a Rejoin creates the identical tie today.

### Scoresheet

An Entrant has no deltas for Rounds before they joined. Those cells render as an **em-dash**, and the join Round renders the way a Rejoin does today — a joiner and a rejoiner are the same shape of event and must not look different.

## Docs to follow

Deferred until the implementation lands, then applied together:

- **`CONTEXT.md` is stale independently of this feature** — it still documents four Variants (Gonga 101, Gonga 151, Okey 21, Okey 101), while `Variant.swift` has three since the Customisable Variants merge: Gonga, Okey, Okey 101. Fix in the same pass.
- New glossary entry: **Join**.
- Amendments: **Rejoin** (gains a sibling), **Closest to out** (plural on ties), **Entrant** (may be added, still never removed), **Archived** (explicitly orthogonal to liveness).
- New ADR: Join is a Round-attached event mirroring Rejoin, rather than a direct mutation of `Match.entrants`, so Undo and Engine replay both fall out for free.
