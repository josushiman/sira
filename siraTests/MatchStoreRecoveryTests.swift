import XCTest
import SwiftData
@testable import sira

/// What happens when the data on the device cannot be used — the two ways that
/// can happen, and the one thing that must never happen in either.
///
/// A player whose store is corrupt gets a working, empty app rather than one
/// that will not start, and a Match this build has no rules for is passed over
/// rather than shown under a substitute. In both cases the data that could not
/// be read is still on the device afterwards: the app recovers by setting data
/// aside, never by destroying it.
final class MatchStoreRecoveryTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = URL.temporaryDirectory.appending(path: "MatchStoreRecoveryTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
        directory = nil
    }

    private var storeURL: URL { directory.appending(path: "Sira.store") }

    /// Opens a store over this test's location the way the app opens its own,
    /// recovering rather than failing, and runs `body` against it. Each call
    /// stands for one launch of the app.
    ///
    /// Only value types come back out, for the reason
    /// `MatchStorePersistenceTests.launch(_:)` gives: a Match outliving its
    /// store reads through a container that no longer exists.
    private func launch<T>(_ body: (MatchStore) throws -> T) throws -> T {
        let store = try MatchStore(recoveringAt: storeURL)
        return try body(store)
    }

    /// Bytes that are not a database, standing in for whatever real corruption
    /// would look like. Recognisable so that a test can prove the same bytes
    /// are still on the device after recovery.
    private static let rubbish = Data("this is not a database".utf8)

    private func writeRubbishWhereTheStoreGoes() throws {
        try Self.rubbish.write(to: storeURL)
    }

    /// Everything in this test's directory that recovery has set aside.
    private func movedAside() throws -> [URL] {
        try FileManager.default
            .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.contains("unreadable") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    // MARK: - A store that cannot be opened

    func test_aStoreThatCannotBeOpenedYieldsAWorkingEmptyStore() throws {
        try writeRubbishWhereTheStoreGoes()

        let count = try launch { store in
            try store.context.fetch(FetchDescriptor<Match>()).count
        }

        XCTAssertEqual(count, 0)
    }

    /// The data is set aside, not destroyed: the same bytes that could not be
    /// read are still on the device, under a name that says what they are.
    func test_dataThatCouldNotBeReadIsStillPresentUnderItsMovedAsideName() throws {
        try writeRubbishWhereTheStoreGoes()

        try launch { _ in }

        let setAside = try movedAside()
        XCTAssertEqual(setAside.count, 1)
        let recovered = try XCTUnwrap(setAside.first)
        XCTAssertEqual(try Data(contentsOf: recovered), Self.rubbish)
        XCTAssertTrue(recovered.lastPathComponent.hasPrefix("Sira-unreadable-"))
    }

    /// SQLite keeps a write-ahead log and a shared memory file beside the
    /// store, holding writes that have not been folded into it yet. They are as
    /// much the player's data as the store file is, so they are set aside with
    /// it — and leaving either behind would hand the fresh store the tail of
    /// the unreadable one.
    func test_theWriteAheadLogAndSharedMemoryFileAreSetAsideWithTheStore() throws {
        try writeRubbishWhereTheStoreGoes()
        let sidecars = ["-wal", "-shm"]
        for sidecar in sidecars {
            try Self.rubbish.write(to: directory.appending(path: "Sira.store" + sidecar))
        }

        try launch { _ in }

        // All three files are set aside together, and what sits at their old
        // paths afterwards belongs to the fresh store rather than the old one —
        // asserted by content, because the fresh store makes sidecars of its
        // own at exactly those names.
        XCTAssertEqual(try movedAside().count, 3)
        XCTAssertEqual(try movedAside().map { try Data(contentsOf: $0) }, Array(repeating: Self.rubbish, count: 3))
        for sidecar in sidecars {
            let atOldPath = directory.appending(path: "Sira.store" + sidecar)
            guard FileManager.default.fileExists(atPath: atOldPath.path) else { continue }
            XCTAssertNotEqual(
                try Data(contentsOf: atOldPath),
                Self.rubbish,
                "\(sidecar) was left behind for the fresh store to pick up"
            )
        }
    }

    /// Two stores set aside keep both sets of data: the second recovery does
    /// not overwrite what the first one saved, and does not fail trying.
    func test_recoveringTwiceKeepsBothSetsOfSetAsideData() throws {
        try writeRubbishWhereTheStoreGoes()
        try launch { _ in }

        let second = Data("a second unreadable store".utf8)
        try second.write(to: storeURL)
        try launch { _ in }

        // Counted by content rather than by file, because the store the first
        // recovery opened brings sidecars of its own to be set aside alongside.
        let contents = try movedAside().map { try Data(contentsOf: $0) }
        XCTAssertTrue(contents.contains(Self.rubbish))
        XCTAssertTrue(contents.contains(second))
    }

    /// The failure this recovery must not become: an app that looks like it is
    /// working while saving nothing. A Match entered after recovering is on the
    /// device, and the launch after that finds it.
    func test_aMatchEnteredAfterRecoveringIsStillThereOnTheNextLaunch() throws {
        try writeRubbishWhereTheStoreGoes()

        let matchID = try launch { store -> Match.ID in
            let match = Match(
                game: .gonga,
                variant: .gongaStandard,
                mode: .players,
                entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")]
            )
            store.add(match)
            return match.id
        }

        try launch { store in
            let matches = try store.context.fetch(FetchDescriptor<Match>())
            XCTAssertEqual(matches.map(\.id), [matchID])
        }
    }

    /// Recovery is for the store that cannot be opened and nothing else: a
    /// store that opens normally keeps its Matches and has nothing set aside.
    func test_aStoreThatOpensNormallyIsLeftExactlyAsItWas() throws {
        let matchID = try launch { store -> Match.ID in
            let match = Match(
                game: .gonga,
                variant: .gongaStandard,
                mode: .players,
                entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")]
            )
            store.add(match)
            return match.id
        }

        try launch { store in
            let matches = try store.context.fetch(FetchDescriptor<Match>())
            XCTAssertEqual(matches.map(\.id), [matchID])
        }
        XCTAssertEqual(try movedAside(), [])
    }

    // MARK: - A Match this build cannot score

    /// A Match naming a Variant this build knows nothing about — a downgrade,
    /// or a bad write — is passed over rather than shown under a substitute,
    /// and rather than deleted: it is still on the device, Rounds and all, for
    /// the build that does know the id.
    func test_aMatchNamingAnUnknownVariantIdIsSkippedAndItsDataIsLeftUntouched() throws {
        let strangerID = try launch { store -> Match.ID in
            let alice = Entrant(name: "Alice")
            let bob = Entrant(name: "Bob")
            let stranger = Match(
                game: .gonga,
                variantId: "gonga-from-a-later-release",
                mode: .players,
                entrants: [alice, bob]
            )
            store.add(stranger)
            store.addRound(Round(deltas: [alice.id: 20, bob.id: 30]), to: stranger)
            return stranger.id
        }

        try launch { store in
            let stored = try store.context.fetch(FetchDescriptor<Match>())

            XCTAssertEqual(stored.scorable.count, 0)
            let stranger = try XCTUnwrap(stored.first { $0.id == strangerID })
            XCTAssertEqual(stranger.variantId, "gonga-from-a-later-release")
            XCTAssertEqual(stranger.entrants.map(\.name), ["Alice", "Bob"])
            XCTAssertEqual(stranger.rounds.count, 1)
        }
    }

    /// Skipping one Match is all that skipping does: every other Match loads
    /// and scores exactly as it would have.
    func test_skippingAMatchLeavesEveryOtherMatchLoadingAndScoringNormally() throws {
        let (playableID, before) = try launch { store -> (Match.ID, Standings) in
            let alice = Entrant(name: "Alice")
            let bob = Entrant(name: "Bob")
            let playable = Match(
                game: .gonga,
                variant: .gongaStandard,
                mode: .players,
                entrants: [alice, bob]
            )
            store.add(playable)
            store.addRound(Round(deltas: [alice.id: 40, bob.id: 25]), to: playable)
            store.addRound(Round(deltas: [alice.id: 15, bob.id: 30]), to: playable)

            let stranger = Match(
                game: .gonga,
                variantId: "gonga-from-a-later-release",
                mode: .players,
                entrants: [Entrant(name: "Carol"), Entrant(name: "Dave")]
            )
            store.add(stranger)

            return (playable.id, WinCondition.survival.engine.standings(for: playable))
        }

        try launch { store in
            let scorable = try store.context.fetch(FetchDescriptor<Match>()).scorable

            XCTAssertEqual(scorable.map(\.match.id), [playableID])
            let (match, variant) = try XCTUnwrap(scorable.first)
            XCTAssertEqual(variant.id, Variant.gongaStandard.id)
            XCTAssertEqual(variant.winCondition.engine.standings(for: match), before)
        }
    }
}
