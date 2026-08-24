# 07 — Record the vocabulary and the decision

**What to build:** The glossary, the decision record, and the last of the copy that still names the retired Variants, brought back in line with what the app now does. Several statements in `CONTEXT.md` are false the moment ticket 03 lands and must not be left standing; ticket 06's review found the same drift in ADR 0007 and on Home's own game cards.

`CONTEXT.md` needs a pass over the entries that name Variants:

- **Game** — "A fixed, small set (extending it means adding code, not data)" is no longer true of a Game's Variants, whose defining number now comes from data.
- **Variant** — "Four exist: Gonga 101, Gonga 151, Okey 21, Okey 101" becomes three, and a Variant no longer "determines the starting score or limit". It determines shape; the Match carries the number.
- **Gösterge** — described as "an Okey-21-only find", a Variant that no longer exists.
- **Win Condition** and **Room left** — both name Variants by their old labels.
- **Entrant**, **Çifte** and **Okey atmak** — the same drift, found in ticket 06's review: all three name "Okey 21" or "Gonga 101/151" as the Variant a rule applies to.

A new entry for **`VariantParameter`**: the single number a Variant takes, chosen at Setup and stored on the Match. Named for what it is rather than *Target* (wrong for Okey, where 21 is the origin and 0 is the target) or *Distance* (fits all three honestly and reads better, but **Room left** is already a per-Entrant distance measured against exactly this number, and two "distances" one hop apart in the same glossary is how vocabulary rots).

`CONTEXT.md` stays a glossary. No implementation detail, no ranges, no chip values — those live in the spec and the code.

One new ADR covering three linked decisions: Variants carry shape and Matches carry values; Variant ids are slots rather than descriptions (`gonga-standard` labelled "Gonga", `okey-standard` labelled "Okey"); and ADR 0007's `okey-standard` → `okey-21` rename is reverted. It supersedes 0007 **in part** — 0007's central decision, that a Match stores an id rather than a copy of its rules, survives intact and should be stated as surviving, so a future reader does not read "superseded" as "discarded".

The ADR should record what was rejected and why: deriving the display name from the number (renders the stock Okey Match as "Okey 21", resurrecting the name being retired), and showing a derived name only for non-default values (the same Match type rendering under two naming schemes depending on a value, making 21 secretly special again).

## ADR 0007 is further out of date than this ticket first recorded

Ticket 06's review read 0007 as a newcomer would and found three statements that now mislead rather than merely age:

- **The decision statement** (line 3) says a Match stores "the Variant's **id**, plus the Round count chosen at Setup where the Variant has one". A Match now always stores one of three numbers, and no Variant has one — so the sentence describes the design ticket 06 replaced.
- **The frozen-id bullet** reads "`okey-standard` was renamed to `okey-21` before any data existed". Ticket 04 reverted exactly that, and ticket 03 retired `gonga-101` and `gonga-151`. A reader consulting 0007 for the frozen-id contract — which is what that bullet is *for* — currently gets three wrong ids and an inverted history.
- The **Consequences** section closes on "Okey 21's Entrants are teams of two", one more use of the retired label.

Annotating 0007 is therefore not optional politeness: it is the only place the frozen-id contract is written down, and it is currently wrong about which ids are frozen.

## The copy that still names the retired Variants

Player-visible, left behind by tickets 03 and 04, and the only place in the app that still says "Okey 21":

- `HomeView`'s `GameGlyphCard.subtitle` reads `"101 / 151"` for Gonga and `"21 / 101"` for Okey. Tapping Okey now opens a Picker offering "Okey" and "Okey 101"; tapping Gonga skips the Picker entirely. Home advertises four Variants, two of which no longer exist and one of which was renamed for quoting a number it no longer guarantees.
- The re-recorded `HomeViewSnapshotTests` snapshots have pinned that copy as correct, so fixing it means re-recording them in the same change (ADR 0004).
- `HomeView`'s hero line hardcodes "Two games, three variants". It was wrong for one commit mid-branch before 03 fixed it and will go wrong again on the next catalogue change; `Game.allCases` and `Variant.all(for:)` can supply both numbers.
- `Navigator`'s type doc still routes every Game through the Picker — "a Game (→ Variant picker → Setup → Play)" — which is the one thing `HomeView.gameDestination(for:)` exists to contradict.
- `VariantTests`'s comment on `test_gongasPickerRuleTextQuotesNoNumber` justifies keeping Gonga's `ruleText` as "what Setup's header would read". Setup's header renders `variant.label`, and the number control renders `ruleText(at:)` off the template — so the comment misstates why the string is kept. Say what it is actually for, or say that it is unreferenced and kept for the next Gonga Variant.

## Housekeeping

`.scratch/match-scoring/issues/09-gonga-151-variant.md` is still open and instructs an agent to add `Variant.gonga151` with `limit: 151` and to list both Gongas in the Picker — work ticket 03 deliberately undid. Close it `wontfix` with a pointer to 03, per `docs/agents/triage-labels.md`, or the next agent picking up the frontier will re-add a Variant this spec removed.

## Not part of this

Deleting `Variant.limit`, `startingScore` and `roundCount` outright. Ticket 06's review argued for it — while they are declared as `let … = nil`, `variant.limit` still compiles and answers `nil`, which is the silent-substitute shape the spec set out to remove, and `VariantTests.test_noVariantCarriesANumberToBePlayedAt` documents the contract rather than defending it. It is a real cleanup with a real argument behind it, and it is a code change, not a documentation one — so it is ticket 08 rather than a line smuggled in beside a glossary pass. It needs a human's call first, because it edits a statement the spec makes.

**Blocked by:** 02, 03, 04, 05, 06.

**Status:** done

- [x] `CONTEXT.md`'s **Game**, **Variant**, **Gösterge**, **Win Condition**, **Room left**, **Entrant**, **Çifte** and **Okey atmak** entries are accurate, and no entry names a retired Variant
- [x] A **`VariantParameter`** entry exists, with its _Avoid_ line covering *Target* and *Distance*
- [x] `CONTEXT.md` contains no implementation detail — no ranges, chip values or type shapes
- [x] A new ADR records the three linked decisions and names what was rejected
- [x] The ADR states plainly which part of 0007 it supersedes and which part stands
- [x] ADR 0007 is annotated so a reader arriving there is sent forward, and its decision statement, its frozen-id bullet and its closing "Okey 21" no longer state things that are false
- [x] Home's game cards no longer advertise retired Variants, with `HomeViewSnapshotTests` re-recorded in the same change
- [x] Home's hero line derives its counts rather than hardcoding them
- [x] `Navigator`'s doc describes Gonga's route to Setup as it now runs
- [x] `VariantTests`'s comment on Gonga's Picker rule text says what that string is actually for
- [x] `.scratch/match-scoring/issues/09-gonga-151-variant.md` is closed `wontfix` pointing at ticket 03
- [x] Full suite green
