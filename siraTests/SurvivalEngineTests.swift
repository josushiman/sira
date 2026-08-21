import XCTest
@testable import sira

final class SurvivalEngineTests: XCTestCase {
    private let variant = Variant.gonga101

    private func makeMatch(entrants: [Entrant], rounds: [Round]) -> Match {
        Match(game: .gonga, variant: variant, mode: .players, entrants: entrants, rounds: rounds)
    }

    func test_accumulatesDeltasAcrossRounds() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 20, b.id: 5]),
                Round(deltas: [a.id: 10, b.id: 15]),
            ]
        )

        let standings = SurvivalEngine().standings(for: match)

        let aliceTotal = standings.ranked.first { $0.entrantID == a.id }!.total
        let bobTotal = standings.ranked.first { $0.entrantID == b.id }!.total
        XCTAssertEqual(aliceTotal, 30)
        XCTAssertEqual(bobTotal, 20)
        XCTAssertFalse(standings.isOver)
    }

    /// Gonga 151 is the same Survival engine with a higher limit — a total
    /// that busts under 101 must still be in under 151.
    func test_gonga151UsesItsOwnHigherLimit() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .gonga,
            variant: .gonga151,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 120, b.id: 10])]
        )

        let standings = SurvivalEngine().standings(for: match)

        XCTAssertFalse(standings.ranked.first { $0.entrantID == a.id }!.isOut)
        XCTAssertFalse(standings.isOver)
    }

    func test_gonga151EntrantCrossing151GoesOut() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .gonga,
            variant: .gonga151,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 160, b.id: 10])]
        )

        let standings = SurvivalEngine().standings(for: match)

        XCTAssertTrue(standings.ranked.first { $0.entrantID == a.id }!.isOut)
        XCTAssertTrue(standings.isOver)
    }

    func test_entrantCrossingLimitGoesOut() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [
                Round(deltas: [a.id: 105, b.id: 20, c.id: 10]),
            ]
        )

        let standings = SurvivalEngine().standings(for: match)

        let alice = standings.ranked.first { $0.entrantID == a.id }!
        let bob = standings.ranked.first { $0.entrantID == b.id }!
        XCTAssertTrue(alice.isOut)
        XCTAssertEqual(alice.total, 105)
        XCTAssertFalse(bob.isOut)
        XCTAssertFalse(standings.isOver)
    }

    func test_matchEndsWithCorrectWinnerWhenOneEntrantRemains() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [
                Round(deltas: [a.id: 50, b.id: 40, c.id: 30]),
                Round(deltas: [a.id: 60, b.id: 65, c.id: 20]),
            ]
        )

        let standings = SurvivalEngine().standings(for: match)

        XCTAssertTrue(standings.isOver)
        XCTAssertEqual(standings.result, "Cara wins!")

        let cara = standings.ranked.first { $0.entrantID == c.id }!
        XCTAssertFalse(cara.isOut)
        XCTAssertEqual(cara.total, 50)
    }

    func test_outEntrantIgnoresFurtherDeltas() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 10, c.id: 10]),
                Round(deltas: [a.id: 5, b.id: 20, c.id: 30]),
            ]
        )

        let standings = SurvivalEngine().standings(for: match)

        let alice = standings.ranked.first { $0.entrantID == a.id }!
        XCTAssertEqual(alice.total, 110)
        XCTAssertTrue(alice.isOut)
    }

    func test_rankingOrdersNotOutAscendingByTotalThenOutEntrantsLast() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [
                Round(deltas: [a.id: 120, b.id: 40, c.id: 10]),
            ]
        )

        let standings = SurvivalEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.map(\.name), ["Cara", "Bob", "Alice"])
    }

    func test_simultaneousBustEndsMatchWithLowestTotalAsWinner() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 120]),
            ]
        )

        let standings = SurvivalEngine().standings(for: match)

        XCTAssertTrue(standings.isOver)
        XCTAssertEqual(standings.result, "Alice wins!")
        XCTAssertTrue(standings.ranked.allSatisfy(\.isOut))
    }

    // MARK: - Rejoin

    func test_acceptingRejoinResetsTotalToHighestAmongEntrantsStillInAndClearsOut() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 20, c.id: 40]),
                Round(id: UUID(), deltas: [a.id: 110, b.id: 20, c.id: 40], rejoins: [RejoinEvent(id: a.id, to: 40)]),
            ]
        )

        let standings = SurvivalEngine().standings(for: match)

        let alice = standings.ranked.first { $0.entrantID == a.id }!
        XCTAssertFalse(alice.isOut)
        XCTAssertEqual(alice.total, 40)
    }

    func test_rejoinTargetFallsBackToTheVariantsLimitWhenEveryoneIsOut() {
        // Being Out means a total above the limit, so falling back to the highest
        // total among all Entrants would itself be above the limit; the fallback
        // must clamp to the limit instead of resuming someone already-busted.
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 130]),
            ]
        )

        let target = SurvivalEngine().rejoinTarget(for: match)

        XCTAssertEqual(target, variant.limit ?? .max)
    }

    func test_decliningRejoinLeavesEntrantOutForRestOfMatch() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 20]),
                Round(deltas: [a.id: 0, b.id: 30]),
            ]
        )

        let standings = SurvivalEngine().standings(for: match)

        let alice = standings.ranked.first { $0.entrantID == a.id }!
        XCTAssertTrue(alice.isOut)
        XCTAssertEqual(alice.total, 110)
    }

    func test_newlyOutEntrantIDsReportsOnlyEntrantsThatBustedInTheLastRound() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 20]),
                Round(deltas: [a.id: 0, b.id: 90]),
            ]
        )

        let newlyOut = SurvivalEngine().newlyOutEntrantIDs(for: match)

        XCTAssertEqual(newlyOut, [b.id])
    }

    func test_newlyOutEntrantIDsAfterRejoinAndSecondBustOffersRejoinAgain() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 20]),
                Round(deltas: [a.id: 0, b.id: 0], rejoins: [RejoinEvent(id: a.id, to: 20)]),
                Round(deltas: [a.id: 100, b.id: 10]),
            ]
        )

        let newlyOut = SurvivalEngine().newlyOutEntrantIDs(for: match)

        XCTAssertEqual(newlyOut, [a.id])
    }

    // MARK: - Okey atmak

    /// Gonga doesn't offer Çifte, so Okey atmak is the only modifier Survival
    /// ever sees — and it doubles everyone uniformly, the Okey atan's own 0
    /// included.
    func test_okeyAtmakDoublesEveryEntrantsDeltaForThatRound() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [
                Round(deltas: [a.id: 10, b.id: 5, c.id: 0], okeyAtanID: c.id),
            ]
        )

        let standings = SurvivalEngine().standings(for: match)

        let alice = standings.ranked.first { $0.entrantID == a.id }!
        let bob = standings.ranked.first { $0.entrantID == b.id }!
        let cara = standings.ranked.first { $0.entrantID == c.id }!
        XCTAssertEqual(alice.total, 20)
        XCTAssertEqual(alice.deltaFromLastRound, 20)
        XCTAssertEqual(bob.total, 10)
        XCTAssertEqual(bob.deltaFromLastRound, 10)
        XCTAssertEqual(cara.total, 0)
    }

    func test_okeyAtmakRoundThatBustsAnEntrantAppliesTheDoubledTotal() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 60, b.id: 0], okeyAtanID: b.id),
            ]
        )

        let standings = SurvivalEngine().standings(for: match)

        let alice = standings.ranked.first { $0.entrantID == a.id }!
        XCTAssertEqual(alice.total, 120)
        XCTAssertTrue(alice.isOut)
    }

    /// Out and Rejoin resolution reads the already-multiplied totals, so a
    /// doubled Round busts an Entrant and sets the Rejoin target exactly as a
    /// large ordinary Round would.
    func test_rejoinTargetAfterAnOkeyAtmakRoundIsComputedFromTheDoubledTotals() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [
                Round(deltas: [a.id: 60, b.id: 30, c.id: 0], okeyAtanID: c.id),
            ]
        )

        let engine = SurvivalEngine()

        XCTAssertEqual(engine.newlyOutEntrantIDs(for: match), [a.id])
        // Bob's doubled 60, not his raw 30.
        XCTAssertEqual(engine.rejoinTarget(for: match), 60)
    }

    // MARK: - Undo

    func test_standingsAfterAppendingThenUndoingARoundMatchStandingsBeforeAppending() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 5])]
        )

        let before = SurvivalEngine().standings(for: match)

        match.addRound(Round(deltas: [a.id: 10, b.id: 15]))
        _ = match.undoLastRound()

        let after = SurvivalEngine().standings(for: match)

        XCTAssertEqual(before, after)
    }

    func test_undoReversesAnEntrantGoingOut() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 105, b.id: 20])]
        )

        _ = match.undoLastRound()

        let standings = SurvivalEngine().standings(for: match)
        XCTAssertTrue(standings.ranked.allSatisfy { !$0.isOut })
    }

    func test_undoReversesADoubledRound() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 5])]
        )

        let before = SurvivalEngine().standings(for: match)

        match.addRound(Round(deltas: [a.id: 10, b.id: 15], okeyAtanID: b.id))
        _ = match.undoLastRound()

        let after = SurvivalEngine().standings(for: match)

        XCTAssertEqual(before, after)
    }

    func test_undoOfRoundThatTriggeredARejoinReversesTheRejoin() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 20]),
                Round(deltas: [a.id: 0, b.id: 0], rejoins: [RejoinEvent(id: a.id, to: 20)]),
            ]
        )

        _ = match.undoLastRound()

        let standings = SurvivalEngine().standings(for: match)
        let alice = standings.ranked.first { $0.entrantID == a.id }!
        XCTAssertTrue(alice.isOut)
        XCTAssertEqual(alice.total, 110)
    }

    func test_multipleRejoinsInTheSameRoundBothTakeEffect() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 120, c.id: 40]),
                Round(
                    deltas: [a.id: 0, b.id: 0, c.id: 0],
                    rejoins: [RejoinEvent(id: a.id, to: 40), RejoinEvent(id: b.id, to: 40)]
                ),
            ]
        )

        let standings = SurvivalEngine().standings(for: match)

        let alice = standings.ranked.first { $0.entrantID == a.id }!
        let bob = standings.ranked.first { $0.entrantID == b.id }!
        XCTAssertFalse(alice.isOut)
        XCTAssertEqual(alice.total, 40)
        XCTAssertFalse(bob.isOut)
        XCTAssertEqual(bob.total, 40)
    }

    /// The Rejoin offer is the one place that compares a Match to itself minus
    /// its last Round, so it depends on `undoLastRound()` taking the highest
    /// sequence rather than whatever happens to sit last in storage.
    func test_newlyOutIsReadFromSequenceOrderNotStorageOrder() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        // Alice passes 101 on the *first* Round, so by the last one she is
        // already Out and no Rejoin is owed.
        let inOrder = makeMatch(entrants: [a, b], rounds: [
            Round(deltas: [a.id: 105, b.id: 10]),
            Round(deltas: [a.id: 0, b.id: 10]),
        ])

        XCTAssertEqual(SurvivalEngine().newlyOutEntrantIDs(for: inOrder), [])
        XCTAssertEqual(SurvivalEngine().newlyOutEntrantIDs(for: inOrder.withEntrantsAndRoundsStoredOutOfOrder()), [])

        // Played the other way round she goes Out *on* the last Round, which is
        // what makes this fixture worth asserting on.
        let reversed = makeMatch(entrants: [a, b], rounds: inOrder.rounds.reversed())
        XCTAssertEqual(SurvivalEngine().newlyOutEntrantIDs(for: reversed), [a.id])
    }
}
