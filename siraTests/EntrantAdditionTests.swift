import XCTest
@testable import sira

/// Someone arriving two Rounds into a Match and taking a free seat: what the
/// table is offered before they sit, where they land when they do, and what
/// the history says about the Rounds they missed.
///
/// Asserted through the seams the screen reads from — `RosterAddition` for the
/// offer, the Engine's Standings and the Scoresheet's rows for the result —
/// rather than through the sheet that starts it, so these stay true of any
/// screen that offers a seat.
final class EntrantAdditionTests: XCTestCase {
    private let limit = 101

    private func makeMatch(entrants: [Entrant], rounds: [Round] = []) -> Match {
        Match(
            game: .gonga,
            variant: .gongaStandard,
            number: limit,
            mode: .players,
            entrants: entrants,
            rounds: rounds
        )
    }

    private func offer(_ match: Match, variant: Variant = .gongaStandard) -> RosterAddition? {
        RosterAddition(
            match: match,
            variant: variant,
            standings: variant.winCondition.engine.standings(for: match)
        )
    }

    private func standing(_ entrant: Entrant, in standings: Standings) -> EntrantStanding? {
        standings.ranked.first { $0.entrantID == entrant.id }
    }

    // MARK: - The offer

    /// The number the table agrees out loud: the highest total among Entrants
    /// still in. Ali is Out on 120 and holds the highest total on the table,
    /// which is exactly the total the newcomer must not inherit — it would
    /// start them past the limit and straight back Out.
    func test_theOfferIsTheHighestTotalAmongEntrantsStillInAndExcludesTheOut() throws {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let cem = Entrant(name: "Cem")
        let match = makeMatch(
            entrants: [ali, veli, cem],
            rounds: [Round(deltas: [ali.id: 120, veli.id: 61, cem.id: 40])]
        )

        let addition = try XCTUnwrap(offer(match))

        XCTAssertTrue(try XCTUnwrap(standing(ali, in: SurvivalEngine().standings(for: match))).isOut)
        XCTAssertEqual(addition.total, 61)
        XCTAssertEqual(addition.joinPhrase, "joins on 61")
    }

    /// The offer is not a second opinion about where a newcomer lands: it is
    /// the Rejoin target itself, so the two can never come to disagree about
    /// the same table.
    func test_theOfferIsTheRejoinTargetItself() throws {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let cem = Entrant(name: "Cem")
        let match = makeMatch(
            entrants: [ali, veli, cem],
            rounds: [Round(deltas: [ali.id: 110, veli.id: 61, cem.id: 40])]
        )

        XCTAssertEqual(try XCTUnwrap(offer(match)).total, SurvivalEngine().rejoinTarget(for: match))
    }

    /// That shared target keeps its cap at the Match's limit and its
    /// everyone-busted fallback, which are branches of the one implementation
    /// the Add row inherits rather than restates. Neither is reachable through
    /// the Add row itself: nobody still in can be over the limit, and a Round
    /// that busts everybody left decides the Match, which withdraws the offer.
    func test_theSharedTargetStillCapsAtTheLimitWhenEverybodyBusts() {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let match = makeMatch(
            entrants: [ali, veli],
            rounds: [Round(deltas: [ali.id: 130, veli.id: 115])]
        )

        XCTAssertNil(offer(match))
        XCTAssertEqual(SurvivalEngine().rejoinTarget(for: match), limit)
    }

    /// Derived at render time, not cached when the screen opened: the number
    /// moves as Rounds are scored, with the list still on screen.
    func test_theOfferMovesAsRoundsAreScored() throws {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let match = makeMatch(entrants: [ali, veli], rounds: [Round(deltas: [ali.id: 20, veli.id: 5])])
        XCTAssertEqual(try XCTUnwrap(offer(match)).total, 20)

        match.addRound(Round(deltas: [ali.id: 10, veli.id: 15]))

        XCTAssertEqual(try XCTUnwrap(offer(match)).total, 30)
    }

