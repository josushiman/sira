import XCTest
import SwiftData
@testable import sira

/// Real V1 disk stores, opened through the same boundary as the app. No V2
/// model or new lifecycle field is used to manufacture the legacy data.
final class MatchStoreMigrationTests: XCTestCase {
    private var directory: URL!
    private var storeURL: URL { directory.appending(path: "Sira.store") }

    override func setUpWithError() throws {
        directory = URL.temporaryDirectory.appending(path: "MatchStoreMigrationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
        directory = nil
    }

    private func writeV1<T>(_ body: (ModelContext) throws -> T) throws -> T {
        try autoreleasepool {
            let container = try ModelContainer(
                for: Schema(versionedSchema: SiraSchemaV1.self),
                configurations: ModelConfiguration(url: storeURL)
            )
            let context = ModelContext(container)
            let result = try body(context)
            try context.save()
            return result
        }
    }

    private func launch<T>(_ body: (MatchStore) throws -> T) throws -> T {
        try autoreleasepool {
            let store = try MatchStore(recoveringAt: storeURL)
            store.discardUnstartedMatches()
            let result = try body(store)
            XCTAssertNil(store.saveFailure)
            return result
        }
    }

    private func match(_ id: UUID, in store: MatchStore) throws -> Match {
        try XCTUnwrap(store.context.fetch(FetchDescriptor<Match>()).first { $0.id == id })
    }

    func test_oldCompletionAndVisibilitySurviveMigrationAndASecondLaunch() throws {
        let cases = try writeV1 { context in
            [(true, false), (true, true), (false, false), (false, true)].map { completed, archived in
                let alice = SiraSchemaV1.Entrant(name: "Alice", sequence: 0)
                let bob = SiraSchemaV1.Entrant(name: "Bob", sequence: 1)
                let rounds = (0..<(completed ? 3 : 2)).map { sequence in
                    SiraSchemaV1.Round(sequence: sequence, deltas: [alice.id: 10, bob.id: 10])
                }
                let match = SiraSchemaV1.Match(
                    game: .okey, variantId: "okey-101", roundCount: 3, mode: .players,
                    storedEntrants: [bob, alice], storedRounds: rounds.reversed(),
                    archived: archived, createdAt: Date(timeIntervalSince1970: 1_700_000_000)
                )
                match.started = true
                context.insert(match)
                return (match.id, completed, archived)
            }
        }

        for _ in 0..<2 {
            try launch { store in
                XCTAssertEqual(try store.context.fetch(FetchDescriptor<Match>()).count, 4)
                for (id, completed, archived) in cases {
                    let match = try match(id, in: store)
                    XCTAssertEqual(match.ended, completed)
                    XCTAssertEqual(match.archived, archived)
                    XCTAssertTrue(match.started)
                    XCTAssertEqual(match.createdAt, Date(timeIntervalSince1970: 1_700_000_000))
                    XCTAssertEqual(match.entrants.map(\.name), ["Alice", "Bob"])
                    XCTAssertEqual(match.entrants.map(\.sequence), [0, 1])
                    XCTAssertEqual(match.rounds.map(\.sequence), completed ? [0, 1, 2] : [0, 1])
                    XCTAssertNil(match.variantNumber)
                    XCTAssertNil(match.numberPhrase)
                    XCTAssertNotNil([match].scorableMatch(id))
                    let standings = WinCondition.lowestTotal.engine.standings(for: match)
                    XCTAssertEqual(standings.ranked.map(\.total), completed ? [30, 30] : [20, 20])
                    XCTAssertEqual(standings.isOver, completed)
                    XCTAssertEqual(standings.result, completed ? "Tie between Alice and Bob!" : nil)
                    XCTAssertEqual(MatchSummary(match: match, engine: WinCondition.lowestTotal.engine).text,
                                   completed ? "Tie between Alice and Bob!" : "Alice leads with 20")
                    if completed {
                        let alice = try XCTUnwrap(match.entrants.first)
                        store.addRound(Round(deltas: [alice.id: 200]), to: match)
                        store.undoLastRound(in: match)
                        store.rename(alice, to: "Changed")
                        XCTAssertEqual(LowestTotalEngine().standings(for: match), standings)
                        XCTAssertTrue(match.isReadOnly)
                        XCTAssertEqual(match.archived, archived)
                    }

                }
            }
        }
        XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .contains { $0.contains("unreadable") }, "Recovery must not hide a failed migration behind an empty store")
    }

