# 06 — Home list: filter, archive, restore

**What to build:** Turn the home screen into a real multi-Match list: filterable by Active / All / Archived, with each Match archivable and restorable without losing its history.

**Blocked by:** 05 — Scoresheet tab

**Status:** ready-for-agent

- [ ] Home screen lists all Matches, not just the one most recently started
- [ ] Active / All / Archived filter chips control which Matches are shown, defaulting to Active
- [ ] Each Match row shows a summary line (leader and score, or result if over) driven off that Match's Engine — no Survival-specific logic in the list view
- [ ] Archiving a Match hides it from the Active filter but does not lock it — it remains fully open in Play, including adding new Rounds
- [ ] Restoring an archived Match returns it to the Active filter
- [ ] Archiving/restoring never discards a Match's Rounds or standings
