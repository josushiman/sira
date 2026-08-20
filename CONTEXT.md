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
A specific ruleset within a Game. Four exist: Gonga 101, Gonga 151, Okey 21, Okey 101. Determines the Win Condition, the starting score or limit, whether Çifte applies, and the Entrant mode and table size the Variant is played at.

**Entrant**:
A player or a team of two, scored uniformly regardless of which. A Match is either all-player or all-team Entrants (`mode`), never mixed — and the mode is fixed by the Variant, not chosen at Setup. Okey 21 is the only Teams Variant, and is always exactly two teams; Gonga 101/151 and Okey 101 are individuals only, seating up to 8 and 4 players respectively.
_Avoid_: player, team, side (as a generic term — use Entrant when talking about either).

**Round**:
One scored turn within a Match. Produces a per-Entrant delta and, for limit Variants, may trigger an Entrant going Out. Every Round knows where it sits in its Match — its **sequence** — rather than that being implied by the order it happens to be held in; cumulative totals, the delta from the last Round, Scoresheet row numbers and Undo all read that sequence. Sequences are assigned when a Round is added and never renumbered: Undo removes only the last Round, freeing the highest sequence for the next one to take again.
_Avoid_: hand, turn, game (a Round is not a Match).

**Out**:
An Entrant that has passed a Variant's score limit. Permanent for the rest of the Match — declining to Rejoin means no way back in.

**Rejoin**:
The one-time offer made to an Entrant the moment they go Out: re-enter the Match at the highest score currently held by any Entrant still in. Declined via "They're out."

**Archived**:
A Match hidden from the default "Active" view. Purely a visibility flag — an Archived Match is not locked, and Rounds can still be added to it.
_Avoid_: using "Archived" and "Deleted" for each other. Archiving hides a Match and is reversible; deleting destroys it and is not.

**Delete**:
Removing a Match and everything it owns — its Entrants and every Round — from the device for good. Offered from the Match's Home card, behind a confirmation, in both the Active and Archived filters; a Match does not have to be Archived first. There is no undo and no restorable state: a deleted Match is gone, where an Archived one is only out of sight.
_Avoid_: "remove," "hide," "archive permanently."

**Gösterge**:
An Okey-21-only find. There is one Gösterge per Round, so at most one Entrant can find it — the Round records who, or nobody — and the find deducts 1 point from the *other* team's total that Round. Not translated — kept as the Turkish term.
_Avoid_: "indicator tile."

**Win Condition**:
The mechanic by which a Match ends, determined by its Variant. Three exist:
- **Survival** (Gonga 101/151) — Entrants accumulate score; passing the limit sends you Out; last Entrant not Out wins.
- **Elimination** (Okey 21) — Entrants count down from a starting score; first to hit 0 ends the Match, the other team wins.
- **Fixed Rounds** (Okey 101) — Match runs a set number of Rounds; lowest total when they're up wins.
_Avoid_: "end condition," "game over logic."

**Çifte**:
An Okey-only Round modifier, called by one or more Entrants during play, that doubles part of that Round's scoring asymmetrically: if a caller wins the Round, every *other* Entrant's delta doubles; if a caller loses, only that caller's own delta doubles. An Entrant doubles if any caller's rule says they do — never more than ×2 from Çifte, however many Entrants called it. In Okey 21 the two branches collapse to the same outcome (there is only one loser, and only their −2 is at stake), so Okey 21's totals don't turn on who called or on how many teams did — both teams calling in the same Round still doubles the loss once. It records the callers anyway, as Okey 101 does, because the scoresheet marks who called. Gösterge deductions are never affected. Gonga has no Çifte concept, so its Round entry screen doesn't offer it. Not translated — kept as the Turkish term.
_Avoid_: describing Çifte as doubling "everyone" — the caller is exempt when they win, and the non-callers are exempt when they lose.

**Okey atmak**:
Finishing a Round by discarding the joker. Every Entrant's delta that Round doubles, uniformly — unlike Çifte, there is no winner/loser asymmetry. Applies to every Game and every Variant. At most one Entrant per Round, and doing it is winning the Round, so the Okey atan necessarily takes the Round (a 0 in keypad Variants, the winning team in Okey 21). In Okey 21 it doubles the losing team's −2 to −4 and never touches Gösterge. Surfaced in the UI as "Okey attı" in Okey and "Jokeri attı" in Gonga; the head-word stays the infinitive. Not translated — kept as the Turkish term.
_Avoid_: "joker finish," "going out on the joker," conflating it with Çifte.

Çifte and Okey atmak are independent and stack per Entrant: a losing Çifte caller in a Round someone finished on the joker takes ×4, while everyone else takes ×2.