    func test_resumedLegacyResultsStayLiveAcrossRelaunchAfterScoringAndUndoToZero() throws {
        let ids = try writeV1 { context in
            [false, true].map { archived in
                let alice = SiraSchemaV1.Entrant(name: "Alice", sequence: 0)
                let bob = SiraSchemaV1.Entrant(name: "Bob", sequence: 1)
                let match = SiraSchemaV1.Match(
                    game: .okey, variantId: "okey-101", roundCount: 1, mode: .players,
                    storedEntrants: [bob, alice],
                    storedRounds: [SiraSchemaV1.Round(deltas: [alice.id: 10, bob.id: 20], cifteCallers: [bob.id], okeyAtanID: alice.id)],
                    archived: archived, createdAt: Date(timeIntervalSince1970: 1_700_000_000)
                )
                match.started = true
                context.insert(match)
                return match.id
            }
        }

        try launch { store in
            for (index, id) in ids.enumerated() {
                let match = try match(id, in: store)
                let alice = try XCTUnwrap(match.entrants.first)
                XCTAssertTrue(match.isReadOnly)
                XCTAssertEqual(match.archived, index == 1)
                XCTAssertTrue(store.resume(match))
                XCTAssertEqual(match.createdAt, Date(timeIntervalSince1970: 1_700_000_000))
                XCTAssertEqual(match.entrants.map(\.sequence), [0, 1])
                XCTAssertEqual(LowestTotalEngine().standings(for: match).ranked.map(\.total), [20, 80])
                if index == 0 {
                    store.addRound(Round(deltas: [alice.id: 30]), to: match)
                } else {
                    store.undoLastRound(in: match)
                }
            }
        }
        try launch { store in
            for (index, id) in ids.enumerated() {
                let match = try match(id, in: store)
                XCTAssertFalse(match.ended)
                XCTAssertFalse(match.archived)
                XCTAssertTrue(match.started)
                XCTAssertEqual(match.rounds.map(\.sequence), index == 0 ? [0, 1] : [])
                XCTAssertEqual(match.canEnd, index == 0)
                if index == 0 {
                    XCTAssertEqual(match.rounds[0].cifteCallers, [match.entrants[1].id])
                    XCTAssertEqual(match.rounds[0].okeyAtanID, match.entrants[0].id)
                    XCTAssertEqual(LowestTotalEngine().standings(for: match).ranked.map(\.total), [50, 80])
                } else {
                    store.addRound(Round(deltas: [match.entrants[0].id: 40]), to: match)
                }
            }
            XCTAssertEqual(store.freeMatches.startedMatches, 2)
        }
        try launch { store in
            for id in ids {
                let match = try match(id, in: store)
                XCTAssertFalse(match.ended, "The old target must never infer completion again")
                XCTAssertFalse(match.archived)
                XCTAssertTrue(match.started)
            }
            XCTAssertEqual(store.freeMatches.startedMatches, 2)
        }
    }

