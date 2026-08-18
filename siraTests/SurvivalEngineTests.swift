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

    // MARK: - Undo

    func test_standingsAfterAppendingThenUndoingARoundMatchStandingsBeforeAppending() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 5])]
        )

        let before = SurvivalEngine().standings(for: match)

        match.rounds.append(Round(deltas: [a.id: 10, b.id: 15]))
        match.undoLastRound()

        let after = SurvivalEngine().standings(for: match)

        XCTAssertEqual(before, after)
    }

    func test_undoReversesAnEntrantGoingOut() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 105, b.id: 20])]
        )

        match.undoLastRound()

        let standings = SurvivalEngine().standings(for: match)
        XCTAssertTrue(standings.ranked.allSatisfy { !$0.isOut })
    }

    func test_undoOfRoundThatTriggeredARejoinReversesTheRejoin() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 20]),
                Round(deltas: [a.id: 0, b.id: 0], rejoins: [RejoinEvent(id: a.id, to: 20)]),
            ]
        )

        match.undoLastRound()

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
}
