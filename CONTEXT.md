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
A specific ruleset within a Game. Four exist: Gonga 101, Gonga 151, Okey (standard), Okey 101. Determines the Win Condition, the starting score or limit, whether Çifte applies, and the Entrant mode and table size the Variant is played at.

**Entrant**:
A player or a team of two, scored uniformly regardless of which. A Match is either all-player or all-team Entrants (`mode`), never mixed — and the mode is fixed by the Variant, not chosen at Setup. Okey standard is the only Teams Variant, and is always exactly two teams; Gonga 101/151 and Okey 101 are individuals only, seating up to 8 and 4 players respectively.
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
An Okey-only per-Round toggle that doubles part of that Round's scoring. In Okey 101 (Fixed Rounds) it doubles every Entrant's delta uniformly. In Okey standard (Elimination) it doubles only the losing team's −2 loss penalty — Gösterge deductions are never affected by Çifte. Gonga has no Çifte concept, so its Round entry screen doesn't offer the toggle. Not translated — kept as the Turkish term.
