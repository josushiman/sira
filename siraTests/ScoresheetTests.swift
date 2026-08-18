import XCTest
@testable import sira

final class ScoresheetTests: XCTestCase {
    private let variant = Variant.gonga101
    private let engine = SurvivalEngine()

    private func makeMatch(entrants: [Entrant], rounds: [Round]) -> Match {
        Match(game: .gonga, variant: variant, mode: .players, entrants: entrants, rounds: rounds)
    }

    func test_oneRowPerSavedRoundWithEachEntrantsDeltaForThatRound() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let round1 = Round(deltas: [a.id: 20, b.id: 5])
        let round2 = Round(deltas: [a.id: 10, b.id: 15])
        let match = makeMatch(entrants: [a, b], rounds: [round1, round2])

        let scoresheet = Scoresheet(match: match, engine: engine)

        XCTAssertEqual(scoresheet.rows.count, 2)
        XCTAssertEqual(scoresheet.rows[0].id, round1.id)
        XCTAssertEqual(scoresheet.rows[0].roundNumber, 1)
        XCTAssertEqual(scoresheet.rows[0].deltas, [a.id: 20, b.id: 5])
        XCTAssertEqual(scoresheet.rows[1].id, round2.id)
        XCTAssertEqual(scoresheet.rows[1].roundNumber, 2)
        XCTAssertEqual(scoresheet.rows[1].deltas, [a.id: 10, b.id: 15])
    }

    func test_totalsRowMatchesEnginesCurrentStandings() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 20, b.id: 5]),
                Round(deltas: [a.id: 10, b.id: 15]),
            ]
        )

        let scoresheet = Scoresheet(match: match, engine: engine)

        XCTAssertEqual(scoresheet.totals, engine.standings(for: match))
    }

    func test_cifteRoundsRowReflectsTheDoubledDelta() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 10, b.id: 5], cifte: true)]
        )

        let scoresheet = Scoresheet(match: match, engine: engine)

        XCTAssertEqual(scoresheet.rows[0].deltas, [a.id: 20, b.id: 10])
    }

    func test_roundAfterAnEntrantIsOutShowsZeroDeltaForThem() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 20]),
                Round(deltas: [a.id: 5, b.id: 30]),
            ]
        )

        let scoresheet = Scoresheet(match: match, engine: engine)

        XCTAssertEqual(scoresheet.rows[1].deltas[a.id], 0)
        XCTAssertEqual(scoresheet.rows[1].deltas[b.id], 30)
    }

    func test_rejoinRoundsDeltaReflectsTheResetToTheRejoinTarget() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 110, b.id: 20]),
                Round(deltas: [a.id: 0, b.id: 0], rejoins: [RejoinEvent(id: a.id, to: 20)]),
            ]
        )

        let scoresheet = Scoresheet(match: match, engine: engine)

        // Alice's total goes from 110 (Out) to 20 (rejoined), a delta of -90.
        XCTAssertEqual(scoresheet.rows[1].deltas[a.id], -90)
    }

    func test_undoingARoundRemovesItsRowAndUpdatesTotalsImmediately() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 20, b.id: 5]),
                Round(deltas: [a.id: 10, b.id: 15]),
            ]
        )

        match.undoLastRound()

        let scoresheet = Scoresheet(match: match, engine: engine)

        XCTAssertEqual(scoresheet.rows.count, 1)
        XCTAssertEqual(scoresheet.totals, engine.standings(for: match))
        let aliceTotal = scoresheet.totals.ranked.first { $0.entrantID == a.id }!.total
        XCTAssertEqual(aliceTotal, 20)
    }
}
