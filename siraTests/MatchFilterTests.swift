import XCTest
@testable import sira

final class MatchFilterTests: XCTestCase {
    /// A Match Home lists: Started, because it has been scored. Every filter
    /// is a view of the Started Matches, so this is the baseline the Active /
    /// All / Archived rules are read against.
    private func makeMatch(archived: Bool = false, createdAt: Date = .fixture(year: 2026, month: 1, day: 1)) -> Match {
        let alice = Entrant(name: "Alice")
        return Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [alice],
            rounds: [Round(deltas: [alice.id: 10])],
            archived: archived,
            createdAt: createdAt
        )
    }

    /// A Match set up and never scored — the mis-tap at Setup.
    private func unStartedMatch(archived: Bool = false) -> Match {
        Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [Entrant(name: "Alice")],
            archived: archived
        )
    }

    func test_activeIncludesOnlyNonArchivedMatches() {
        XCTAssertTrue(MatchFilter.active.includes(makeMatch(archived: false)))
        XCTAssertFalse(MatchFilter.active.includes(makeMatch(archived: true)))
    }

    func test_archivedIncludesOnlyArchivedMatches() {
        XCTAssertFalse(MatchFilter.archived.includes(makeMatch(archived: false)))
        XCTAssertTrue(MatchFilter.archived.includes(makeMatch(archived: true)))
    }

    func test_allIncludesEveryStartedMatch() {
        XCTAssertTrue(MatchFilter.all.includes(makeMatch(archived: false)))
        XCTAssertTrue(MatchFilter.all.includes(makeMatch(archived: true)))
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
        let archivedNew = makeMatch(archived: true, createdAt: .fixture(year: 2026, month: 6, day: 5))
        let activeNew = makeMatch(createdAt: .fixture(year: 2026, month: 4, day: 5))

        let ordered = MatchFilter.active.apply(to: [activeOld, archivedNew, activeNew])

        XCTAssertEqual(ordered.map(\.id), [activeNew.id, activeOld.id])
    }

    // MARK: - Started

    /// Home lists games that have been scored. Every filter is a view of that
    /// list, so an un-Started Match is out of all three rather than out of
    /// Active and back in under All.
    func test_noFilterIncludesAnUnStartedMatch() {
        for filter in MatchFilter.allCases {
            XCTAssertFalse(
                filter.includes(unStartedMatch(archived: false)),
                "\(filter.rawValue) listed an un-Started Match"
            )
            XCTAssertFalse(
                filter.includes(unStartedMatch(archived: true)),
                "\(filter.rawValue) listed an un-Started Match"
            )
        }
    }

    /// The case that breaks if the filter counts Rounds instead of reading the
    /// flag: undoing the only Round leaves the Match on Home.
    func test_aStartedMatchWhoseOnlyRoundWasUndoneIsStillListed() {
        let match = makeMatch()
        _ = match.undoLastRound()

        XCTAssertTrue(match.rounds.isEmpty)
        XCTAssertTrue(MatchFilter.active.includes(match))
    }

    func test_applyDropsUnStartedMatchesBeforeOrdering() {
        let started = makeMatch()

        XCTAssertEqual(
            MatchFilter.all.apply(to: [unStartedMatch(), started]).map(\.id),
            [started.id]
        )
    }
}
