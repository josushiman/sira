import XCTest
import SwiftData
@testable import sira

final class MatchStoreTests: XCTestCase {
    func test_resumeKeepsTheSameHistoryAndAllowsCorrectionAndReendingWhileLocked() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let bob = Entrant(name: "Bob")
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let match = Match(game: .okey, variant: .okey101, mode: .players,
                          entrants: [alice, bob], createdAt: date)
        let id = match.id
        store.add(match)
        let round = Round(deltas: [alice.id: 10, bob.id: 20], cifteCallers: [bob.id], okeyAtanID: alice.id)
        store.addRound(round, to: match)
        for _ in 0..<2 {
            let other = gongaMatch(entrants: [Entrant(name: "Other")])
            store.add(other)
            store.addRound(Round(), to: other)
        }
        XCTAssertTrue(GameAccess.resolved(freeMatches: store.freeMatches, isUnlocked: false).isLocked)
        XCTAssertTrue(store.end(match))

        XCTAssertTrue(store.resume(match))

        XCTAssertEqual(match.id, id)
        XCTAssertEqual(match.createdAt, date)
        XCTAssertFalse(match.ended)
        XCTAssertFalse(match.archived)
        XCTAssertTrue(match.started)
        XCTAssertEqual(match.entrants.map(\.id), [alice.id, bob.id])
        XCTAssertEqual(match.entrants.map(\.sequence), [0, 1])
        XCTAssertEqual(match.rounds.map(\.id), [round.id])
        XCTAssertEqual(match.rounds.map(\.sequence), [0])
        XCTAssertEqual(round.deltas, [alice.id: 10, bob.id: 20])
        XCTAssertEqual(round.cifteCallers, [bob.id])
        XCTAssertEqual(round.okeyAtanID, alice.id)
        XCTAssertNil(LowestTotalEngine().standings(for: match).result)
        XCTAssertEqual(LowestTotalEngine().standings(for: match).ranked.map(\.total), [20, 80])
        XCTAssertTrue(MatchFilter.active.includes(match))
        XCTAssertFalse(MatchFilter.archived.includes(match))
        store.rename(alice, to: "Alicia")
        store.undoLastRound(in: match)
        XCTAssertTrue(match.started)
        XCTAssertTrue(match.rounds.isEmpty)
        XCTAssertFalse(match.canEnd)
        XCTAssertFalse(store.end(match))
        store.addRound(Round(deltas: [alice.id: 30, bob.id: 10]), to: match)
        XCTAssertTrue(store.end(match))
        XCTAssertEqual(LowestTotalEngine().standings(for: match).result, "Bob wins!")
        XCTAssertTrue(store.resume(match))
        store.addRound(Round(deltas: [alice.id: 0, bob.id: 40]), to: match)
        XCTAssertTrue(store.end(match))
        XCTAssertEqual(LowestTotalEngine().standings(for: match).result, "Alicia wins!")
        XCTAssertEqual(store.freeMatches.startedMatches, 3)
        XCTAssertEqual(try storedMatches(in: store).count, 3)
    }

    func test_liveArchiveAndRestoreRemainVisibilityOnlyAndResumeRequiresAnEndedOkey101() {
        let store = MatchStore()
        for variant in [Variant.okey101, .gongaStandard, .okeyStandard] {
            let match = Match(game: variant == .gongaStandard ? .gonga : .okey, variant: variant,
                              number: 101, mode: variant.entrantMode,
                              entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")])
            store.add(match)
            store.addRound(Round(), to: match)
            store.archive(match)
            XCTAssertFalse(store.resume(match))
            XCTAssertTrue(match.archived)
            XCTAssertFalse(match.ended)
            store.addRound(Round(), to: match)
            XCTAssertEqual(match.rounds.count, 2)
            store.restore(match)
            XCTAssertFalse(match.archived)
            XCTAssertFalse(match.ended)
            XCTAssertEqual(match.rounds.count, 2)
        }
        XCTAssertEqual(store.freeMatches.startedMatches, 3)
    }

    func test_endingOkey101DeclaresAndArchivesTheCurrentResultWithoutSpendingAnotherStart() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let bob = Entrant(name: "Bob")
        let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: [alice, bob])
        store.add(match)
        store.addRound(Round(deltas: [alice.id: 10, bob.id: 20]), to: match)

        XCTAssertTrue(store.end(match))

        XCTAssertTrue(match.ended)
        XCTAssertTrue(match.archived)
        XCTAssertTrue(match.started)
        XCTAssertEqual(store.freeMatches.startedMatches, 1)
        XCTAssertEqual(LowestTotalEngine().standings(for: match).result, "Alice wins!")
        XCTAssertEqual(MatchFilter.active.apply(to: [match]).count, 0)
        XCTAssertEqual(MatchFilter.archived.apply(to: [match]).map(\.id), [match.id])
        XCTAssertEqual(MatchFilter.all.apply(to: [match]).map(\.id), [match.id])
        XCTAssertTrue([match].scorableMatch(match.id) === match)
    }

    func test_endedOkey101RefusesScoresUndoRenameAndRestoreAtOrdinaryMutationPaths() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let bob = Entrant(name: "Bob")
        let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: [alice, bob])
        store.add(match)
        store.addRound(Round(deltas: [alice.id: 10, bob.id: 20]), to: match)
        store.end(match)
        let result = LowestTotalEngine().standings(for: match)

        store.addRound(Round(deltas: [alice.id: 200, bob.id: 0]), to: match)
        store.undoLastRound(in: match)
        store.rename(alice, to: "Changed")
        store.addEntrant(Entrant(name: "Uninvited"), to: match, joiningOn: 0)
        store.recordRejoin(RejoinEvent(id: bob.id, to: 0), in: match)
        store.restore(match)
        // Domain callers cannot bypass the same protections either.
        match.addRound(Round(deltas: [alice.id: 500]))
        match.addEntrant(Entrant(name: "Also uninvited"), joiningOn: 0)
        match.recordRejoin(RejoinEvent(id: alice.id, to: 0))
        XCTAssertNil(match.undoLastRound())
        match.restore()

        XCTAssertEqual(LowestTotalEngine().standings(for: match), result)
        XCTAssertEqual(match.rounds.count, 1)
        XCTAssertEqual(match.entrants.map(\.name), ["Alice", "Bob"])
        XCTAssertTrue(match.rounds[0].rejoins.isEmpty)
        XCTAssertTrue(match.archived)
        XCTAssertEqual(store.freeMatches.startedMatches, 1)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Round>()).count, 1)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Entrant>()).count, 2)
    }

    func test_prospectiveEndNamesEveryTiedWinnerWithoutChangingTheLiveMatch() throws {
        let store = MatchStore()
        let entrants = ["Alice", "Bob", "Cem", "Dila"].map { Entrant(name: $0) }
        let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: entrants)
        store.add(match)
        store.addRound(Round(deltas: Dictionary(uniqueKeysWithValues: entrants.map { ($0.id, 20) })), to: match)
        store.archive(match)
        let preview = try XCTUnwrap(match.prospectiveEndResult)

        XCTAssertEqual(preview.winners.map(\.name), ["Alice", "Bob", "Cem", "Dila"])
        XCTAssertEqual(preview.total, 20)
        XCTAssertEqual(preview.summary, "Alice, Bob, Cem & Dila · 20")
        XCTAssertFalse(match.ended)
        XCTAssertTrue(match.archived)
        XCTAssertNil(LowestTotalEngine().standings(for: match).result)
        XCTAssertTrue(store.end(match))
        let standings = LowestTotalEngine().standings(for: match)
        XCTAssertEqual(standings.result, preview.declaration)
        XCTAssertEqual(PlayStats(variant: .okey101, match: match, standings: standings).leadValue, preview.summary)
        XCTAssertEqual(HomeCard(match: match, variant: .okey101).summaryText, preview.declaration)
    }

    func test_endRequiresACurrentRoundEvenAfterUndoAndOnlyAppliesToOkey101() {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: [alice])
        store.add(match)
        XCTAssertFalse(match.canEnd)
        XCTAssertNil(match.prospectiveEndResult)
        XCTAssertFalse(store.end(match))
        XCTAssertFalse(match.ended)
        XCTAssertFalse(match.archived)
        store.addRound(Round(deltas: [alice.id: 20]), to: match)
        XCTAssertTrue(match.canEnd)
        XCTAssertEqual(match.prospectiveEndResult?.declaration, "Alice wins!")
        store.undoLastRound(in: match)
        XCTAssertFalse(store.end(match))
        XCTAssertFalse(match.end())
        XCTAssertFalse(match.archived)
        XCTAssertFalse(match.ended)
        XCTAssertTrue(match.started)
        XCTAssertEqual(store.freeMatches.startedMatches, 1)

        for variant in [Variant.gongaStandard, .okeyStandard] {
            let other = Match(game: variant == .gongaStandard ? .gonga : .okey, variant: variant, number: 101,
                              mode: variant == .gongaStandard ? .players : .teams, entrants: [Entrant(name: "Other")], rounds: [Round()])
            store.add(other)
            XCTAssertFalse(store.end(other))
            XCTAssertFalse(other.ended)
            XCTAssertFalse(other.archived)
        }
    }

    func test_targetFreeOkey101CanStartAndRouteIntoPlay() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let bob = Entrant(name: "Bob")
        let match = Match(game: .okey, variantId: "okey-101", mode: .players, entrants: [alice, bob])
        store.add(match)

        let fresh = try storedMatches(in: store)
        XCTAssertEqual(fresh.scorable.map(\.match.id), [match.id])
        XCTAssertTrue(fresh.scorableMatch(match.id) === match)
        XCTAssertFalse(match.started)
        XCTAssertEqual(store.freeMatches.remaining, 3)

        store.addRound(Round(deltas: [alice.id: 10, bob.id: 20]), to: match)

        XCTAssertTrue(match.started)
        XCTAssertEqual(store.freeMatches.remaining, 2)
        let standings = try XCTUnwrap(match.variant).winCondition.engine.standings(for: match)
        XCTAssertEqual(standings.ranked.map(\.total), [10, 20])
        XCTAssertFalse(standings.isOver)
        XCTAssertNil(standings.result)
    }

    func test_targetFreeOkey101ContinuesBeyondFormerCountsAndUndoDoesNotSpendAnotherStart() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let bob = Entrant(name: "Bob")
        let match = Match(game: .okey, variant: .okey101, mode: .players, entrants: [alice, bob])
        store.add(match)

        for _ in 0..<104 {
            store.addRound(Round(deltas: [alice.id: 10, bob.id: 0]), to: match)
        }

        let standings = try XCTUnwrap(match.variant).winCondition.engine.standings(for: match)
        XCTAssertEqual(standings.ranked.map(\.total), [0, 1040])
        XCTAssertFalse(standings.isOver)
        XCTAssertNil(standings.result)
        XCTAssertEqual(match.rounds.map(\.sequence), Array(0..<104))
        XCTAssertEqual(match.entrants.map(\.sequence), [0, 1])
        XCTAssertEqual(store.freeMatches.startedMatches, 1)

        for _ in 0..<104 { store.undoLastRound(in: match) }
        XCTAssertTrue(match.rounds.isEmpty)
        XCTAssertTrue(match.started)
        XCTAssertTrue([match].scorableMatch(match.id) === match)

        store.addRound(Round(deltas: [alice.id: 20, bob.id: 0]), to: match)
        XCTAssertEqual(match.rounds.map(\.sequence), [0])
        XCTAssertEqual(store.freeMatches.startedMatches, 1)
        XCTAssertFalse(match.ended)
    }

    private func gongaMatch(
        entrants: [Entrant] = [Entrant(name: "Alice")],
        createdAt: Date = Date()
    ) -> Match {
        Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: entrants,
            createdAt: createdAt
        )
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
        XCTAssertEqual(stored.variant, .gongaStandard)
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

    // MARK: - Started

    /// Scoring is what turns an intention into a game, so the Round that does
    /// it Starts the Match — through the same store call that records it,
    /// rather than as a second thing a screen has to remember.
    func test_theFirstRoundScoredStartsTheMatch() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let match = gongaMatch(entrants: [alice])
        store.add(match)
        XCTAssertFalse(match.started)

        store.addRound(Round(deltas: [alice.id: 10]), to: match)

        XCTAssertTrue(try XCTUnwrap(try storedMatches(in: store).first).started)
    }

    /// Undo takes back the score, never the Start. A Match the player has been
    /// scoring stays on Home while they correct it.
    func test_undoingTheOnlyRoundLeavesTheMatchStarted() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let match = gongaMatch(entrants: [alice])
        store.add(match)
        store.addRound(Round(deltas: [alice.id: 10]), to: match)

        store.undoLastRound(in: match)

        XCTAssertTrue(match.rounds.isEmpty)
        XCTAssertTrue(match.started)
    }

    /// Adding a Match is not scoring it: Setup hands the store a Match nobody
    /// has played yet, and Home does not list it.
    func test_addingAMatchDoesNotStartIt() throws {
        let store = MatchStore()
        let match = gongaMatch()

        store.add(match)

        XCTAssertFalse(try XCTUnwrap(try storedMatches(in: store).first).started)
    }

    /// The launch sweep, in one store: what an earlier run left un-scored
    /// goes, what was scored stays.
    ///
    /// The abandoned Match is dated before this store was opened because that
    /// is what it is — a leftover from a run that has ended. The sweep will not
    /// touch one created since, which is the next test.
    func test_discardingUnstartedMatchesLeavesTheStartedOnes() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let scored = gongaMatch(entrants: [alice])
        store.add(scored)
        store.addRound(Round(deltas: [alice.id: 10]), to: scored)
        store.add(gongaMatch(createdAt: .distantPast))

        store.discardUnstartedMatches()

        XCTAssertEqual(try storedMatches(in: store).map(\.id), [scored.id])
    }

    /// The Match the player is on right now: saved by Setup, un-Started, no
    /// Rounds — the exact shape the sweep deletes, and the one it must never
    /// take. A sweep running a second time is what would find it, so the rule
    /// is age rather than call order.
    func test_aMatchSetUpSinceTheStoreOpenedSurvivesTheSweep() throws {
        let store = MatchStore()
        let live = gongaMatch()
        store.add(live)

        store.discardUnstartedMatches()

        XCTAssertEqual(try storedMatches(in: store).map(\.id), [live.id])
    }

    // MARK: - Deleting

    /// Delete means deleted: the Match goes, and the Rounds and Entrants it
    /// owns go with it rather than staying behind as objects belonging to
    /// nothing.
    func test_deleteRemovesTheMatchAndEverythingItOwns() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let match = gongaMatch(entrants: [alice])
        store.add(match)
        store.addRound(Round(deltas: [alice.id: 10]), to: match)

        store.delete(match)

        XCTAssertEqual(try storedMatches(in: store).map(\.id), [])
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Round>()).count, 0)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<Entrant>()).count, 0)
    }

    /// The reason Entrants are owned by their Match rather than shared between
    /// Matches: removing a mistake can never reach into real history.
    func test_deletingOneMatchLeavesEveryOtherMatchIntact() throws {
        let store = MatchStore()
        let alice = Entrant(name: "Alice")
        let kept = gongaMatch(entrants: [alice])
        let mistake = gongaMatch(entrants: [Entrant(name: "Bob")])
        store.add(kept)
        store.add(mistake)
        store.addRound(Round(deltas: [alice.id: 10]), to: kept)
        store.addRound(Round(deltas: [alice.id: 20]), to: kept)

        store.delete(mistake)

        XCTAssertEqual(try storedMatches(in: store).map(\.id), [kept.id])
        XCTAssertEqual(kept.rounds.map { $0.deltas[alice.id] }, [10, 20])
        XCTAssertEqual(kept.entrants.map(\.name), ["Alice"])
    }

    /// Archived is a visibility flag and nothing more — it neither permits
    /// deletion nor stands in its way.
    func test_anArchivedMatchCanBeDeleted() throws {
        let store = MatchStore()
        let match = gongaMatch()
        store.add(match)
        store.archive(match)

        store.delete(match)

        XCTAssertEqual(try storedMatches(in: store).map(\.id), [])
    }
}
