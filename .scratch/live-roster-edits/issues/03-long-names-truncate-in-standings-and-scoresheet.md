# 03 — Long names truncate in Standings and on the Scoresheet

**What to build:** An Entrant with a very long name no longer breaks the layout. In the Standings list the name truncates with a tail ellipsis on a single line, keeping the dot-badge, the progress bar and the "N left" figure in their places. On the Scoresheet the column header truncates to a fixed column width rather than letting one long name widen its column and push the rest of the sheet sideways.

This is a latent bug rather than one the roster-edit work introduces — Setup can already accept a name long enough to break both screens. It lands independently so that Rename and Add inherit correct behaviour rather than having to fix it under time pressure.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A long name in a Standings row truncates with a tail ellipsis on one line; the row's height is unchanged and the bar and "N left" figure stay put.
- [ ] The dot-badge remains visible beside a truncated name, so two names that truncate to the same characters can still be told apart.
- [ ] A long name in a Scoresheet column header truncates to the column's width; the column does not widen and no other column is displaced.
- [ ] Names wrap onto a second line nowhere — Standings row height is fixed by the block beneath the name.
- [ ] Short names are visually unchanged.
- [ ] Snapshot coverage for a long name in a Standings row and in a Scoresheet column header.