    /// And as Entrants go Out: the leader busting drops the offer to whoever
    /// is highest of those left, rather than leaving the newcomer to inherit a
    /// total nobody is playing on any more.
    func test_theOfferMovesAsEntrantsGoOut() throws {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let cem = Entrant(name: "Cem")
        let match = makeMatch(
            entrants: [ali, veli, cem],
            rounds: [Round(deltas: [ali.id: 90, veli.id: 40, cem.id: 10])]
        )
        XCTAssertEqual(try XCTUnwrap(offer(match)).total, 90)

        match.addRound(Round(deltas: [ali.id: 20, veli.id: 0, cem.id: 0]))

        XCTAssertEqual(try XCTUnwrap(offer(match)).total, 40)
    }

    // MARK: - When there is no offer

    /// A full table has no seat to give away, so there is no row — not a row
    /// that is shown and refuses.
    func test_thereIsNoOfferAtTheVariantsMaximum() {
        let entrants = (0..<Variant.gongaStandard.maxEntrants).map { Entrant(name: "P\($0)") }
        let match = makeMatch(entrants: entrants, rounds: [Round(deltas: [entrants[0].id: 20])])

        XCTAssertNil(offer(match))
    }

    func test_thereIsAnOfferOneSeatShortOfTheVariantsMaximum() {
        let entrants = (0..<(Variant.gongaStandard.maxEntrants - 1)).map { Entrant(name: "P\($0)") }
        let match = makeMatch(entrants: entrants, rounds: [Round(deltas: [entrants[0].id: 20])])

        XCTAssertNotNil(offer(match))
    }

    /// A decided Match is not something a new arrival reopens — the
    /// Standings' own `acceptsRosterEdits`, asked rather than restated.
    func test_thereIsNoOfferOnAMatchItsWinConditionHasDecided() {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let match = makeMatch(entrants: [ali, veli], rounds: [Round(deltas: [ali.id: 120, veli.id: 5])])

        XCTAssertTrue(SurvivalEngine().standings(for: match).isOver)
        XCTAssertNil(offer(match))
    }

    /// Okey is out by both of its Variants and by neither of them being named:
    /// the standard game seats exactly two teams, so its table is never short
    /// of a seat, and Okey 101 has seats to spare but no running total a
    /// newcomer could be brought in on.
    func test_thereIsNoOfferOnAnOkeyMatch() {
        let bizimkiler = Entrant(name: "Bizimkiler")
        let onlar = Entrant(name: "Onlar")
        let okey = Match(
            game: .okey,
            variant: .okeyStandard,
            number: 21,
            mode: .teams,
            entrants: [bizimkiler, onlar],
            rounds: [Round(losingEntrantID: onlar.id)]
        )

        XCTAssertNil(offer(okey, variant: .okeyStandard))
    }

    func test_thereIsNoOfferOnAnOkey101MatchEvenWithSeatsToSpare() {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let okey101 = Match(
            game: .okey,
            variant: .okey101,
            number: 8,
            mode: .players,
            entrants: [ali, veli],
            rounds: [Round(deltas: [ali.id: 20, veli.id: 0])]
        )

        XCTAssertLessThan(okey101.entrants.count, Variant.okey101.maxEntrants)
        XCTAssertNil(offer(okey101, variant: .okey101))
    }

    // MARK: - Adding

    /// The one that matters: they are scored from the Round they arrived at,
    /// on the total the row previewed.
    func test_anAddedEntrantEntersOnTheOfferedTotalAndIsScoredFromThereOn() throws {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let match = makeMatch(
            entrants: [ali, veli],
            rounds: [
                Round(deltas: [ali.id: 40, veli.id: 30]),
                Round(deltas: [ali.id: 21, veli.id: 15]),
            ]
        )
        let store = MatchStore()
        store.add(match)
        let addition = try XCTUnwrap(offer(match))
        let cem = Entrant(name: "Cem")

        store.addEntrant(cem, to: match, joiningOn: addition.total)

        XCTAssertEqual(addition.total, 61)
        XCTAssertEqual(try XCTUnwrap(standing(cem, in: SurvivalEngine().standings(for: match))).total, 61)

        store.addRound(Round(deltas: [ali.id: 10, veli.id: 0, cem.id: 12]), to: match)

        XCTAssertEqual(try XCTUnwrap(standing(cem, in: SurvivalEngine().standings(for: match))).total, 73)
    }

