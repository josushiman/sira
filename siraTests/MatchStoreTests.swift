import XCTest
import SwiftData
@testable import sira

final class MatchStoreTests: XCTestCase {
    private func gongaMatch(entrants: [Entrant] = [Entrant(name: "Alice")]) -> Match {
        Match(game: .gonga, variant: .gonga101, mode: .players, entrants: entrants)
    }

    /// Reading is `@Query`'s job in the app, so the store's own tests read the
    /// same way the framework does rather than through an array the store keeps.
    private func storedMatches(in store: MatchStore) throws -> [Match] {
        try store.context.fetch(FetchDescriptor<Match>())
    }

    func test_addPutsTheMatchInTheStore() throws {
        let store = MatchStore()
        let match = gongaMatch()

        store.add(match)

        XCTAssertEqual(try storedMatches(in: store).map(\.id), [match.id])
    }

    func test_addedMatchKeepsItsEntrantsAndVariant() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let bob = Entrant(name: "Bob")

        store.add(gongaMatch(entrants: [alice, bob]))

        let stored = try XCTUnwrap(try storedMatches(in: store).first)
        XCTAssertEqual(stored.variant, .gonga101)
        XCTAssertEqual(stored.entrants.map(\.name).sorted(), ["Alice", "Bob"])
    }

    func test_addRoundAppendsToTheMatch() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let match = gongaMatch(entrants: [alice])
        store.add(match)

        let round = Round(deltas: [alice.id: 10])
        store.addRound(round, to: match)

        XCTAssertEqual(match.rounds.map(\.id), [round.id])
    }

    /// Undo has two halves — dropping the Round from the Match, and deleting
    /// the Round itself. Leaving the second one out would leave a Round in the
    /// store belonging to no Match.
    func test_undoLastRoundRemovesTheRoundAndLeavesNoOrphan() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let match = gongaMatch(entrants: [alice])
        store.add(match)
        store.addRound(Round(deltas: [alice.id: 10]), to: match)
        store.addRound(Round(deltas: [alice.id: 20]), to: match)

        store.undoLastRound(in: match)

        XCTAssertEqual(match.rounds.map { $0.deltas[alice.id] }, [10])
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Round>()).count, 1)
    }

    func test_undoLastRoundOnAMatchWithNoRoundsIsANoOp() throws {
        let store = MatchStore()
        let match = gongaMatch()
        store.add(match)

        store.undoLastRound(in: match)

        XCTAssertEqual(match.rounds, [])
    }

    func test_archiveAndRestoreFlipTheMatchesVisibility() throws {
        let store = MatchStore()
        let match = gongaMatch()
        store.add(match)

        store.archive(match)
        XCTAssertTrue(match.archived)

        store.restore(match)
        XCTAssertFalse(match.archived)
    }

    func test_recordRejoinAttachesToTheLatestRound() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let match = gongaMatch(entrants: [alice])
        store.add(match)
        store.addRound(Round(deltas: [alice.id: 105]), to: match)

        store.recordRejoin(RejoinEvent(id: alice.id, to: 40), in: match)

        XCTAssertEqual(match.rounds.last?.rejoins, [RejoinEvent(id: alice.id, to: 40)])
    }

    /// The seeded fixtures are what previews and view tests draw, so they have
    /// to be two Matches with the fixed dates those snapshots were recorded at.
    func test_seededHoldsTheTwoFixtureMatches() throws {
        let store = MatchStore.seeded()

        let matches = try storedMatches(in: store)

        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches.filter(\.archived).count, 1)
    }

    /// Each seeded Match owns its own Alice. Handing one Entrant to both would
    /// move her out of the first Match rather than have her play in two.
    func test_seededMatchesDoNotShareAnEntrant() throws {
        let store = MatchStore.seeded()

        let matches = try storedMatches(in: store)

        XCTAssertEqual(matches.map(\.entrants.count), [2, 2])
        let entrantIDs = matches.flatMap { $0.entrants.map(\.id) }
        XCTAssertEqual(Set(entrantIDs).count, entrantIDs.count)
    }
}
