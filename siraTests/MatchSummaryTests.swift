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
}
