import XCTest
@testable import sira

final class MatchTests: XCTestCase {
    // MARK: - Variant resolution

    private func match(
        game: Game,
        variantId: String,
        limit: Int? = nil,
        startingScore: Int? = nil,
        roundCount: Int? = nil
    ) -> Match {
        Match(
            game: game,
            variantId: variantId,
            limit: limit,
            startingScore: startingScore,
            roundCount: roundCount,
            mode: .players,
            entrants: [Entrant(name: "Alice")]
        )
    }

    func test_resolvesEveryShippedVariantFromItsStoredId() {
        for game in Game.allCases {
            for shipped in Variant.all(for: game) {
                let resolved = match(game: game, variantId: shipped.id).variant
                XCTAssertEqual(resolved, shipped, "\(shipped.id) did not resolve to itself")
            }
        }
    }

    /// What the id resolves is shape — the rules the Match is scored by — and
    /// never how far it runs.
    func test_resolvedVariantCarriesItsOwnScoringRules() {
        XCTAssertEqual(match(game: .gonga, variantId: "gonga-standard").variant?.winCondition, .survival)
        XCTAssertEqual(match(game: .okey, variantId: "okey-standard").variant?.entrantMode, .teams)
        XCTAssertEqual(match(game: .okey, variantId: "okey-101").variant?.winCondition, .fixedRounds)
    }

    // Resolving the Variant cannot smuggle the Match's number back onto it:
    // `Variant` has no `limit`, `startingScore` or `roundCount` to smuggle it
    // into. The number stays reachable only through `Match.variantNumber`,
    // asserted below.

    /// A Match naming a Variant this build doesn't know is skipped rather than
    /// scored by a substitute, so resolution yields nothing at all.
    func test_anUnknownVariantIdResolvesToNoVariant() {
        XCTAssertNil(match(game: .okey, variantId: "okey-999").variant)
    }

    /// Ids resolve against the Variants of the Match's own Game, so a real id
    /// belonging to the other Game is as unresolvable as a made-up one.
    func test_aVariantIdFromAnotherGameDoesNotResolve() {
        XCTAssertNil(match(game: .gonga, variantId: "okey-standard").variant)
    }

    // MARK: - The number the Match is played at

    // Every read of a Match's number goes through one accessor, so that the
    // four places which used to invent a fallback each — an unreachable limit
    // here, a zero one there — cannot disagree about what a Match with no
    // number means.

    func test_aStoredLimitIsTheNumberASurvivalMatchIsPlayedAt() {
        XCTAssertEqual(match(game: .gonga, variantId: "gonga-standard", limit: 201).variantNumber, 201)
    }

    func test_aStoredStartingScoreIsTheNumberAnEliminationMatchIsPlayedAt() {
        XCTAssertEqual(match(game: .okey, variantId: "okey-standard", startingScore: 31).variantNumber, 31)
    }

    func test_aStoredRoundCountIsTheNumberAFixedRoundsMatchIsPlayedAt() {
        XCTAssertEqual(match(game: .okey, variantId: "okey-101", roundCount: 12).variantNumber, 12)
    }

    /// A Match that stored no number is played at no number: the Variant it
    /// names has none to lend it, and inventing one would score the table's
    /// game by a rule nobody at it agreed to.
    func test_withoutAStoredNumberThereIsNoNumber() {
        XCTAssertNil(match(game: .gonga, variantId: "gonga-standard").variantNumber)
        XCTAssertNil(match(game: .okey, variantId: "okey-standard").variantNumber)
        XCTAssertNil(match(game: .okey, variantId: "okey-101").variantNumber)
    }

    /// The Win Condition says which of the three numbers is the Match's, so a
    /// Match storing one of the other two stores nothing that describes it.
    func test_aNumberOfTheWrongKindIsNoNumberAtAll() {
        XCTAssertNil(match(game: .gonga, variantId: "gonga-standard", roundCount: 12).variantNumber)
        XCTAssertNil(match(game: .okey, variantId: "okey-standard", limit: 201).variantNumber)
        XCTAssertNil(match(game: .okey, variantId: "okey-101", startingScore: 21).variantNumber)
    }

    /// A Survival Match is played at a limit whatever else happens to be
    /// stored beside it: the Win Condition says which of the three is the
    /// number, so a stray value cannot become one.
    func test_onlyTheNumberTheWinConditionTakesIsRead() {
        let confused = match(game: .gonga, variantId: "gonga-standard", limit: 201, startingScore: 31, roundCount: 12)

        XCTAssertEqual(confused.variantNumber, 201)
    }

