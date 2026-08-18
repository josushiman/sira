# Sıra

A score tracker for Turkish card and tile games — currently Gonga and Okey — that keeps a running, unarguable tally across rounds for a Match's Entrants.

## Language

**Game**:
An abstract ruleset family: Gonga or Okey. A fixed, small set (extending it means adding code, not data).
_Avoid_: using "game" for a played session — see Match.

**Match**:
One played instance of a Game — has its own Entrants, Rounds, and running totals. What the home screen lists as "Your games."
_Avoid_: "game" (ambiguous with the Game type above), "session."

**Variant**:
A specific ruleset within a Game, e.g. Gonga 101, Gonga 151, Okey (standard), Okey 101. Determines the Win Condition, starting score, and whether teams are required.

**Entrant**:
A player or a team of two, scored uniformly regardless of which. A Match is either all-player or all-team Entrants (`mode`), never mixed.
_Avoid_: player, team, side (as a generic term — use Entrant when talking about either).

**Round**:
One scored turn within a Match. Produces a per-Entrant delta and, for limit Variants, may trigger an Entrant going Out.

**Out**:
An Entrant that has passed a Variant's score limit. Permanent for the rest of the Match — declining to Rejoin means no way back in.

**Rejoin**:
The one-time offer made to an Entrant the moment they go Out: re-enter the Match at the highest score currently held by any Entrant still in. Declined via "They're out."

**Archived**:
A Match hidden from the default "Active" view. Purely a visibility flag — an Archived Match is not locked, and Rounds can still be added to it.

**Gösterge**:
An Okey-standard-only find: at most one per Entrant per Round. Each find deducts 1 point from the *other* team's total that Round. Not translated — kept as the Turkish term.
_Avoid_: "indicator tile."

**Win Condition**:
The mechanic by which a Match ends, determined by its Variant. Three exist:
- **Survival** (Gonga 101/151) — Entrants accumulate score; passing the limit sends you Out; last Entrant not Out wins.
- **Elimination** (Okey standard) — Entrants count down from a starting score; first to hit 0 ends the Match, the other team wins.
- **Fixed Rounds** (Okey 101) — Match runs a set number of Rounds; lowest total when they're up wins.
_Avoid_: "end condition," "game over logic."

**Çifte**:
A per-Round toggle that doubles part of that Round's scoring. In Survival and Fixed Rounds Variants it doubles every Entrant's delta uniformly. In Elimination (Okey standard) it doubles only the losing team's −2 loss penalty — Gösterge deductions are never affected by Çifte. Not translated — kept as the Turkish term.
