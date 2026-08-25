# Sıra

A score tracker for Turkish card and tile games — currently Gonga and Okey — that keeps a running, unarguable tally across rounds for a Match's Entrants.

## Language

**Game**:
An abstract ruleset family: Gonga or Okey. Games and the Variants under them are a fixed, small set — adding one means adding code, not data. The number a Variant is played at is the exception: that is data, chosen per Match.
_Avoid_: using "game" for a played session — see Match.

**Match**:
One played instance of a Game — has its own Entrants, Rounds, and running totals. What the home screen lists as "Your games."
_Avoid_: "game" (ambiguous with the Game type above), "session."

**Variant**:
A specific ruleset within a Game. Three exist: Gonga, Okey, Okey 101. Determines the shape of a Match — its Win Condition, which VariantParameter it takes, whether Çifte applies, and the Entrant mode and table size it is played at — but not the value of that number, which the Match carries.

**VariantParameter**:
The single number a Variant is played at — a Survival limit, an Elimination starting score, a Fixed Rounds Round count. The Variant says which of the three it takes; the table chooses the value at Setup and the Match carries it for good, so two Matches of the same Variant played at different numbers are still the same Variant.
_Avoid_: "Target" (wrong for Okey, where the number is where the count starts and 0 is what it ends at), "Distance" (honest for all three, but Room left is already a distance measured against exactly this number, and two "distances" one entry apart is how a vocabulary rots).

**Entrant**:
A player or a team of two, scored uniformly regardless of which. A Match is either all-player or all-team Entrants (`mode`), never mixed — and the mode is fixed by the Variant, not chosen at Setup. Okey is the only Teams Variant, and is always exactly two teams; Gonga and Okey 101 are individuals only, seating up to 8 and 4 players respectively.

A roster is not fixed at Setup: an Entrant can be added to a live Match while the table has a free Seat — see **Join** — but one can never be **removed** from a Match, at any point, for any reason. That is not a missing feature. A Round's deltas and Çifte callers name Entrants by id with no referential integrity behind them, so a removal would silently orphan every key naming the departed (`docs/adr/0006`). Somebody who stops playing is left seated, and goes **Out** in the ordinary way.
_Avoid_: player, team, side (as a generic term — use Entrant when talking about either); "leaving" or "dropping out" for anything that takes an Entrant off the roster — nothing does.

**Seat**:
Where an Entrant sits at their Match's table, stamped by the Match when it seats them — at Setup, or at whichever Round they arrived at — and never changed afterwards. A Seat decides the Entrant's dot-badge colour and the name a blank field falls back to (`Player 3`), so it has to be as stable as a score: two Entrants sharing one would share a colour, and renumbering would move colours between launches of a Match nobody had played.

The next Seat is one past the highest in use, never the count of Entrants, and unlike a **Round**'s sequence a Seat is never freed and reused: undoing the Round a **Join** sits on takes the arrival with it but leaves the Entrant seated, so the Seat stays spoken for.

Stored as `Entrant.sequence`, and stamped by `withSequence(_:)` — the older name, kept because it is a stored SwiftData property and the storage-order argument it shares with `Round.sequence` is the reason it exists at all. The stamping method keeps it too, for symmetry with `Round.withSequence(_:)`: a Match seats an Entrant and orders a Round by the same gesture, and spelling one of them differently would hide that. Seat is the word everywhere the number is *read* or offered — `EntrantName.seat`, `RosterAddition.seat`, `Match.nextSeat`, and this glossary. Where the two meet, read `sequence` as "the Seat as stored."

One more exception, and it is a rendering one: `DotBadge` takes the number as `index`, because a badge is picking a colour out of a palette and does not know it is looking at a table.
_Avoid_: "index," "position," "order" for the concept — none of them say that the number is owned by the table and never moves; "sequence" for an Entrant anywhere outside the two spellings named above.

**Round**:
One scored turn within a Match. Produces a per-Entrant delta and, for limit Variants, may trigger an Entrant going Out. Every Round knows where it sits in its Match — its **sequence** — rather than that being implied by the order it happens to be held in; cumulative totals, the delta from the last Round, Scoresheet row numbers and Undo all read that sequence. Sequences are assigned when a Round is added and never renumbered: Undo removes only the last Round, freeing the highest sequence for the next one to take again.
_Avoid_: hand, turn, game (a Round is not a Match).

**Out**:
An Entrant that has passed the Match's score limit. Permanent for the rest of the Match — declining to Rejoin means no way back in.

**Rejoin**:
The one-time offer made to an Entrant the moment they go Out: re-enter the Match at the highest score currently held by any Entrant still in. Declined via "They're out."
_Avoid_: using it for **Join** — a Rejoin returns somebody the Match already had, a Join brings in somebody it never did.

**Join**:
An Entrant added to a live Match after Setup — someone arriving two Rounds in and taking a free **Seat**. They enter on the highest total among Entrants **still in** (Entrants who are Out are excluded, since one of them typically holds the highest total on the table and inheriting it would start the newcomer past everyone actually playing), and they are scored from that Round onward: Rounds before it are not theirs, and the Scoresheet shows an em-dash there rather than a zero. The arrival is recorded against the latest Round, so **Undo** reverses a mistaken add exactly as it reverses a mistaken score.

Only a Survival Match can offer one, because only a Match played to a running total has a total to bring somebody in on — which keeps both Okey Variants out without either being named.

