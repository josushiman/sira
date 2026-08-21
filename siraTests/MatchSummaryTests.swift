import XCTest
@testable import sira

final class MatchSummaryTests: XCTestCase {
    private let engine = SurvivalEngine()

    func test_inProgressMatchShowsTheLeaderAndTheirScore() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 5])]
        )

        let summary = MatchSummary(match: match, engine: engine)

        XCTAssertEqual(summary.text, "Bob leads with 5")
    }

    func test_overMatchShowsTheEnginesResultText() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 110, b.id: 5])]
        )

        let summary = MatchSummary(match: match, engine: engine)

        XCTAssertEqual(summary.text, engine.standings(for: match).result)
    }

    func test_matchWithNoEntrantsShowsAPlaceholder() {
        let match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [])

        let summary = MatchSummary(match: match, engine: engine)

        XCTAssertEqual(summary.text, "No Entrants")
    }

    /// The Home card's line is derived from Standings, so it inherits their
    /// order-independence — asserted here rather than assumed, because this is
    /// the reading a player checks without opening the Match.
    func test_summaryReadsTheSameHoweverRoundsAreStored() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        // Alice goes Out on the first Round and rejoins at 20, so the second
        // Round's 10 lands on 20 rather than on the 110 it would the other way
        // round.
        let inOrder = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 105, b.id: 5], rejoins: [RejoinEvent(id: a.id, to: 20)]),
                Round(deltas: [a.id: 10, b.id: 15]),
            ]
        )

        let expected = MatchSummary(match: inOrder, engine: engine).text
        let actual = MatchSummary(match: inOrder.withEntrantsAndRoundsStoredOutOfOrder(), engine: engine).text

        XCTAssertEqual(actual, expected)

        let reversed = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a, b],
            rounds: Array(inOrder.rounds.reversed())
        )
        XCTAssertNotEqual(MatchSummary(match: reversed, engine: engine).text, expected)
    }
}