    func test_legacyStartedHistoryAndMissingAccessAccountingAreReconciledOnce() throws {
        let ids = try writeV1 { context in
            let undone = SiraSchemaV1.Match(
                game: .okey, variantId: "okey-101", roundCount: 7, mode: .players,
                storedEntrants: [SiraSchemaV1.Entrant(name: "Alice")], storedRounds: [],
                createdAt: .distantPast
            )
            undone.started = true
            context.insert(undone)
            let scoredBeforeStartedExisted = SiraSchemaV1.Match(
                game: .okey, variantId: "okey-101", roundCount: 7, mode: .players,
                storedEntrants: [SiraSchemaV1.Entrant(name: "Bob")],
                storedRounds: [SiraSchemaV1.Round()], createdAt: .distantPast
            )
            context.insert(scoredBeforeStartedExisted)
            let abandonedSetup = SiraSchemaV1.Match(
                game: .okey, variantId: "okey-101", roundCount: 7, mode: .players,
                storedEntrants: [], storedRounds: [], createdAt: .distantPast
            )
            context.insert(abandonedSetup)
            return (undone.id, scoredBeforeStartedExisted.id)
        }

        for _ in 0..<2 {
            try launch { store in
                XCTAssertEqual(try store.context.fetch(FetchDescriptor<Match>()).count, 2)
                let undone = try match(ids.0, in: store)
                XCTAssertTrue(undone.started)
                XCTAssertTrue(undone.rounds.isEmpty)
                XCTAssertFalse(undone.ended)
                let scored = try match(ids.1, in: store)
                XCTAssertTrue(scored.started)
                XCTAssertFalse(scored.ended)
                XCTAssertEqual(store.freeMatches.startedMatches, 2)
                XCTAssertEqual(store.freeMatches.remaining, 1)
            }
        }
    }


    func test_migratedLiveMatchIgnoresItsOldTargetWithoutAnotherStart() throws {
        let id = try writeV1 { context in
            let alice = SiraSchemaV1.Entrant(name: "Alice")
            let match = SiraSchemaV1.Match(
                game: .okey, variantId: "okey-101", roundCount: 2, mode: .players,
                storedEntrants: [alice], storedRounds: [SiraSchemaV1.Round(deltas: [alice.id: 10])]
            )
            match.started = true
            context.insert(match)
            context.insert(SiraSchemaV1.StartedMatchTally(startedMatches: 1))
            return match.id
        }

        try launch { store in
            let match = try match(id, in: store)
            let alice = try XCTUnwrap(match.entrants.first)
            XCTAssertFalse(match.ended)
            store.addRound(Round(deltas: [alice.id: 20]), to: match)
            XCTAssertFalse(match.ended)
            store.undoLastRound(in: match)
            XCTAssertFalse(match.ended)
            store.undoLastRound(in: match)
            XCTAssertFalse(match.ended)
            XCTAssertTrue(match.started)
            store.addRound(Round(deltas: [alice.id: 30]), to: match)
            store.addRound(Round(deltas: [alice.id: 40]), to: match)
            XCTAssertFalse(match.ended)
            XCTAssertEqual(store.freeMatches.startedMatches, 1)
        }
        try launch { store in
            let match = try match(id, in: store)
            XCTAssertFalse(match.ended)
            XCTAssertFalse(match.archived)
            XCTAssertEqual(match.rounds.map(\.sequence), [0, 1])
            XCTAssertEqual(WinCondition.lowestTotal.engine.standings(for: match).ranked.map(\.total), [70])
            XCTAssertEqual(store.freeMatches.startedMatches, 1)
        }
    }


    func test_anExistingTallyKeepsDeletedStartsAndCountsOnlyNewlyInferredStarts() throws {
        let id = try writeV1 { context in
            let alreadyStarted = SiraSchemaV1.Match(
                game: .okey, variantId: "okey-101", roundCount: 9, mode: .players,
                storedEntrants: [], storedRounds: [], createdAt: .distantPast
            )
            alreadyStarted.started = true
            context.insert(alreadyStarted)
            let inferred = SiraSchemaV1.Match(
                game: .okey, variantId: "okey-101", roundCount: 9, mode: .players,
                storedEntrants: [], storedRounds: [SiraSchemaV1.Round()], createdAt: .distantPast
            )
            context.insert(inferred)
            // Includes four Matches deleted before this update. They must not
            // be refunded, and the already-Started Match must not cost twice.
            context.insert(SiraSchemaV1.StartedMatchTally(startedMatches: 5))
            return alreadyStarted.id
        }
        for _ in 0..<2 {
            try launch { store in
                XCTAssertEqual(store.freeMatches.startedMatches, 6)
                XCTAssertEqual(store.freeMatches.remaining, 0)
                XCTAssertTrue(try match(id, in: store).started)
            }
        }
    }

