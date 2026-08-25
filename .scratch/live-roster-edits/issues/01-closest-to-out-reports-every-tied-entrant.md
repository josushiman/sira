# 01 — Closest to out reports every tied Entrant

**What to build:** On a Survival Match, the Play screen's **Closest to out** tile names every Entrant tied on the highest total among those still in, rather than silently picking one of them. A player looking at the tile during a Gonga Match where two people are level on Room left sees both names, so the tile never states something that isn't true.

This is a pre-existing gap, not one introduced by live roster edits: a **Rejoin** puts the rejoining Entrant on the highest total still in and therefore creates this exact tie today. It lands first so the tile is already correct before **Join** starts producing ties as a matter of course.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] Two Entrants tied on the highest total still in are both named by the tile.
- [x] Three or more tied Entrants are all named, and the tile's copy stays readable at that length.
- [x] A single at-risk Entrant renders exactly as it does today — no regression in the common path.
- [x] Entrants who are **Out** are still excluded from the tie, since they have no Room left.
- [x] A Match with no limit still reports nothing rather than inventing a tie.
- [x] The "Match is over" case still reports the survivor's own Room left, unchanged.
- [x] Covered at the existing `PlayStats` seam, asserting on the rendered value rather than on how the at-risk set is computed.
