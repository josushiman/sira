# A Join is a Round-attached event, not a roster mutation

Someone arrives two Rounds into a Gonga Match and there is a free seat. The obvious implementation is the direct one: append an Entrant to `Match.entrants` on the agreed total and carry on. We decided instead that a **Join** is a `JoinEvent` recorded on the latest **Round** — the same shape a **Rejoin** already had — and that the Entrants list is only ever the roster, never the record of when somebody got there.

- **The event lives on a Round.** `Round.joins` is a list of `JoinEvent(id:to:)` beside the `rejoins` that were already there. Undo removes the last Round and takes the arrival's Round with it, for free, because Undo already removes a Round and everything on it. Nothing about Undo had to learn what a Join is.
- **The Engine replays it.** `SurvivalEngine` walks the Rounds it is given and applies each Round's joins after that Round's deltas, exactly as it applies its rejoins — a joiner arrives at an agreed total for a Round already scored rather than taking score in it. Standings for any prefix of Rounds therefore come out right without a second code path, which is what the Scoresheet needs: it scores every prefix in turn, and a joiner has to be absent from the ones that predate them.
- **The entering total is the Rejoin target, called, not copied.** `RosterAddition` asks `SurvivalEngine.rejoinTarget(for:)` for the number the Add row previews and the sheet commits, so the cap at the Match's limit and the everybody-busted fallback come along unchanged. A Join and a Rejoin land an Entrant on a total by one rule, and two spellings of one rule is one spelling too many.

## Considered Options

**Appending to `Match.entrants` and nothing else** was rejected on Undo. The arrival would have no Round to be undone with, so undoing the Round it was agreed in would leave a player nobody had agreed to, ranked from the Match's first Round on a total of zero. Making Undo aware of arrivals separately means Undo carries two kinds of knowledge instead of one.

**Deriving "arrived later" from the `JoinEvent`s alone** was tried and abandoned during ticket 05. It is right until the Round carrying the event is undone, at which point nothing distinguishes the joiner from someone seated at Setup and they come back as a player on zero — the Match inventing a player rather than showing the orphan the Undo actually left. So the fact is recorded twice, deliberately and asymmetrically: the **Entrant** records *that* they arrived (`arrivedMidMatch`, one-way, no Undo takes it back) and the **Round** records *where* (`JoinEvent`, which Undo takes with it). `Match`'s designated initializer reconciles the two additively, so no way of building a Match can lose an arrival.

## The seated orphan, accepted

Undo the Round a Join sits on and the Entrant is left seated with their arrival in no Round of the Match. The Engine omits them from Standings — every Round predates them — so they are on the roster and in no scoring. This is accepted rather than repaired.

The repair would be to remove them, and removing an Entrant is what [`0006`](0006-domain-types-are-the-swiftdata-models.md) says cannot happen: `Round.deltas`, `Round.cifteCallers` and `RejoinEvent` are all keyed by `Entrant.ID` with no referential integrity behind them, so a removal orphans every key naming the departed with nothing anywhere to raise it.

We considered weakening 0006's rule to "an Entrant cannot be removed **once they have scored**", which would let exactly this Entrant go. It was rejected. The weakened form is a conditional invariant, and a conditional invariant has to be evaluated correctly at every future call site by someone who has read the condition — where the flat form is checkable by inspection and enforced by `Entrant.match` being settable only from `Entrant.swift`. The condition would also be subtler than it reads: "has scored" is not a property of an Entrant but a question asked of every Round, every Çifte caller list and every RejoinEvent in the Match, and the wrong answer is silent. Trading a visible orphan for a silent one is a bad trade, and the orphan costs a row that isn't rendered.

## Consequences

Adding an Entrant before any Round has been scored appends them on zero with no `JoinEvent` at all — not a special case, the same rule arriving somewhere else. With no Rounds the highest total still in *is* zero, and an Entrant who has missed no Rounds is what the absence of a JoinEvent already means.

**Seats are never freed.** `Match.nextSeat` is one past the highest in use, so the orphan above keeps their seat and their dot-badge colour, and a subsequent joiner takes the next one rather than inheriting a colour that was on screen a moment ago. This is where a Seat differs from a Round's sequence, which Undo does free for reuse.

`Round.joins` and `Entrant.arrivedMidMatch` are both additive, defaulted properties absorbed into schema version 1.0.0 rather than cut as a v2 — see the note in `SiraSchema.swift`, which also records that a third such change is where that run of luck stops being a policy.

Play's subtitle still counts an orphaned joiner in its "3 players", because that phrase is shared verbatim with the Home card and reads the roster rather than the Standings. Known, and left: splitting the two so one screen can disagree with the other about how many people are at a table is the worse outcome.
