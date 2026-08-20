# 05 — Delete a Match

**What to build:** A Match created by mistake can be removed permanently, and the glossary says plainly how that differs from Archived. This lands last because deletion is only meaningful once data outlives the session, and because it is the change that makes `MatchStore`'s old never-removes invariant false.

**Blocked by:** 04 — Persist to disk, durably

**Status:** ready-for-agent

- [ ] A context menu on the Home card offers Delete, in both the Active and Archived filters
- [ ] A confirmation dialog stands between the menu item and the deletion; the copy makes clear the Match and its Rounds are gone for good
- [ ] Deletion is immediate and permanent — cascade removes the Match's Entrants and Rounds. No undo affordance, no pending-deletion state
- [ ] No swipe-to-delete: Home's cards are custom surfaces, not `List` rows, and adopting `List` semantics for one gesture would disturb settled layout and tap targets
- [ ] `Navigator` is cleared when it names a deleted Match, so the app can never present a Match that no longer exists
- [ ] Archive and Restore keep their current meaning and behaviour; Archived remains a visibility flag and is not a precondition for deleting
- [ ] Test: deleting a Match removes it and its Rounds, and leaves every other Match's Rounds and Entrants intact
- [ ] Test: the deletion survives a reload — a deleted Match does not come back
- [ ] Test: `Navigator` naming a deleted Match is cleared (`NavigatorTests`)
- [ ] Snapshot: the context menu and the confirmation dialog, in both themes (per ADR 0004)
- [ ] `CONTEXT.md` gains a **Delete** entry, defined against the existing **Archived** entry so the difference between hiding and destroying is unmissable, with an _Avoid_ line against using "delete" and "archive" interchangeably