    /// Neither a stored number nor a Variant to supply one: nothing at all,
    /// rather than a substitute that would score the Match by a rule nobody
    /// at the table agreed to.
    func test_aMatchWithNoStoredNumberAndNoVariantResolvesNothing() {
        XCTAssertNil(match(game: .gonga, variantId: "gonga-from-a-later-release").variantNumber)
    }

    /// Setup records the number for every Match it starts, in the field its
    /// Win Condition takes it in.
    func test_aMatchStartedFromAVariantRecordsTheNumberItWasStartedAt() {
        let gonga = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Alice")])
        let okeyStandard = Match(game: .okey, variant: .okeyStandard, number: 21, mode: .teams, entrants: [Entrant(name: "Us")])
        let okey101 = Match(game: .okey, variant: .okey101, number: 8, mode: .players, entrants: [Entrant(name: "Alice")])

        XCTAssertEqual(gonga.variantNumber, 101)
        XCTAssertEqual(gonga.limit, 101)
        XCTAssertEqual(okeyStandard.startingScore, 21)
        XCTAssertEqual(okey101.roundCount, 8)
    }

    /// At most one of the three is ever set, so nothing downstream has to ask
    /// which of two present numbers describes the Match.
    func test_aMatchRecordsOnlyTheNumberItsWinConditionTakes() {
        let gonga = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Alice")])

        XCTAssertNil(gonga.startingScore)
        XCTAssertNil(gonga.roundCount)
    }

    // MARK: - Round sequence