    /// The joiner takes the next free seat — which is what their dot-badge
    /// colour is picked from — and nobody already at the table moves.
    func test_theJoinerTakesTheNextFreeSeatAndNoExistingSeatMoves() throws {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let match = makeMatch(entrants: [ali, veli], rounds: [Round(deltas: [ali.id: 20, veli.id: 5])])
        let store = MatchStore()
        store.add(match)
        let cem = Entrant(name: "Cem")

        store.addEntrant(cem, to: match, joiningOn: try XCTUnwrap(offer(match)).total)

        XCTAssertEqual(match.entrants.map(\.sequence), [0, 1, 2])
        XCTAssertEqual(match.entrants.map(\.name), ["Ali", "Veli", "Cem"])
        XCTAssertEqual(ali.sequence, 0)
        XCTAssertEqual(veli.sequence, 1)
        XCTAssertEqual(cem.sequence, 2)
    }

    /// Adding before anything has been scored is the same rule, not a second
    /// one: with no Rounds played, the highest total still in *is* zero, so
    /// the newcomer is seated on zero and there is no arrival to record.
    func test_addingBeforeAnyRoundHasBeenScoredSeatsThemDirectlyOnZero() throws {
        let ali = Entrant(name: "Ali")
        let match = makeMatch(entrants: [ali, Entrant(name: "Veli")])
        let store = MatchStore()
        store.add(match)
        let addition = try XCTUnwrap(offer(match))
        let cem = Entrant(name: "Cem")

        store.addEntrant(cem, to: match, joiningOn: addition.total)

        XCTAssertEqual(addition.total, 0)
        XCTAssertTrue(match.rounds.isEmpty)
        XCTAssertEqual(try XCTUnwrap(standing(cem, in: SurvivalEngine().standings(for: match))).total, 0)
    }

    /// A join sits on the latest Round, so Undo reverses a mistaken add
    /// exactly as it reverses a mistaken score. The Entrant stays seated —
    /// Entrants are never removed from a Match — and is simply nobody the
    /// Standings have anything to say about.
    func test_undoingTheRoundAJoinSitsOnRemovesTheJoinAndLeavesAnUnrankedSeat() throws {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let match = makeMatch(entrants: [ali, veli], rounds: [Round(deltas: [ali.id: 40, veli.id: 30])])
        let store = MatchStore()
        store.add(match)
        let cem = Entrant(name: "Cem")
        store.addEntrant(cem, to: match, joiningOn: try XCTUnwrap(offer(match)).total)
        XCTAssertNotNil(standing(cem, in: SurvivalEngine().standings(for: match)))

        store.undoLastRound(in: match)

        XCTAssertEqual(match.entrants.map(\.name), ["Ali", "Veli", "Cem"])
        XCTAssertNil(standing(cem, in: SurvivalEngine().standings(for: match)))
        XCTAssertEqual(SurvivalEngine().standings(for: match).ranked.count, 2)
    }

    /// And the seat they left behind is not handed to the next arrival: seats
    /// are never renumbered, and two Entrants sharing one would share a
    /// dot-badge colour.
    func test_anUndoneJoinDoesNotFreeTheSeatItTook() throws {
        let ali = Entrant(name: "Ali")
        let match = makeMatch(entrants: [ali, Entrant(name: "Veli")], rounds: [Round(deltas: [ali.id: 40])])
        let store = MatchStore()
        store.add(match)
        store.addEntrant(Entrant(name: "Cem"), to: match, joiningOn: 40)

        store.undoLastRound(in: match)

        XCTAssertEqual(match.nextSeat, 3)
    }

