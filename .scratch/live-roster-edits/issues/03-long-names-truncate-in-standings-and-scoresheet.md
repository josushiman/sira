# 03 — Long names truncate in Standings and on the Scoresheet

**What to build:** An Entrant with a very long name no longer breaks the layout. In the Standings list the name truncates with a tail ellipsis on a single line, keeping the dot-badge, the progress bar and the "N left" figure in their places. On the Scoresheet the column header truncates to a fixed column width rather than letting one long name widen its column and push the rest of the sheet sideways.

This is a latent bug rather than one the roster-edit work introduces — Setup can already accept a name long enough to break both screens. It lands independently so that Rename and Add inherit correct behaviour rather than having to fix it under time pressure.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] A long name in a Standings row truncates with a tail ellipsis on one line; the row's height is unchanged and the bar and "N left" figure stay put.
- [x] The dot-badge remains visible beside a truncated name, so two names that truncate to the same characters can still be told apart.
- [x] A long name in a Scoresheet column header truncates to the column's width; the column does not widen and no other column is displaced.
- [x] Names wrap onto a second line nowhere — Standings row height is fixed by the block beneath the name.
- [x] Short names are visually unchanged.
- [x] Snapshot coverage for a long name in a Standings row and in a Scoresheet column header.

## What was actually found

The premise did not reproduce. Both screens already truncate correctly on this
build — the Standings name has carried `lineLimit(1)` since the Play reskin, and
the Scoresheet's columns are equal shares of the row (`frame(maxWidth: .infinity)`),
so a long header truncates inside its column rather than widening it.

This was checked, not assumed. A 72-character unbroken name was rendered at 402pt
and at 320pt, as leader (Leads tag) and as busted (Out tag): the name truncated with
a tail ellipsis every time, the row height matched its neighbours, and the badge, bar
and "N left" figure held their positions. On the Scoresheet the ink of the totals row
was measured against a four-short-name control at the same Entrant count — column
right edges at 413/638/864/1090 against 412/638/864/1091, i.e. identical to within a
pixel of antialiasing. No column widened and none was displaced.

So this ticket landed as regression coverage plus two invariants made explicit
rather than incidental:

- The Out/Leads tag beside a Standings name is now `fixedSize()`. SwiftUI was
  already shrinking the name first, being the more flexible of the two, but nothing
  said so — and Rename is about to make long names easy to produce.
- Comments in both screens state what the layout guarantees, so a later change to
  either row reads as a change to the rule rather than a tidy-up.

The long-name snapshots are the real deliverable: Rename and Add inherit a
checked-in reference of what a long name is supposed to look like.

**Out of scope, noticed on the way:** the Leader stat tile wraps a long name
mid-word across its two lines and then truncates. It does not break the layout —
both tiles grow together — but it reads poorly. Worth its own ticket if it matters.