    private func gongaMatch(rounds: [Round] = []) -> Match {
        Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [Entrant(name: "Alice")],
            rounds: rounds
        )
    }

    func test_addRoundStampsEachRoundWithTheNextSequence() {
        let match = gongaMatch()

        match.addRound(Round())
        match.addRound(Round())
        match.addRound(Round())

        XCTAssertEqual(match.rounds.map(\.sequence), [0, 1, 2])
    }

    func test_roundsGivenInPlayedOrderTakeTheirPositionAsTheirSequence() {
        let match = gongaMatch(rounds: [Round(), Round(), Round()])

        XCTAssertEqual(match.rounds.map(\.sequence), [0, 1, 2])
    }

    func test_addRoundIgnoresWhateverSequenceTheRoundArrivedWith() {
        let match = gongaMatch()

        match.addRound(Round().withSequence(99))

        XCTAssertEqual(match.rounds.map(\.sequence), [0])
    }

    func test_entrantsReadInSeatOrderHoweverTheyAreStored() {
        let seated = [Entrant(name: "Alice"), Entrant(name: "Bob"), Entrant(name: "Cem")]
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: seated
        ).withEntrantsAndRoundsStoredOutOfOrder()

        XCTAssertEqual(match.storedEntrants.map(\.name), ["Cem", "Bob", "Alice"])
        XCTAssertEqual(match.entrants.map(\.name), ["Alice", "Bob", "Cem"])
        XCTAssertEqual(match.entrants.map(\.sequence), [0, 1, 2])
    }

    func test_roundsReadInSequenceOrderHoweverTheyAreStored() {
        let played = [Round(), Round(), Round()]
        let match = gongaMatch(rounds: played).withEntrantsAndRoundsStoredOutOfOrder()

        XCTAssertEqual(match.storedRounds.map(\.id), played.reversed().map(\.id))
        XCTAssertEqual(match.rounds.map(\.id), played.map(\.id))
        XCTAssertEqual(match.rounds.map(\.sequence), [0, 1, 2])
    }

    func test_undoFreesTheHighestSequenceAndTheNextRoundTakesItAgain() {
        let match = gongaMatch(rounds: [Round(), Round(), Round()])

        _ = match.undoLastRound()
        let replacement = Round()
        match.addRound(replacement)

        XCTAssertEqual(match.rounds.count, 3)
        XCTAssertEqual(match.rounds.map(\.sequence), [0, 1, 2])
        XCTAssertEqual(match.rounds.last?.id, replacement.id)
    }

    func test_undoRemovesTheHighestSequenceRatherThanTheLastStoredRound() {
        let played = [Round(), Round(), Round()]
        let match = gongaMatch(rounds: played).withEntrantsAndRoundsStoredOutOfOrder()

        _ = match.undoLastRound()

        XCTAssertEqual(match.rounds.map(\.id), [played[0].id, played[1].id])
    }

    func test_recordRejoinAttachesToTheHighestSequenceRound() {
        let a = Entrant(name: "Alice")
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [a],
            rounds: [Round(), Round()]
        ).withEntrantsAndRoundsStoredOutOfOrder()

        match.recordRejoin(RejoinEvent(id: a.id, to: 40))

        XCTAssertEqual(match.rounds.first?.rejoins, [])
        XCTAssertEqual(match.rounds.last?.rejoins, [RejoinEvent(id: a.id, to: 40)])
    }

    // MARK: - Undo

    func test_undoLastRoundRemovesTheMostRecentRound() {
        let a = Entrant(name: "Alice")
        let firstRound = Round(deltas: [a.id: 10])
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [a],
            rounds: [
                firstRound,
                Round(deltas: [a.id: 20]),
            ]
        )

        _ = match.undoLastRound()

        XCTAssertEqual(match.rounds, [firstRound])
    }

    func test_undoLastRoundRemovesAnyRejoinAttachedToThatRound() {
        let a = Entrant(name: "Alice")
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [a],
            rounds: [
                Round(deltas: [a.id: 10], rejoins: [RejoinEvent(id: a.id, to: 40)]),
            ]
        )

        _ = match.undoLastRound()

        XCTAssertTrue(match.rounds.isEmpty)
    }

    func test_undoLastRoundOnMatchWithNoRoundsIsANoOp() {
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Alice")])

        _ = match.undoLastRound()

        XCTAssertTrue(match.rounds.isEmpty)
    }

    func test_archiveSetsTheArchivedFlag() {
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Alice")])

        match.archive()

        XCTAssertTrue(match.archived)
    }

    func test_restoreClearsTheArchivedFlag() {
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [Entrant(name: "Alice")],
            archived: true
        )

        match.restore()

        XCTAssertFalse(match.archived)
    }

    func test_archivingAndRestoringPreservesRoundsAndStandings() {
        let a = Entrant(name: "Alice")
        let round = Round(deltas: [a.id: 10])
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [a],
            rounds: [round]
        )

        match.archive()
        match.restore()

        XCTAssertEqual(match.rounds, [round])
    }

    // MARK: - Route resolution

    /// The one route into Play that does not come through Home's list: a
    /// `Navigator` naming a Match by id. Both ways that id can stop naming a
    /// Match this build can score have to resolve to nothing, or Play is left
    /// standing in front of a Match it has no rules for.
    func test_aRouteNamingAScorableMatchResolvesToIt() {
        let playable = playableGonga()
        let matches = [playable, match(game: .okey, variantId: "okey-standard", startingScore: 21)]

        XCTAssertEqual(matches.scorableMatch(playable.id)?.id, playable.id)
    }

    func test_aRouteNamingAMatchThisBuildCannotScoreResolvesToNothing() {
        let stranger = match(game: .gonga, variantId: "gonga-from-a-later-release", limit: 101)
        let matches = [playableGonga(), stranger]

        XCTAssertNil(matches.scorableMatch(stranger.id))
    }

    /// Deletion is the other way a route stops resolving: the id names a Match
    /// that is simply no longer among them.
    func test_aRouteNamingAMatchThatIsNoLongerThereResolvesToNothing() {
        let matches = [playableGonga()]

        XCTAssertNil(matches.scorableMatch(UUID()))
    }

    func test_aRouteNamingNothingResolvesToNothing() {
        let matches = [playableGonga()]

        XCTAssertNil(matches.scorableMatch(nil))
    }

    // MARK: - The gate a Match with no number does not pass

    // A Match with a Variant this build knows and no number to play it at is
    // as unscorable as one naming a Variant it does not know, and is treated
    // the same way: skipped, and left exactly where it is.

    private func numberless() -> Match {
        match(game: .gonga, variantId: "gonga-standard")
    }

    private func playableGonga() -> Match {
        match(game: .gonga, variantId: "gonga-standard", limit: 101)
    }

    func test_aMatchWithNoNumberIsSkippedByTheScorableGate() {
        let playable = playableGonga()
        let matches = [numberless(), playable]

        XCTAssertEqual(matches.scorable.map(\.match.id), [playable.id])
    }

    func test_aRouteNamingAMatchWithNoNumberResolvesToNothing() {
        let unplayable = numberless()
        let matches = [unplayable, playableGonga()]

        XCTAssertNil(matches.scorableMatch(unplayable.id))
    }

    /// Skipped is not deleted (`docs/adr/0007`): the Match, its Entrants and
    /// its Rounds are all still there for the build — or the player — that can
    /// say what it was played at.
    func test_aMatchSkippedForHavingNoNumberIsLeftUntouched() {
        let alice = Entrant(name: "Alice")
        let unplayable = Match(
            game: .gonga,
            variantId: "gonga-standard",
            mode: .players,
            entrants: [alice],
            rounds: [Round(deltas: [alice.id: 20])]
        )
        let matches = [unplayable]

        XCTAssertTrue(matches.scorable.isEmpty)
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(unplayable.entrants.map(\.name), ["Alice"])
        XCTAssertEqual(unplayable.rounds.count, 1)
    }

    /// The `?? .max` regression, pinned where it is actually prevented. An
    /// Engine handed a numberless Match has nothing to score it by; what keeps
    /// one from ever being handed over is this gate, so it is asserted here
    /// rather than by giving an Engine a substitute to be scored against.
    func test_noWinConditionsMatchesReachAnEngineWithoutANumber() {
        let numberlessMatches = [
            match(game: .gonga, variantId: "gonga-standard"),
            match(game: .okey, variantId: "okey-standard"),
            match(game: .okey, variantId: "okey-101"),
        ]

        XCTAssertTrue(numberlessMatches.scorable.isEmpty)
        for unplayable in numberlessMatches {
            XCTAssertNil(numberlessMatches.scorableMatch(unplayable.id))
        }
    }
}


