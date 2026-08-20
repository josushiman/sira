# 08 — Delete a Match

**What to build:** A Match created by mistake can be removed for good, and the glossary says plainly how that differs from archiving one. This lands last because deletion is only meaningful once data outlives the session, and because it is the change that makes the store's old never-removes invariant false.

**Blocked by:** 06

**Status:** ready-for-human

- [x] A context menu on the Home card offers Delete, in both the Active and Archived filters
- [x] A confirmation stands between the menu item and the deletion, and its wording makes clear the Match and its Rounds are gone for good
- [x] Deletion is immediate and permanent, taking the Match's Entrants and Rounds with it — no undo affordance, no pending-deletion state
- [x] No swipe-to-delete: Home's cards are custom surfaces rather than list rows, and adopting list semantics for one gesture would disturb layout and tap targets the redesign settled deliberately
- [x] Deleting one Match leaves every other Match's Rounds and Entrants intact
- [x] The deletion survives a relaunch — a deleted Match does not come back
- [x] A player looking at a Match that gets deleted is returned to Home; the app can never present a Match that no longer exists
- [x] Archive and Restore keep their current meaning: Archived stays a visibility flag and is not a precondition for deleting
- [x] Snapshot: the context menu and the confirmation, in both themes
- [x] `CONTEXT.md` gains a **Delete** entry defined against the existing **Archived** entry, with an _Avoid_ line against using the two terms interchangeably

## Comments

**Implemented** (`e719a3c`). Delete is a context menu item on the Home card, backed by `MatchStore.delete(_:)` — SwiftData cascades to the Match's Entrants and Rounds. Swipe stays Archive's.

Two decisions worth flagging for review:

- **The confirmation is a themed bottom sheet, not `.confirmationDialog`.** The ticket asks for the confirmation to be snapshot in both themes, and a system dialog is system chrome that answers to neither theme. The Rejoin offer is the prior art: a decision the app asks the player to make, drawn on the app's own surface (`DeleteMatchSheet`, alongside `RejoinSheet`).
- **The context menu's snapshot is of its items, not of the menu as iOS draws it.** A context menu is presented by the system and nothing renders it into an image; what the two `test_contextMenu_*` cases pin down is the wording, the ordering and Delete's destructive role.
