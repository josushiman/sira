import XCTest
@testable import sira

final class FixedRoundsEngineTests: XCTestCase {
    private let variant = Variant.okey101.choosingRoundCount(8)

    private func makeMatch(entrants: [Entrant], rounds: [Round]) -> Match {
        Match(game: .okey, variant: variant, mode: .players, entrants: entrants, rounds: rounds)
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

        let standings = FixedRoundsEngine().standings(for: match)

        let aliceTotal = standings.ranked.first { $0.entrantID == a.id }!.total
        let bobTotal = standings.ranked.first { $0.entrantID == b.id }!.total
        XCTAssertEqual(aliceTotal, 30)
        XCTAssertEqual(bobTotal, 20)
        XCTAssertFalse(standings.isOver)
    }

    func test_cifteDoublesEveryEntrantsDeltaForThatRound() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 10, b.id: 5], cifte: true)]
        )

        let standings = FixedRoundsEngine().standings(for: match)

        let alice = standings.ranked.first { $0.entrantID == a.id }!
        let bob = standings.ranked.first { $0.entrantID == b.id }!
        XCTAssertEqual(alice.total, 20)
        XCTAssertEqual(alice.deltaFromLastRound, 20)
        XCTAssertEqual(bob.total, 10)
        XCTAssertEqual(bob.deltaFromLastRound, 10)
    }

    func test_noOneIsEverMarkedOut() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 500, b.id: 5])]
        )

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertTrue(standings.ranked.allSatisfy { !$0.isOut })
    }

    func test_matchDoesNotEndBeforeTheConfiguredRoundCount() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let rounds = (0..<7).map { _ in Round(deltas: [a.id: 5, b.id: 10]) }
        let match = makeMatch(entrants: [a, b], rounds: rounds)

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertFalse(standings.isOver)
        XCTAssertNil(standings.result)
    }

    func test_lowestTotalWinsOnceTheConfiguredRoundCountIsReached() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let rounds = (0..<8).map { _ in Round(deltas: [a.id: 5, b.id: 10]) }
        let match = makeMatch(entrants: [a, b], rounds: rounds)

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertTrue(standings.isOver)
        XCTAssertEqual(standings.result, "Alice wins!")
        XCTAssertEqual(standings.ranked.map(\.name), ["Alice", "Bob"])
    }

    func test_tiedLowestTotalAtTheEndProducesATieResult() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let rounds = (0..<8).map { _ in Round(deltas: [a.id: 5, b.id: 5]) }
        let match = makeMatch(entrants: [a, b], rounds: rounds)

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertTrue(standings.isOver)
        XCTAssertEqual(standings.result, "Tie between Alice and Bob!")
    }

    // MARK: - Undo

    func test_standingsAfterAppendingThenUndoingARoundMatchStandingsBeforeAppending() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 5])]
        )

        let before = FixedRoundsEngine().standings(for: match)

        match.rounds.append(Round(deltas: [a.id: 10, b.id: 15], cifte: true))
        match.undoLastRound()

        let after = FixedRoundsEngine().standings(for: match)

        XCTAssertEqual(before, after)
    }
}
