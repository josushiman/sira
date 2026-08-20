import XCTest
import SwiftData
@testable import sira

/// What a player would see after quitting the app and opening it again.
///
/// Every test here writes through one store, lets that store go, and opens a
/// second one over the same location — the closest thing to a relaunch a test
/// can perform, and the only way to prove durability rather than infer it from
/// the schema. Each test gets its own temporary location, so no test can read
/// what another one wrote.
final class MatchStorePersistenceTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = URL.temporaryDirectory.appending(path: "MatchStorePersistenceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
        directory = nil
    }

    /// Opens a store over this test's location and runs `body` against it. Each
    /// call stands for one launch of the app.
    ///
    /// Everything a store's Matches are needed for happens inside the closure,
    /// and only value types come back out. A Match is no use once its store has
    /// gone — it reads through a container that no longer exists, which
    /// SwiftData traps on rather than reports — so the shape of this helper is
    /// what keeps a test from returning one by accident.
    private func launch<T>(_ body: (MatchStore) throws -> T) throws -> T {
        let store = try MatchStore(storedAt: directory.appending(path: "Sira.store"))
        return try body(store)
    }

    /// Reads a Match back the way the app does — by its own id, which means the
    /// same thing before a Match is stored as after.
    private func match(_ id: Match.ID, in store: MatchStore) throws -> Match {
        let matches = try store.context.fetch(FetchDescriptor<Match>())
        return try XCTUnwrap(matches.first { $0.id == id })
    }

    private func entrant(_ name: String, in match: Match) throws -> Entrant {
        try XCTUnwrap(match.entrants.first { $0.name == name })
    }

    // MARK: - First launch

    /// The first thing a new player sees. Until Matches were stored, the app
    /// could not show this state at all — it opened on two fixture Matches
    /// belonging to nobody.
    func test_aStoreOverAFreshLocationHoldsNoMatches() throws {
        let count = try launch { store in
            try store.context.fetch(FetchDescriptor<Match>()).count
        }

        XCTAssertEqual(count, 0)
    }

    // MARK: - The Match itself

    func test_aMatchComesBackWithItsGameVariantModeEntrantsAndArchivedFlag() throws {
        let matchID = try launch { store -> Match.ID in
            let match = Match(
                game: .okey,
                variant: .okeyStandard,
                mode: .teams,
                entrants: [Entrant(name: "Kırmızı"), Entrant(name: "Mavi")]
            )
            store.add(match)
            store.archive(match)
            return match.id
        }

        try launch { store in
            let reloaded = try match(matchID, in: store)

            XCTAssertEqual(reloaded.game, .okey)
            XCTAssertEqual(reloaded.variant, .okeyStandard)
            XCTAssertEqual(reloaded.mode, .teams)
            XCTAssertEqual(reloaded.entrants.map(\.name).sorted(), ["Kırmızı", "Mavi"])
            XCTAssertTrue(reloaded.archived)
        }
    }

    /// Enough Entrants that an accidental reordering shows up. Their seats are
    /// what the dot-badge colours are picked from, so a Match whose scores have
    /// not moved would otherwise come back in different colours.
    func test_entrantsComeBackInTheOrderTheyWereSeatedAtSetup() throws {
        let seated = ["Alice", "Bob", "Cem", "Deniz", "Ece", "Fatma"]
        let matchID = try launch { store -> Match.ID in
            let match = Match(
                game: .gonga,
                variant: .gonga101,
                mode: .players,
                entrants: seated.map { Entrant(name: $0) }
            )
            store.add(match)
            return match.id
        }

        try launch { store in
            let reloaded = try match(matchID, in: store)

            XCTAssertEqual(reloaded.entrants.map(\.name), seated)
        }
    }

    // MARK: - Round order

    /// Enough Rounds that an accidental reordering shows up, rather than the
    /// two or three a wrong order has an even chance of surviving.
    func test_roundsComeBackInTheOrderTheyWereEntered() throws {
        let entered = [7, 13, 21, 34, 55, 89, 3]
        let matchID = try launch { store -> Match.ID in
            let alice = Entrant(name: "Alice")
            let match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [alice])
            store.add(match)
            for delta in entered {
                store.addRound(Round(deltas: [alice.id: delta]), to: match)
            }
            return match.id
        }

        try launch { store in
            let reloaded = try match(matchID, in: store)
            let alice = try entrant("Alice", in: reloaded)

            XCTAssertEqual(reloaded.rounds.map { $0.deltas[alice.id] }, entered)
        }
    }

    // MARK: - What a Round carries

    func test_aRoundsModifiersRejoinsAndRawDeltasAllSurvive() throws {
        let matchID = try launch { store -> Match.ID in
            let alice = Entrant(name: "Alice")
            let bob = Entrant(name: "Bob")
            let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: [alice, bob])
            store.add(match)
            store.addRound(
                Round(
                    deltas: [alice.id: 101, bob.id: 0],
                    cifteCallers: [alice.id, bob.id],
                    okeyAtanID: bob.id,
                    losingEntrantID: alice.id,
                    gostergeFinderID: bob.id
                ),
                to: match
            )
            store.recordRejoin(RejoinEvent(id: alice.id, to: 40), in: match)
            return match.id
        }

        try launch { store in
            let reloaded = try match(matchID, in: store)
            let alice = try entrant("Alice", in: reloaded)
            let bob = try entrant("Bob", in: reloaded)
            let round = try XCTUnwrap(reloaded.rounds.first)

            // Raw as entered: 101 is what the player typed, never the doubled
            // figure the Çifte call produces (`docs/adr/0005`).
            XCTAssertEqual(round.deltas, [alice.id: 101, bob.id: 0])
            XCTAssertEqual(round.cifteCallers, [alice.id, bob.id])
            XCTAssertEqual(round.okeyAtanID, bob.id)
            XCTAssertEqual(round.losingEntrantID, alice.id)
            XCTAssertEqual(round.gostergeFinderID, bob.id)
            XCTAssertEqual(round.rejoins, [RejoinEvent(id: alice.id, to: 40)])
        }
    }

    // MARK: - Standings across the reload

    /// The test that actually proves a player's tally is safe: not that the
    /// fields came back, but that the number on screen is the same number.
    ///
    /// Written once per Win Condition, because each Engine reads a different
    /// part of a Round and a persistence bug could reach one and not the others.
    func test_survivalStandingsAreUnchangedByAReload_includingAnEntrantWhoIsOut() throws {
        let (matchID, before) = try launch { store -> (Match.ID, Standings) in
            let alice = Entrant(name: "Alice")
            let bob = Entrant(name: "Bob")
            let carol = Entrant(name: "Carol")
            let dave = Entrant(name: "Dave")
            let match = Match(
                game: .gonga,
                variant: .gonga101,
                mode: .players,
                entrants: [alice, bob, carol, dave]
            )
            store.add(match)
            store.addRound(Round(deltas: [alice.id: 20, bob.id: 15, carol.id: 30, dave.id: 45]), to: match)
            // Alice busts and is brought back in, so the reload has a Rejoin to
            // recover as well as an Out.
            store.addRound(Round(deltas: [alice.id: 90, bob.id: 10, carol.id: 5, dave.id: 20]), to: match)
            store.recordRejoin(RejoinEvent(id: alice.id, to: 70), in: match)
            // Dave busts and stays Out.
            store.addRound(Round(deltas: [alice.id: 5, bob.id: 8, carol.id: 4, dave.id: 100]), to: match)
            return (match.id, WinCondition.survival.engine.standings(for: match))
        }

        try launch { store in
            let after = WinCondition.survival.engine.standings(for: try match(matchID, in: store))

            XCTAssertEqual(after, before)
            XCTAssertEqual(after.ranked.filter(\.isOut).map(\.name), ["Dave"])
        }
    }

    func test_eliminationStandingsAreUnchangedByAReload_includingAMatchThatIsOver() throws {
        let (matchID, before) = try launch { store -> (Match.ID, Standings) in
            let kirmizi = Entrant(name: "Kırmızı")
            let mavi = Entrant(name: "Mavi")
            let match = Match(game: .okey, variant: .okeyStandard, mode: .teams, entrants: [kirmizi, mavi])
            store.add(match)
            // Ten Rounds at −2 leaves Mavi on 1; the eleventh is doubled by a
            // Çifte call, which takes them past 0 and ends the Match.
            for _ in 0..<10 {
                store.addRound(Round(losingEntrantID: mavi.id), to: match)
            }
            store.addRound(Round(cifteCallers: [mavi.id], losingEntrantID: mavi.id), to: match)
            return (match.id, WinCondition.elimination.engine.standings(for: match))
        }

        try launch { store in
            let after = WinCondition.elimination.engine.standings(for: try match(matchID, in: store))

            XCTAssertEqual(after, before)
            XCTAssertTrue(after.isOver)
            XCTAssertEqual(after.result, "Kırmızı wins!")
        }
    }

    func test_fixedRoundsStandingsAreUnchangedByAReload() throws {
        let (matchID, before) = try launch { store -> (Match.ID, Standings) in
            let alice = Entrant(name: "Alice")
            let bob = Entrant(name: "Bob")
            let carol = Entrant(name: "Carol")
            let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: [alice, bob, carol])
            store.add(match)
            store.addRound(
                Round(deltas: [alice.id: 30, bob.id: 0, carol.id: 45], cifteCallers: [carol.id]),
                to: match
            )
            store.addRound(
                Round(deltas: [alice.id: 12, bob.id: 20, carol.id: 0], okeyAtanID: carol.id),
                to: match
            )
            return (match.id, WinCondition.fixedRounds.engine.standings(for: match))
        }

        try launch { store in
            let after = WinCondition.fixedRounds.engine.standings(for: try match(matchID, in: store))

            XCTAssertEqual(after, before)
        }
    }

    /// Okey 101's Round count is chosen at Setup rather than by the Variant, so
    /// it is the one part of the rules stored per Match. Lose it and a 12-Round
    /// Match resolves the Variant's own 8 and declares itself over four Rounds
    /// early.
    func test_okey101sSetupChosenRoundCountSurvives() throws {
        let matchID = try launch { store -> Match.ID in
            let alice = Entrant(name: "Alice")
            let bob = Entrant(name: "Bob")
            let match = Match(
                game: .okey,
                variantId: Variant.okey101.id,
                roundCount: 12,
                mode: .players,
                entrants: [alice, bob]
            )
            store.add(match)
            for _ in 0..<8 {
                store.addRound(Round(deltas: [alice.id: 10, bob.id: 0]), to: match)
            }
            return match.id
        }

        try launch { store in
            let reloaded = try match(matchID, in: store)

            XCTAssertEqual(reloaded.variant?.roundCount, 12)
            XCTAssertFalse(WinCondition.fixedRounds.engine.standings(for: reloaded).isOver)
        }
    }

    // MARK: - Undo after a reload

    func test_undoAfterAReloadRemovesTheLastRoundAndNothingElse() throws {
        let matchID = try launch { store -> Match.ID in
            let alice = Entrant(name: "Alice")
            let match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [alice])
            store.add(match)
            for delta in [10, 20, 30] {
                store.addRound(Round(deltas: [alice.id: delta]), to: match)
            }
            return match.id
        }

        try launch { store in
            let reloaded = try match(matchID, in: store)
            store.undoLastRound(in: reloaded)

            let alice = try entrant("Alice", in: reloaded)
            XCTAssertEqual(reloaded.rounds.map { $0.deltas[alice.id] }, [10, 20])
        }

        // And the Undo is saved like any other change: the launch after it does
        // not find the Round back again.
        try launch { store in
            let afterUndo = try match(matchID, in: store)
            let alice = try entrant("Alice", in: afterUndo)

            XCTAssertEqual(afterUndo.rounds.map { $0.deltas[alice.id] }, [10, 20])
            XCTAssertEqual(try store.context.fetch(FetchDescriptor<Round>()).count, 2)
        }
    }

    // MARK: - When a save fails

    /// A full disk is the realistic case. The Round the player just entered
    /// stays exactly where it is: playing on against a tally that has silently
    /// stopped recording is the failure worth avoiding, and throwing the Round
    /// away to keep memory and disk in step would be the same failure with the
    /// evidence removed.
    func test_aFailedSaveIsSurfacedAndKeepsTheChangeInMemory() throws {
        let store = MatchStore { _ in throw DiskFull() }
        let alice = Entrant(name: "Alice")
        let match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [alice])
        store.add(match)

        store.addRound(Round(deltas: [alice.id: 40]), to: match)

        XCTAssertNotNil(store.saveFailure)
        XCTAssertEqual(match.rounds.map { $0.deltas[alice.id] }, [40])
        XCTAssertEqual(
            WinCondition.survival.engine.standings(for: match).ranked.map(\.total),
            [40]
        )
    }

    func test_aSaveThatSucceedsClearsAnEarlierFailure() throws {
        var failing = true
        let store = MatchStore { context in
            if failing { throw DiskFull() }
            try context.save()
        }
        let alice = Entrant(name: "Alice")
        let match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [alice])
        store.add(match)
        XCTAssertNotNil(store.saveFailure)

        failing = false
        store.addRound(Round(deltas: [alice.id: 40]), to: match)

        XCTAssertNil(store.saveFailure)
    }

    func test_acknowledgingASaveFailureLeavesTheChangeInPlace() throws {
        let store = MatchStore { _ in throw DiskFull() }
        let alice = Entrant(name: "Alice")
        let match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [alice])
        store.add(match)

        store.acknowledgeSaveFailure()

        XCTAssertNil(store.saveFailure)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Match>()).map(\.id), [match.id])
    }
}

/// The save failure worth designing for: the device has no room left.
private struct DiskFull: Error {}
