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

    func test_104RoundScoresheetSurvivesReopeningEndResumeFurtherScoringAndUndoToZero() throws {
        let facts = try launch { store in
            let alice = Entrant(name: "Alice"), bob = Entrant(name: "Bob")
            let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: [alice, bob])
            store.add(match)
            for _ in 0..<104 {
                store.addRound(Round(deltas: [alice.id: 0, bob.id: 10], cifteCallers: [bob.id],
                                     okeyAtanID: alice.id), to: match)
            }
            let sheet = Scoresheet(match: match, engine: LowestTotalEngine())
            XCTAssertEqual(sheet.rows.count, 104)
            XCTAssertEqual(sheet.totals.ranked.map(\.total), [0, 4160])
            return (match.id, alice.id, bob.id, sheet.rows.map(\.id))
        }
        try launch { store in
            let stored = try match(facts.0, in: store)
            let sheet = Scoresheet(match: stored, engine: LowestTotalEngine())
            XCTAssertEqual(stored.entrants.map(\.id), [facts.1, facts.2])
            XCTAssertEqual(stored.entrants.map(\.sequence), [0, 1])
            XCTAssertEqual(stored.rounds.map(\.sequence), Array(0..<104))
            XCTAssertEqual(sheet.rows.map(\.id), facts.3)
            XCTAssertEqual(sheet.rows.map(\.roundNumber), Array(1...104))
            XCTAssertTrue(sheet.rows.allSatisfy { $0.deltas == [facts.1: 0, facts.2: 40] })
            XCTAssertTrue(stored.rounds.allSatisfy {
                $0.deltas == [facts.1: 0, facts.2: 10] && $0.cifteCallers == [facts.2]
                    && $0.okeyAtanID == facts.1 && $0.joins.isEmpty && $0.rejoins.isEmpty
            })
            XCTAssertEqual(sheet.totals, LowestTotalEngine().standings(for: stored))
            XCTAssertEqual(sheet.totals.ranked.map(\.total), [0, 4160])
            XCTAssertTrue(store.end(stored))
            XCTAssertTrue(stored.isReadOnly)
        }
        try launch { store in
            let stored = try match(facts.0, in: store)
            XCTAssertTrue(stored.isReadOnly)
            XCTAssertEqual(Scoresheet(match: stored, engine: LowestTotalEngine()).rows.map(\.id), facts.3)
            XCTAssertEqual(LowestTotalEngine().standings(for: stored).result, "Alice wins!")
            XCTAssertTrue(store.resume(stored))
            store.addRound(Round(deltas: [facts.1: 15, facts.2: 0]), to: stored)
            let continued = Scoresheet(match: stored, engine: LowestTotalEngine())
            XCTAssertEqual(continued.rows.last?.roundNumber, 105)
            XCTAssertEqual(continued.totals.ranked.map(\.total), [15, 4160])
            store.undoLastRound(in: stored)
            XCTAssertEqual(Scoresheet(match: stored, engine: LowestTotalEngine()).rows.map(\.id), facts.3)
            for _ in 0..<104 { store.undoLastRound(in: stored) }
            XCTAssertTrue(Scoresheet(match: stored, engine: LowestTotalEngine()).rows.isEmpty)
            XCTAssertEqual(LowestTotalEngine().standings(for: stored).ranked.map(\.total), [0, 0])
            XCTAssertFalse(stored.canEnd)
            store.addRound(Round(deltas: [facts.1: 0, facts.2: 5]), to: stored)
            XCTAssertEqual(Scoresheet(match: stored, engine: LowestTotalEngine()).rows.map(\.roundNumber), [1])
            XCTAssertEqual(store.freeMatches.startedMatches, 1)
        }
        try launch { store in
            let stored = try match(facts.0, in: store)
            XCTAssertFalse(stored.isReadOnly)
            XCTAssertEqual(Scoresheet(match: stored, engine: LowestTotalEngine()).totals.ranked.map(\.total), [0, 5])
            XCTAssertEqual(store.freeMatches.startedMatches, 1)
        }
    }

    func test_resumedHistoryAndFurtherScoresSurviveRelaunchAndCanEndAgain() throws {
        let facts = try launch { store in
            let alice = Entrant(name: "Alice")
            let bob = Entrant(name: "Bob")
            let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: [alice, bob],
                              createdAt: Date(timeIntervalSince1970: 1_700_000_000))
            let round = Round(deltas: [alice.id: 10, bob.id: 20], cifteCallers: [bob.id], okeyAtanID: alice.id)
            store.add(match)
            store.addRound(round, to: match)
            store.end(match)
            store.resume(match)
            store.rename(alice, to: "Alicia")
            store.addRound(Round(deltas: [alice.id: 70, bob.id: 0]), to: match)
            return (match.id, round.id, alice.id, bob.id)
        }
        try launch { store in
            let stored = try match(facts.0, in: store)
            XCTAssertFalse(stored.isReadOnly)
            XCTAssertFalse(stored.archived)
            XCTAssertTrue(stored.started)
            XCTAssertEqual(stored.createdAt, Date(timeIntervalSince1970: 1_700_000_000))
            XCTAssertEqual(stored.entrants.map(\.id), [facts.2, facts.3])
            XCTAssertEqual(stored.entrants.map(\.name), ["Alicia", "Bob"])
            XCTAssertEqual(stored.entrants.map(\.sequence), [0, 1])
            XCTAssertEqual(stored.rounds.map(\.sequence), [0, 1])
            XCTAssertEqual(stored.rounds[0].id, facts.1)
            XCTAssertEqual(stored.rounds[0].deltas, [facts.2: 10, facts.3: 20])
            XCTAssertEqual(stored.rounds[0].cifteCallers, [facts.3])
            XCTAssertEqual(stored.rounds[0].okeyAtanID, facts.2)
            XCTAssertEqual(LowestTotalEngine().standings(for: stored).ranked.map(\.total), [80, 90])
            XCTAssertTrue(store.end(stored))
            XCTAssertEqual(LowestTotalEngine().standings(for: stored).result, "Bob wins!")
            XCTAssertEqual(store.freeMatches.startedMatches, 1)
        }
        try launch { store in
            let stored = try match(facts.0, in: store)
            XCTAssertTrue(stored.isReadOnly)
            XCTAssertTrue(stored.archived)
            XCTAssertEqual(LowestTotalEngine().standings(for: stored).result, "Bob wins!")
            XCTAssertEqual(store.freeMatches.startedMatches, 1)
        }
    }

    func test_failedResumeSaveKeepsBothVisibleStatesAndSurfacesTheExistingFailure() {
        var failing = false
        let store = MatchStore { context in
            if failing { throw DiskFull() }
            try context.save()
        }
        let match = Match(game: .okey, variant: .okey101, mode: .players,
                          entrants: [Entrant(name: "Alice")], rounds: [Round()])
        store.add(match)
        store.end(match)
        failing = true

        XCTAssertTrue(store.resume(match))

        XCTAssertNotNil(store.saveFailure)
        XCTAssertFalse(match.ended)
        XCTAssertFalse(match.archived)
        XCTAssertTrue(match.started)
        XCTAssertEqual(store.freeMatches.startedMatches, 1)
    }

    func test_endedArchivedResultAndReadOnlyHistorySurviveTwoReopens() throws {
        let id = try launch { store -> Match.ID in
            let alice = Entrant(name: "Alice")
            let bob = Entrant(name: "Bob")
            let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: [alice, bob],
                              createdAt: Date(timeIntervalSince1970: 1_700_000_000))
            store.add(match)
            store.addRound(Round(deltas: [alice.id: 20, bob.id: 10], okeyAtanID: bob.id), to: match)
            XCTAssertTrue(store.end(match))
            return match.id
        }
        for _ in 0..<2 {
            try launch { store in
                let stored = try match(id, in: store)
                let alice = try entrant("Alice", in: stored)
                XCTAssertTrue([stored].scorableMatch(id) === stored)
                XCTAssertTrue(stored.ended)
                XCTAssertTrue(stored.archived)
                XCTAssertTrue(stored.started)
                XCTAssertEqual(stored.createdAt, Date(timeIntervalSince1970: 1_700_000_000))
                XCTAssertEqual(stored.entrants.map(\.sequence), [0, 1])
                XCTAssertEqual(stored.rounds.map(\.sequence), [0])
                XCTAssertEqual(LowestTotalEngine().standings(for: stored).ranked.map(\.total), [20, 40])
                XCTAssertEqual(HomeCard(match: stored, variant: .okey101).summaryText, "Bob wins!")
                store.addRound(Round(deltas: [alice.id: 200]), to: stored)
                store.undoLastRound(in: stored)
                store.rename(alice, to: "Changed")
                store.restore(stored)
                XCTAssertEqual(stored.entrants.map(\.name), ["Alice", "Bob"])
                XCTAssertEqual(stored.rounds.count, 1)
                XCTAssertTrue(stored.archived)
                XCTAssertEqual(store.freeMatches.startedMatches, 1)
            }
        }
    }

    func test_failedEndSaveKeepsBothVisibleStatesAndSurfacesTheExistingFailure() throws {
        var failing = false
        let store = MatchStore { context in
            if failing { throw DiskFull() }
            try context.save()
        }
        let match = Match(game: .okey, variant: .okey101, mode: .players,
                          entrants: [Entrant(name: "Alice")], rounds: [Round()])
        store.add(match)
        failing = true
        XCTAssertTrue(store.end(match))
        XCTAssertNotNil(store.saveFailure)
        XCTAssertTrue(match.ended)
        XCTAssertTrue(match.archived)
        XCTAssertTrue(match.isReadOnly)
        XCTAssertEqual(store.freeMatches.startedMatches, 1)
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
                number: 21,
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
                variant: .gongaStandard,
                number: 101,
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

    /// A name fixed mid-Match is the Match the player comes back to — and the
    /// seat it was fixed on does not move with it, so the renamed Entrant is
    /// still sitting where they were.
    func test_aRenamedEntrantComesBackUnderTheirNewNameAndOnTheirOwnSeat() throws {
        let matchID = try launch { store -> Match.ID in
            let match = Match(
                game: .gonga,
                variant: .gongaStandard,
                number: 101,
                mode: .players,
                entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")]
            )
            store.add(match)
            store.rename(try entrant("Bob", in: match), to: "Bora")
            return match.id
        }

        try launch { store in
            let reloaded = try match(matchID, in: store)

            XCTAssertEqual(reloaded.entrants.map(\.name), ["Alice", "Bora"])
            XCTAssertEqual(reloaded.entrants.map(\.sequence), [0, 1])
        }
    }

    // MARK: - Round order

    /// Enough Rounds that an accidental reordering shows up, rather than the
    /// two or three a wrong order has an even chance of surviving.
    func test_roundsComeBackInTheOrderTheyWereEntered() throws {
        let entered = [7, 13, 21, 34, 55, 89, 3]
        let matchID = try launch { store -> Match.ID in
            let alice = Entrant(name: "Alice")
            let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice])
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

    /// Someone who arrived partway through comes back as someone who arrived
    /// partway through: the Entrant with the seat they took, and the arrival
    /// itself, on the Round it was recorded against. Lose either half and the
    /// reload has a fourth player who has been there all along on a total
    /// nobody can account for.
    func test_anEntrantAddedMidMatchSurvivesWithTheirSeatAndTheirArrival() throws {
        let (matchID, before) = try launch { store -> (Match.ID, Standings) in
            let alice = Entrant(name: "Alice")
            let bob = Entrant(name: "Bob")
            let match = Match(
                game: .gonga,
                variant: .gongaStandard,
                number: 101,
                mode: .players,
                entrants: [alice, bob]
            )
            store.add(match)
            store.addRound(Round(deltas: [alice.id: 40, bob.id: 30]), to: match)
            store.addRound(Round(deltas: [alice.id: 21, bob.id: 15]), to: match)
            store.addEntrant(Entrant(name: "Carol"), to: match, joiningOn: 61)
            return (match.id, WinCondition.survival.engine.standings(for: match))
        }

        try launch { store in
            let reloaded = try match(matchID, in: store)
            let carol = try entrant("Carol", in: reloaded)

            XCTAssertEqual(reloaded.entrants.map(\.name), ["Alice", "Bob", "Carol"])
            XCTAssertEqual(carol.sequence, 2)
            XCTAssertTrue(carol.arrivedMidMatch)
            XCTAssertEqual(reloaded.entrants.filter(\.arrivedMidMatch).map(\.name), ["Carol"])
            XCTAssertEqual(reloaded.rounds.map(\.joins), [[], [JoinEvent(id: carol.id, to: 61)]])
            XCTAssertEqual(WinCondition.survival.engine.standings(for: reloaded), before)
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
                variant: .gongaStandard,
                number: 101,
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

    /// Declining a Rejoin writes nothing, which is the point: being Out is what
    /// the Round that busted the Entrant already says, and that Round was saved
    /// as it was entered. This pins the behaviour the absence relies on, so
    /// nobody later "fixes" a decline into a stored fact.
    func test_aDeclinedRejoinLeavesTheEntrantOutAfterAReload() throws {
        let matchID = try launch { store -> Match.ID in
            let alice = Entrant(name: "Alice")
            let bob = Entrant(name: "Bob")
            let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice, bob])
            store.add(match)
            store.addRound(Round(deltas: [alice.id: 110, bob.id: 40]), to: match)
            // Alice is offered a Rejoin here and declines: nothing is recorded.
            return match.id
        }

        try launch { store in
            let after = WinCondition.survival.engine.standings(for: try match(matchID, in: store))

            XCTAssertEqual(after.ranked.filter(\.isOut).map(\.name), ["Alice"])
        }
    }

    func test_eliminationStandingsAreUnchangedByAReload_includingAMatchThatIsOver() throws {
        let (matchID, before) = try launch { store -> (Match.ID, Standings) in
            let kirmizi = Entrant(name: "Kırmızı")
            let mavi = Entrant(name: "Mavi")
            let match = Match(game: .okey, variant: .okeyStandard, number: 21, mode: .teams, entrants: [kirmizi, mavi])
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

    func test_lowestTotalStandingsAreUnchangedByAReload() throws {
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
            return (match.id, WinCondition.lowestTotal.engine.standings(for: match))
        }

        try launch { store in
            let after = WinCondition.lowestTotal.engine.standings(for: try match(matchID, in: store))

            XCTAssertEqual(after, before)
        }
    }

    func test_targetFreeOkey101ScoresAndRoutesAfterAReload() throws {
        let matchID = try launch { store -> Match.ID in
            let alice = Entrant(name: "Alice")
            let bob = Entrant(name: "Bob")
            let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: [alice, bob])
            store.add(match)
            for _ in 0..<51 {
                store.addRound(Round(deltas: [alice.id: 10, bob.id: 0]), to: match)
            }
            return match.id
        }

        try launch { store in
            let reloaded = try match(matchID, in: store)
            XCTAssertNil(reloaded.variantNumber)
            XCTAssertNil(reloaded.numberPhrase)
            XCTAssertTrue([reloaded].scorableMatch(matchID) === reloaded)
            XCTAssertEqual(reloaded.rounds.count, 51)
            let standings = WinCondition.lowestTotal.engine.standings(for: reloaded)
            XCTAssertEqual(standings.ranked.map(\.total), [0, 510])
            XCTAssertFalse(standings.isOver)
            XCTAssertNil(standings.result)
            XCTAssertTrue(reloaded.started)
            XCTAssertEqual(store.freeMatches.startedMatches, 1)
        }
    }

    // MARK: - Undo after a reload

    func test_undoAfterAReloadRemovesTheLastRoundAndNothingElse() throws {
        let matchID = try launch { store -> Match.ID in
            let alice = Entrant(name: "Alice")
            let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice])
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

    // MARK: - Deleting

    /// Deleted has to mean deleted across launches too — a Match that comes
    /// back after a relaunch was never deleted, it was hidden, and this app
    /// already has a word for hidden.
    func test_aDeletedMatchDoesNotComeBack() throws {
        let deleted = UUID()
        let kept = UUID()
        // The Entrant's id and not the Entrant: an object belonging to the
        // first launch's store is no use to the third's.
        let alice = UUID()

        try launch { store in
            store.add(
                Match(id: deleted, game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Bob")])
            )
            let keptMatch = Match(
                id: kept,
                game: .gonga,
                variant: .gongaStandard,
                number: 101,
                mode: .players,
                entrants: [Entrant(id: alice, name: "Alice")]
            )
            store.add(keptMatch)
            store.addRound(Round(deltas: [alice: 10]), to: keptMatch)
            store.addRound(Round(deltas: [alice: 20]), to: keptMatch)
        }

        try launch { store in
            store.delete(try self.match(deleted, in: store))
        }

        try launch { store in
            XCTAssertEqual(try store.context.fetch(FetchDescriptor<Match>()).map(\.id), [kept])
            // The surviving Match's history is untouched by the deletion, which
            // is what makes removing a mis-tap safe to offer at all.
            let survivor = try self.match(kept, in: store)
            XCTAssertEqual(survivor.rounds.map { $0.deltas[alice] }, [10, 20])
            XCTAssertEqual(survivor.entrants.map(\.name), ["Alice"])
        }
    }

    /// Nothing the deleted Match owned outlives it — an orphaned Round is
    /// invisible to the player and still on their device.
    func test_aDeletedMatchLeavesNoRoundsOrEntrantsBehind() throws {
        let id = UUID()
        let alice = Entrant(name: "Alice")

        try launch { store in
            let match = Match(id: id, game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice])
            store.add(match)
            store.addRound(Round(deltas: [alice.id: 10]), to: match)
        }

        try launch { store in
            store.delete(try self.match(id, in: store))
        }

        try launch { store in
            XCTAssertEqual(try store.context.fetch(FetchDescriptor<Round>()).count, 0)
            XCTAssertEqual(try store.context.fetch(FetchDescriptor<Entrant>()).count, 0)
        }
    }

    // MARK: - Un-Started Matches, at launch

    /// A Match set up and never scored is unreachable once Home stops listing
    /// it, so it is discarded rather than left on the device forever. Nothing
    /// is lost: a Match with no Rounds has no tally, only a Variant choice and
    /// some Entrant names.
    func test_anUnStartedMatchIsGoneAfterTheNextLaunch() throws {
        let abandoned = UUID()
        let played = UUID()
        let alice = UUID()

        try launch { store in
            store.add(
                Match(id: abandoned, game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Bob")])
            )
            let scored = Match(
                id: played,
                game: .gonga,
                variant: .gongaStandard,
                number: 101,
                mode: .players,
                entrants: [Entrant(id: alice, name: "Alice")]
            )
            store.add(scored)
            store.addRound(Round(deltas: [alice: 10]), to: scored)
        }

        try launch { store in
            store.discardUnstartedMatches()
        }

        try launch { store in
            XCTAssertEqual(try store.context.fetch(FetchDescriptor<Match>()).map(\.id), [played])
            // The abandoned Match takes its Entrant with it rather than
            // leaving one behind with no Match to belong to.
            XCTAssertEqual(try store.context.fetch(FetchDescriptor<Entrant>()).map(\.id), [alice])
        }
    }

    /// The launch path run twice over the same database — a scene re-entered,
    /// or the sweep called from somewhere it should not have been. What an
    /// earlier launch abandoned goes once; the played Match and the Match this
    /// launch is setting up both survive both calls.
    func test_sweepingTwiceOverOneStoreLeavesTheLiveMatchAlone() throws {
        let abandoned = UUID()
        let played = UUID()
        let live = UUID()
        let alice = UUID()

        try launch { store in
            store.add(
                Match(id: abandoned, game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Bob")])
            )
            let scored = Match(
                id: played,
                game: .gonga,
                variant: .gongaStandard,
                number: 101,
                mode: .players,
                entrants: [Entrant(id: alice, name: "Alice")]
            )
            store.add(scored)
            store.addRound(Round(deltas: [alice: 10]), to: scored)
        }

        try launch { store in
            store.discardUnstartedMatches()
            // Setup's Match, saved and not yet scored, arriving between the two
            // sweeps exactly as it would between two evaluations of a view.
            store.add(
                Match(id: live, game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Cem")])
            )
            store.discardUnstartedMatches()

            XCTAssertEqual(
                Set(try store.context.fetch(FetchDescriptor<Match>()).map(\.id)),
                [played, live]
            )
        }

        // And on the disk, not only in the store that swept: the live Match is
        // still there to be played on.
        try launch { store in
            XCTAssertEqual(
                Set(try store.context.fetch(FetchDescriptor<Match>()).map(\.id)),
                [played, live]
            )
        }
    }

    /// The Match whose only Round was undone is Started, and stays. This is the
    /// case that would be swept away by a launch that discarded Matches with no
    /// Rounds rather than Matches that were never Started.
    func test_aStartedMatchWithNoRoundsLeftSurvivesTheNextLaunch() throws {
        let id = UUID()
        let alice = Entrant(name: "Alice")

        try launch { store in
            let match = Match(id: id, game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice])
            store.add(match)
            store.addRound(Round(deltas: [alice.id: 10]), to: match)
            store.undoLastRound(in: match)
        }

        try launch { store in
            store.discardUnstartedMatches()
        }

        try launch { store in
            let survivor = try self.match(id, in: store)
            XCTAssertTrue(survivor.rounds.isEmpty)
            XCTAssertTrue(survivor.started)
        }
    }

    /// A Match written before the Started flag existed reads back as
    /// un-Started, because that is what the default says. Its Rounds say
    /// otherwise, and they are older than the flag — so it is Started at
    /// launch rather than discarded as an intention.
    func test_aMatchScoredBeforeTheFlagExistedIsStartedRatherThanDiscarded() throws {
        let id = UUID()
        // The Entrant's id and not the Entrant: an object belonging to the
        // first launch's store is no use to the third's.
        let alice = UUID()

        try launch { store in
            let match = Match(id: id, game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(id: alice, name: "Alice")])
            store.add(match)
            store.addRound(Round(deltas: [alice: 10]), to: match)
            // What the store held before this release: Rounds on the Match,
            // and no flag to have written. Written out here rather than left
            // to autosave, which this launch does not live long enough for.
            match.started = false
            try store.context.save()
        }

        try launch { store in
            store.discardUnstartedMatches()
        }

        try launch { store in
            let survivor = try self.match(id, in: store)
            XCTAssertTrue(survivor.started)
            XCTAssertEqual(survivor.rounds.map { $0.deltas[alice] }, [10])
        }
    }

    // MARK: - Free games

    /// The reinstall case, and the first launch with it: a store over a
    /// location holding nothing has three free games. Deliberate — the tally
    /// lives in the app's own database and goes when the app goes, rather than
    /// being hidden somewhere that survives being deleted.
    func test_aStoreOverAFreshLocationHasThreeFreeGames() throws {
        let remaining = try launch { $0.freeMatches.remaining }

        XCTAssertEqual(remaining, 3)
    }

    func test_theFreeGamesSpentAreStillSpentAtTheNextLaunch() throws {
        try launch { store in
            for _ in 0..<2 {
                let alice = Entrant(name: "Alice")
                let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice])
                store.add(match)
                store.addRound(Round(deltas: [alice.id: 10]), to: match)
            }
        }

        XCTAssertEqual(try launch { $0.freeMatches.remaining }, 1)
    }

    /// The case a count taken by fetching Started Matches would get wrong.
    /// Deleting the games does not unplay them, so the next launch opens on
    /// an empty Home with two free games left rather than three.
    func test_deletingAPlayedMatchDoesNotGiveItsFreeGameBackAtTheNextLaunch() throws {
        try launch { store in
            let alice = Entrant(name: "Alice")
            let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice])
            store.add(match)
            store.addRound(Round(deltas: [alice.id: 10]), to: match)
            store.delete(match)
        }

        try launch { store in
            XCTAssertEqual(store.freeMatches.remaining, 2)
            XCTAssertEqual(try store.context.fetch(FetchDescriptor<Match>()).count, 0)
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
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice])
        store.add(match)

        store.addRound(Round(deltas: [alice.id: 40]), to: match)

        XCTAssertNotNil(store.saveFailure)
        XCTAssertEqual(match.rounds.map { $0.deltas[alice.id] }, [40])
        XCTAssertEqual(
            WinCondition.survival.engine.standings(for: match).ranked.map(\.total),
            [40]
        )
    }

    /// A deletion is a change like any other, and fails like one: the Match is
    /// gone from Home, the player is told it could not be written, and the
    /// next save that succeeds takes the deletion with it. The one thing that
    /// must not happen is silence.
    func test_aDeletionThatCannotBeSavedIsSurfacedAndStillStands() throws {
        var failing = false
        let store = MatchStore { context in
            if failing { throw DiskFull() }
            try context.save()
        }
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Alice")])
        store.add(match)

        failing = true
        store.delete(match)

        XCTAssertNotNil(store.saveFailure)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Match>()).count, 0)

        failing = false
        store.add(Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Bob")]))

        XCTAssertNil(store.saveFailure)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Match>()).map(\.entrants.first?.name), ["Bob"])
    }

    func test_aSaveThatSucceedsClearsAnEarlierFailure() throws {
        var failing = true
        let store = MatchStore { context in
            if failing { throw DiskFull() }
            try context.save()
        }
        let alice = Entrant(name: "Alice")
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice])
        store.add(match)
        XCTAssertNotNil(store.saveFailure)

        failing = false
        store.addRound(Round(deltas: [alice.id: 40]), to: match)

        XCTAssertNil(store.saveFailure)
    }

    /// A free game spent on screen and not on the disk is the meter's version
    /// of the same failure, and it behaves the same way: the count stands, the
    /// player is told, and the next save that succeeds writes it out.
    ///
    /// Following `test_aDeletionThatCannotBeSavedIsSurfacedAndStillStands` —
    /// the store is built healthy so the Match can be added, and only then
    /// made to fail, because a Round is what spends the free game and there
    /// has to be a Match for it to land on.
    func test_aFreeGameSpentWhenTheSaveFailsIsSurfacedAndStillStands() throws {
        var failing = false
        let store = MatchStore { context in
            if failing { throw DiskFull() }
            try context.save()
        }
        let alice = Entrant(name: "Alice")
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice])
        store.add(match)

        failing = true
        store.addRound(Round(deltas: [alice.id: 40]), to: match)

        XCTAssertNotNil(store.saveFailure)
        XCTAssertEqual(store.freeMatches.remaining, 2)

        failing = false
        store.addRound(Round(deltas: [alice.id: 10]), to: match)

        XCTAssertNil(store.saveFailure)
        XCTAssertEqual(store.freeMatches.remaining, 2)
    }

    func test_acknowledgingASaveFailureLeavesTheChangeInPlace() throws {
        let store = MatchStore { _ in throw DiskFull() }
        let alice = Entrant(name: "Alice")
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [alice])
        store.add(match)

        store.acknowledgeSaveFailure()

        XCTAssertNil(store.saveFailure)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Match>()).map(\.id), [match.id])
    }
}

/// The save failure worth designing for: the device has no room left.
private struct DiskFull: Error {}