Distinct from **Rejoin**, and the two are easy to conflate because they land an Entrant on the same number by the same rule: a Rejoin returns an Entrant the Match already had, one who went Out and is being let back; a Join seats one the Match never had. What a Rejoin clears — an Out state — a Join has nothing to clear.
_Avoid_: "add a player" in domain prose (that is the button's label, not the concept), "re-add," "invite."

**Room left**:
How much an Entrant can still take before passing their Match's limit and going Out — the limit minus their total. Only Survival Variants have one; an Entrant already Out has none. Standings shows it per Entrant beside their bar, and the Entrants with the least of it are the Match's **Closest to out** — every one of them, plural where they tie, since a **Rejoin** and a **Join** both land an Entrant on the highest total still in and so produce ties as a matter of course.
_Avoid_: "headroom," "remaining," using it for Okey's countdown (that total *is* the distance to 0).

**Started**:
A Match that has had at least one **Round** scored on it. Permanent: **Undo** removes the Round but never the Start, so a Match whose only Round has been undone is still Started, and scoring the next one does not Start it again. Home lists Started Matches — under every filter, since the chips are views of that list — and an un-Started Match is not history yet: it is discarded at the next launch rather than kept, taking nothing with it but a Variant choice and some Entrant names. Carried as a flag on the Match rather than read off its Round count, which is exactly what the undo case turns on.
Defined against **Archived**, which hides a Started Match, and **Delete**, which removes one.
_Avoid_: "created" — every Match is created, so it no longer distinguishes anything Home acts on; "in progress", which is about whether a Match has finished rather than whether it has begun.

**Free Match**:
One of the three Matches that can be **Started** before the app has to be paid for. Consumed the moment a Match Starts — the first Round scored on it — and never returned: **Undo**, **Delete** and **Archived** all leave the count exactly where it was, because what was spent was the playing of a game and none of those unplays it. Counted by a tally stored beside the Matches, so the Start and the Round that caused it are written together. The tally goes with the app if it is deleted, and a reinstalling player gets three again — a deliberate choice, not an oversight.
Defined against **Started**, which is the event that consumes one, and against a Match, of which there may be any number: the limit is on starting them, never on keeping or reading them.
_Avoid_: "trial", which suggests a period that expires; "credit", which suggests something that can be topped up or spent back. To the player these are "free games" — Home's own word — never "free Matches".

**Archived**:
A Match hidden from the default "Active" view. Purely a visibility flag, and **orthogonal to whether a Match is live**: an Archived Match is not locked, and takes Rounds, Rejoins, renames and Joins exactly as an unarchived one does. What closes a roster to edits is the Win Condition deciding the Match (`Standings.acceptsRosterEdits`), never its filter.
_Avoid_: using "Archived" and "Deleted" for each other. Archiving hides a Match and is reversible; deleting destroys it and is not.

**Delete**:
Removing a Match and everything it owns — its Entrants and every Round — from the device for good. Offered from the Match's Home card, behind a confirmation, in both the Active and Archived filters; a Match does not have to be Archived first. There is no undo and no restorable state: a deleted Match is gone, where an Archived one is only out of sight.
_Avoid_: "remove," "hide," "archive permanently."

**Gösterge**:
An Okey-only find — Okey 101 has no Gösterge. There is one Gösterge per Round, so at most one Entrant can find it — the Round records who, or nobody — and the find deducts 1 point from the *other* team's total that Round. Not translated — kept as the Turkish term.
_Avoid_: "indicator tile."

**Win Condition**:
The mechanic by which a Match ends, determined by its Variant. Three exist:
- **Survival** (Gonga) — Entrants accumulate score; passing the limit sends you Out; last Entrant not Out wins.
- **Elimination** (Okey) — Entrants count down from a starting score; first to hit 0 ends the Match, the other team wins.
- **Fixed Rounds** (Okey 101) — Match runs a set number of Rounds; lowest total when they're up wins.
_Avoid_: "end condition," "game over logic."

**Çifte**:
An Okey-only Round modifier, called by one or more Entrants during play, that doubles part of that Round's scoring asymmetrically: if a caller wins the Round, every *other* Entrant's delta doubles; if a caller loses, only that caller's own delta doubles. An Entrant doubles if any caller's rule says they do — never more than ×2 from Çifte, however many Entrants called it. In Okey the two branches collapse to the same outcome (there is only one loser, and only their −2 is at stake), so Okey's totals don't turn on who called or on how many teams did — both teams calling in the same Round still doubles the loss once. It records the callers anyway, as Okey 101 does, because the scoresheet marks who called. Gösterge deductions are never affected. Gonga has no Çifte concept, so its Round entry screen doesn't offer it. Not translated — kept as the Turkish term.
_Avoid_: describing Çifte as doubling "everyone" — the caller is exempt when they win, and the non-callers are exempt when they lose.

**Okey atmak**:
Finishing a Round by discarding the joker. Every Entrant's delta that Round doubles, uniformly — unlike Çifte, there is no winner/loser asymmetry. Applies to every Game and every Variant. At most one Entrant per Round, and doing it is winning the Round, so the Okey atan necessarily takes the Round (a 0 in keypad Variants, the winning team in Okey). In Okey it doubles the losing team's −2 to −4 and never touches Gösterge. Surfaced in the UI as "Okey attı" in Okey and "Jokeri attı" in Gonga; the head-word stays the infinitive. Not translated — kept as the Turkish term.
_Avoid_: "joker finish," "going out on the joker," conflating it with Çifte.

Çifte and Okey atmak are independent and stack per Entrant: a losing Çifte caller in a Round someone finished on the joker takes ×4, while everyone else takes ×2.