    /// A Round saying someone arrived and an Entrant saying they were seated
    /// at Setup is a Match that contradicts itself, and the contradiction is
    /// the one that scores an Entrant for Rounds they were not at the table
    /// for. Building a Match reconciles the two, whichever initializer is used
    /// and whatever order the stored parts happen to arrive in — so a caller
    /// reconstituting a Match from storage cannot lose an arrival by not
    /// having thought about it.
    func test_buildingAMatchStampsAnyEntrantSomeRoundSaysArrived() {
        let ali = Entrant(name: "Ali")
        let cem = Entrant(name: "Cem")
        let match = makeMatch(
            entrants: [ali, cem],
            rounds: [Round(deltas: [ali.id: 40], joins: [JoinEvent(id: cem.id, to: 40)])]
        )

        XCTAssertTrue(cem.arrivedMidMatch)
        XCTAssertFalse(ali.arrivedMidMatch)
        XCTAssertTrue(match.withEntrantsAndRoundsStoredOutOfOrder().entrants
            .first { $0.name == "Cem" }?.arrivedMidMatch ?? false)
    }

    // MARK: - The Scoresheet

    /// The Rounds before they arrived carry **no entry** for them, which is
    /// what lets the sheet draw an em-dash there rather than a zero they never
    /// scored. The Round they joined at carries the total they entered on,
    /// which is how a Rejoin already reads.
    func test_theScoresheetHasNoEntryBeforeAJoinAndTheEnteringTotalAtIt() throws {
        let ali = Entrant(name: "Ali")
        let veli = Entrant(name: "Veli")
        let match = makeMatch(
            entrants: [ali, veli],
            rounds: [
                Round(deltas: [ali.id: 40, veli.id: 30]),
                Round(deltas: [ali.id: 21, veli.id: 15]),
                Round(deltas: [ali.id: 0, veli.id: 16]),
            ]
        )
        let store = MatchStore()
        store.add(match)
        let cem = Entrant(name: "Cem")
        store.addEntrant(cem, to: match, joiningOn: try XCTUnwrap(offer(match)).total)
        store.addRound(Round(deltas: [ali.id: 5, veli.id: 5, cem.id: 12]), to: match)

        let rows = Scoresheet(match: match, engine: SurvivalEngine()).rows

        // The two Rounds Cem was not at the table for hold nothing of his —
        // not a zero, which is a score he would have had to be there to take.
        XCTAssertNil(rows[0].deltas[cem.id])
        XCTAssertNil(rows[1].deltas[cem.id])
        // Ali took a real zero in Round 3, which is the distinction the sheet
        // has to draw: his cell is present and zero, Cem's are absent.
        XCTAssertEqual(rows[2].deltas[ali.id], 0)
        XCTAssertEqual(rows[2].deltas[cem.id], 61)
        XCTAssertEqual(rows[3].deltas[cem.id], 12)
    }

    // MARK: - The name

    /// The Add path is handed to the same validator Rename uses, so the two
    /// cannot drift: a name another Entrant already holds is refused, folded
    /// under the pinned Turkish locale, and the Entrant being added is nobody's
    /// incumbent so nothing is exempt.
    func test_anAddedNameIsJudgedByTheSameValidatorAsARename() throws {
        let match = makeMatch(
            entrants: [Entrant(name: "ALİ"), Entrant(name: "Veli")],
            rounds: [Round(deltas: [:])]
        )
        let addition = try XCTUnwrap(offer(match))

        let clash = EntrantName("ali", seat: addition.seat, mode: .players).resolved(against: match.entrants)
        let fresh = EntrantName(" Cem ", seat: addition.seat, mode: .players).resolved(against: match.entrants)

        XCTAssertEqual(clash, .duplicate("ALİ"))
        XCTAssertEqual(fresh, .accepted("Cem"))
    }

    /// A blank field materialises the free seat's own fallback, numbered from
    /// the seat rather than from a position in a list — so the third seat is
    /// `Player 3` however many people are currently ranked.
    func test_aBlankNameMaterialisesTheFreeSeatsFallback() throws {
        let ali = Entrant(name: "Ali")
        let match = makeMatch(entrants: [ali, Entrant(name: "Veli")], rounds: [Round(deltas: [ali.id: 20])])
        let addition = try XCTUnwrap(offer(match))

        let blank = EntrantName("", seat: addition.seat, mode: .players).resolved(against: match.entrants)

        XCTAssertEqual(addition.seat, 2)
        XCTAssertEqual(blank, .accepted("Player 3"))
    }
}
