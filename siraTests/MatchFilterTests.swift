import XCTest
@testable import sira

final class MatchFilterTests: XCTestCase {
    private func makeMatch(archived: Bool) -> Match {
        Match(game: .gonga, variant: .gongaStandard, mode: .players, entrants: [Entrant(name: "Alice")], archived: archived)
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

    private func makeMatch(createdAt: Date, archived: Bool = false) -> Match {
        Match(
            game: .gonga,
            variant: .gongaStandard,
            mode: .players,
            entrants: [Entrant(name: "Alice")],
            archived: archived,
            createdAt: createdAt
        )
    }

    func test_applyOrdersMatchesNewestCreatedFirst() {
        let oldest = makeMatch(createdAt: .fixture(year: 2026, month: 1, day: 5))
        let newest = makeMatch(createdAt: .fixture(year: 2026, month: 6, day: 5))
        let middle = makeMatch(createdAt: .fixture(year: 2026, month: 3, day: 5))

        let ordered = MatchFilter.all.apply(to: [oldest, newest, middle])

        XCTAssertEqual(ordered.map(\.id), [newest.id, middle.id, oldest.id])
    }

    func test_applyFiltersBeforeOrdering() {
        let activeOld = makeMatch(createdAt: .fixture(year: 2026, month: 1, day: 5))
        let archivedNew = makeMatch(createdAt: .fixture(year: 2026, month: 6, day: 5), archived: true)
        let activeNew = makeMatch(createdAt: .fixture(year: 2026, month: 4, day: 5))

        let ordered = MatchFilter.active.apply(to: [activeOld, archivedNew, activeNew])

        XCTAssertEqual(ordered.map(\.id), [activeNew.id, activeOld.id])
    }
}
