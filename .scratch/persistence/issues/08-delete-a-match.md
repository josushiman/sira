# 08 — Delete a Match

**What to build:** A Match created by mistake can be removed for good, and the glossary says plainly how that differs from archiving one. This lands last because deletion is only meaningful once data outlives the session, and because it is the change that makes the store's old never-removes invariant false.

**Blocked by:** 06

**Status:** ready-for-agent

- [ ] A context menu on the Home card offers Delete, in both the Active and Archived filters
- [ ] A confirmation stands between the menu item and the deletion, and its wording makes clear the Match and its Rounds are gone for good
- [ ] Deletion is immediate and permanent, taking the Match's Entrants and Rounds with it — no undo affordance, no pending-deletion state
- [ ] No swipe-to-delete: Home's cards are custom surfaces rather than list rows, and adopting list semantics for one gesture would disturb layout and tap targets the redesign settled deliberately
- [ ] Deleting one Match leaves every other Match's Rounds and Entrants intact
- [ ] The deletion survives a relaunch — a deleted Match does not come back
- [ ] A player looking at a Match that gets deleted is returned to Home; the app can never present a Match that no longer exists
- [ ] Archive and Restore keep their current meaning: Archived stays a visibility flag and is not a precondition for deleting
- [ ] Snapshot: the context menu and the confirmation, in both themes
- [ ] `CONTEXT.md` gains a **Delete** entry defined against the existing **Archived** entry, with an _Avoid_ line against using the two terms interchangeably
