import XCTest
@testable import sira

final class MatchFilterTests: XCTestCase {
    private func makeMatch(archived: Bool) -> Match {
        Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [Entrant(name: "Alice")], archived: archived)
    }

    func test_activeIncludesOnlyNonArchivedMatches() {
        XCTAssertTrue(MatchFilter.active.includes(makeMatch(archived: false)))
        XCTAssertFalse(MatchFilter.active.includes(makeMatch(archived: true)))
    }

    func test_archivedIncludesOnlyArchivedMatches() {
        XCTAssertFalse(MatchFilter.archived.includes(makeMatch(archived: false)))
        XCTAssertTrue(MatchFilter.archived.includes(makeMatch(archived: true)))
    }

    func test_allIncludesEveryMatch() {
        XCTAssertTrue(MatchFilter.all.includes(makeMatch(archived: false)))
        XCTAssertTrue(MatchFilter.all.includes(makeMatch(archived: true)))
    }
}
