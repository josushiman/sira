import XCTest
@testable import sira

final class MatchTests: XCTestCase {
    func test_undoLastRoundRemovesTheMostRecentRound() {
        let a = Entrant(name: "Alice")
        let firstRound = Round(deltas: [a.id: 10])
        var match = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a],
            rounds: [
                firstRound,
                Round(deltas: [a.id: 20]),
            ]
        )

        match.undoLastRound()

        XCTAssertEqual(match.rounds, [firstRound])
    }

    func test_undoLastRoundRemovesAnyRejoinAttachedToThatRound() {
        let a = Entrant(name: "Alice")
        var match = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a],
            rounds: [
                Round(deltas: [a.id: 10], rejoins: [RejoinEvent(id: a.id, to: 40)]),
            ]
        )

        match.undoLastRound()

        XCTAssertTrue(match.rounds.isEmpty)
    }

    func test_undoLastRoundOnMatchWithNoRoundsIsANoOp() {
        var match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [Entrant(name: "Alice")])

        match.undoLastRound()

        XCTAssertTrue(match.rounds.isEmpty)
    }
}