/// `isGone` — the question "is this Match still there to read?", which
/// SwiftData answers differently on either side of the save.
extension MatchTests {
    func test_aStoredMatchIsNotGone() {
        let store = MatchStore()
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Alice")])
        store.add(match)

        XCTAssertFalse(match.isGone)
    }

    /// Deleted but not yet written out: this is the window `isDeleted` covers,
    /// and the Match still belongs to its context.
    func test_aMatchDeletedButNotYetSavedIsGone() {
        let store = MatchStore()
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Alice")])
        store.add(match)

        store.context.delete(match)

        XCTAssertTrue(match.isGone)
    }

    /// Written out, which is what `MatchStore.delete(_:)` does in one step. The
    /// Match is no longer deleted as far as `isDeleted` is concerned — it is
    /// no longer anything, which is what having no context says.
    func test_aDeletedAndSavedMatchIsGone() {
        let store = MatchStore()
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Alice")])
        store.add(match)

        store.delete(match)

        XCTAssertFalse(match.isDeleted)
        XCTAssertTrue(match.isGone)
    }

    /// A Match that was built but never added to a store is not gone — it has
    /// no context, like a deleted one, but it never belonged to a store and
    /// every property on it reads fine. Fixtures and a Setup screen's Match
    /// before it is added are both this.
    func test_aMatchThatWasNeverStoredIsNotGone() {
        let match = Match(game: .gonga, variant: .gongaStandard, number: 101, mode: .players, entrants: [Entrant(name: "Alice")])

        XCTAssertFalse(match.isGone)
    }

    // MARK: - How the number reads

    /// Home and Play both name a Match by this, so it is phrased once here
    /// rather than assembled the same way on two screens.
    func test_aMatchIsNamedByTheNumberItIsPlayedAtInItsOwnKindsPhrase() {
        let survival = match(game: .gonga, variantId: "gonga-standard", limit: 201)
        let elimination = match(game: .okey, variantId: "okey-standard", startingScore: 31)
        let fixedRounds = match(game: .okey, variantId: "okey-101", roundCount: 5)

        XCTAssertEqual(survival.numberPhrase, "to 201")
        XCTAssertEqual(elimination.numberPhrase, "from 31")
        XCTAssertEqual(fixedRounds.numberPhrase, "5 rounds")
    }

    /// Nothing to name it by when nothing resolves — the same silence the
    /// accessor answers with, rather than a phrase built around a blank.
    func test_aMatchWithNoNumberHasNoPhrase() {
        XCTAssertNil(match(game: .gonga, variantId: "gonga-from-a-later-release").numberPhrase)
    }
}