    private struct LegacyMatchIDs {
        let match: UUID
        let entrants: [UUID]
        let rounds: [UUID]
    }

    func test_allScoringFactsSeatsAndOtherVariantResultsSurviveMigration() throws {
        let ids = try writeV1 { context in
            let alice = SiraSchemaV1.Entrant(name: "Alice", sequence: 0)
            let bob = SiraSchemaV1.Entrant(name: "Bob", sequence: 2)
            let cem = SiraSchemaV1.Entrant(name: "Cem", sequence: 5)
            let first = SiraSchemaV1.Round(
                sequence: 2, deltas: [alice.id: 0, bob.id: 10, cem.id: 20],
                cifteCallers: [alice.id], okeyAtanID: alice.id
            )
            let last = SiraSchemaV1.Round(
                sequence: 6, deltas: [alice.id: 30, bob.id: 0, cem.id: 5], cifteCallers: [alice.id]
            )
            let okey101 = SiraSchemaV1.Match(
                game: .okey, variantId: "okey-101", roundCount: 2, mode: .players,
                storedEntrants: [cem, bob, alice], storedRounds: [last, first],
                createdAt: Date(timeIntervalSince1970: 1_600_000_000)
            )
            okey101.started = true
            context.insert(okey101)

            let gongaAlice = SiraSchemaV1.Entrant(name: "Alice", sequence: 1)
            let gongaBob = SiraSchemaV1.Entrant(name: "Bob", sequence: 3)
            let joiner = SiraSchemaV1.Entrant(name: "Cem", sequence: 7, arrivedMidMatch: true)
            let arrival = SiraSchemaV1.Round(
                sequence: 4, deltas: [gongaAlice.id: 120, gongaBob.id: 30],
                rejoins: [RejoinEvent(id: gongaAlice.id, to: 30)],
                joins: [JoinEvent(id: joiner.id, to: 30)]
            )
            let finish = SiraSchemaV1.Round(
                sequence: 8, deltas: [gongaAlice.id: 0, gongaBob.id: 30, joiner.id: 20],
                okeyAtanID: gongaAlice.id
            )
            let gonga = SiraSchemaV1.Match(
                game: .gonga, variantId: "gonga-standard", limit: 50, mode: .players,
                storedEntrants: [joiner, gongaBob, gongaAlice], storedRounds: [finish, arrival], archived: true
            )
            gonga.started = true
            context.insert(gonga)

            let red = SiraSchemaV1.Entrant(name: "Red", sequence: 4)
            let blue = SiraSchemaV1.Entrant(name: "Blue", sequence: 9)
            let loss = SiraSchemaV1.Round(
                sequence: 3, cifteCallers: [red.id, blue.id], okeyAtanID: blue.id,
                losingEntrantID: red.id, gostergeFinderID: blue.id
            )
            let okey = SiraSchemaV1.Match(
                game: .okey, variantId: "okey-standard", startingScore: 7, mode: .teams,
                storedEntrants: [blue, red], storedRounds: [loss]
            )
            okey.started = true
            context.insert(okey)
            context.insert(SiraSchemaV1.StartedMatchTally(startedMatches: 6))
            context.insert(SiraSchemaV1.UnlockCache(hasSeenVerifiedUnlock: true))
            return (
                okey101: LegacyMatchIDs(match: okey101.id, entrants: [alice.id, bob.id, cem.id], rounds: [first.id, last.id]),
                gonga: LegacyMatchIDs(match: gonga.id, entrants: [gongaAlice.id, gongaBob.id, joiner.id], rounds: [arrival.id, finish.id]),
                okey: LegacyMatchIDs(match: okey.id, entrants: [red.id, blue.id], rounds: [loss.id])
            )
        }

        for _ in 0..<2 {
            try launch { store in
                for original in [ids.okey101, ids.gonga, ids.okey] {
                    let reloaded = try match(original.match, in: store)
                    XCTAssertEqual(reloaded.entrants.map(\.id), original.entrants)
                    XCTAssertEqual(reloaded.rounds.map(\.id), original.rounds)
                }
                let okey101 = try match(ids.okey101.match, in: store)
                let a = ids.okey101.entrants[0], b = ids.okey101.entrants[1], c = ids.okey101.entrants[2]
                XCTAssertEqual(okey101.entrants.map(\.sequence), [0, 2, 5])
                XCTAssertEqual(okey101.rounds.map(\.sequence), [2, 6])
                XCTAssertEqual(okey101.rounds.map(\.deltas), [[a: 0, b: 10, c: 20], [a: 30, b: 0, c: 5]])
                XCTAssertEqual(okey101.rounds.map(\.cifteCallers), [Set([a]), Set([a])])
                XCTAssertEqual(okey101.rounds.map(\.okeyAtanID), [a, nil])
                XCTAssertTrue(okey101.ended)
                XCTAssertEqual(okey101.createdAt, Date(timeIntervalSince1970: 1_600_000_000))
                let lowest = WinCondition.lowestTotal.engine.standings(for: okey101)
                XCTAssertEqual(lowest.ranked.map(\.name), ["Bob", "Alice", "Cem"])
                XCTAssertEqual(lowest.ranked.map(\.total), [40, 60, 85])
                XCTAssertEqual(lowest.result, "Bob wins!")

                let gonga = try match(ids.gonga.match, in: store)
                XCTAssertEqual(gonga.variantNumber, 50)
                XCTAssertEqual(gonga.entrants.map(\.sequence), [1, 3, 7])
                XCTAssertEqual(gonga.entrants.map(\.arrivedMidMatch), [false, false, true])
                XCTAssertEqual(gonga.rounds.map(\.sequence), [4, 8])
                XCTAssertEqual(gonga.rounds[0].rejoins, [RejoinEvent(id: ids.gonga.entrants[0], to: 30)])
                XCTAssertEqual(gonga.rounds[0].joins, [JoinEvent(id: ids.gonga.entrants[2], to: 30)])
                XCTAssertTrue(gonga.archived)
                XCTAssertFalse(gonga.ended)
                let survival = WinCondition.survival.engine.standings(for: gonga)
                XCTAssertEqual(survival.ranked.map(\.total), [30, 70, 90])
                XCTAssertEqual(survival.result, "Alice wins!")

                let okey = try match(ids.okey.match, in: store)
                XCTAssertEqual(okey.mode, .teams)
                XCTAssertEqual(okey.variantNumber, 7)
                XCTAssertEqual(okey.entrants.map(\.sequence), [4, 9])
                XCTAssertEqual(okey.rounds[0].losingEntrantID, ids.okey.entrants[0])
                XCTAssertEqual(okey.rounds[0].gostergeFinderID, ids.okey.entrants[1])
                XCTAssertEqual(okey.rounds[0].okeyAtanID, ids.okey.entrants[1])
                XCTAssertEqual(okey.rounds[0].cifteCallers, Set(ids.okey.entrants))
                XCTAssertFalse(okey.ended)
                let elimination = WinCondition.elimination.engine.standings(for: okey)
                XCTAssertEqual(elimination.ranked.map(\.total), [7, -2])
                XCTAssertEqual(elimination.result, "Blue wins!")
                XCTAssertEqual(store.freeMatches.startedMatches, 6)
                XCTAssertTrue(store.hasSeenUnlock)
            }
        }
    }

}
