import XCTest
@testable import sira

final class MatchTests: XCTestCase {
    // MARK: - Variant resolution

    private func match(game: Game, variantId: String, roundCount: Int? = nil) -> Match {
        Match(
            game: game,
            variantId: variantId,
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

    func test_resolvedVariantCarriesItsOwnScoringRules() {
        XCTAssertEqual(match(game: .gonga, variantId: "gonga-101").variant?.limit, 101)
        XCTAssertEqual(match(game: .gonga, variantId: "gonga-151").variant?.limit, 151)
        XCTAssertEqual(match(game: .okey, variantId: "okey-21").variant?.startingScore, 21)
        XCTAssertEqual(match(game: .okey, variantId: "okey-101").variant?.winCondition, .fixedRounds)
    }

    /// Okey 101 is played over 8 or 12 Rounds, chosen at Setup. The choice is
    /// stored on the Match and applied on top of the shipped Variant.
    func test_storedRoundCountOverridesTheVariantsDefault() {
        XCTAssertEqual(match(game: .okey, variantId: "okey-101", roundCount: 12).variant?.roundCount, 12)
        XCTAssertEqual(match(game: .okey, variantId: "okey-101", roundCount: 8).variant?.roundCount, 8)
    }

    func test_withoutAStoredRoundCountTheVariantsOwnValueStands() {
        XCTAssertEqual(match(game: .okey, variantId: "okey-101").variant?.roundCount, 8)
    }

    /// A Match naming a Variant this build doesn't know is skipped rather than
    /// scored by a substitute, so resolution yields nothing at all.
    func test_anUnknownVariantIdResolvesToNoVariant() {
        XCTAssertNil(match(game: .okey, variantId: "okey-999").variant)
    }

    /// Ids resolve against the Variants of the Match's own Game, so a real id
    /// belonging to the other Game is as unresolvable as a made-up one.
    func test_aVariantIdFromAnotherGameDoesNotResolve() {
        XCTAssertNil(match(game: .gonga, variantId: "okey-21").variant)
    }

    // MARK: - Round sequence

    private func gongaMatch(rounds: [Round] = []) -> Match {
        Match(
            game: .gonga,
            variant: .gonga101,
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
            variant: .gonga101,
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
            variant: .gonga101,
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
            variant: .gonga101,
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
            variant: .gonga101,
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
        let match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [Entrant(name: "Alice")])

        _ = match.undoLastRound()

        XCTAssertTrue(match.rounds.isEmpty)
    }

    func test_archiveSetsTheArchivedFlag() {
        let match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [Entrant(name: "Alice")])

        match.archive()

        XCTAssertTrue(match.archived)
    }

    func test_restoreClearsTheArchivedFlag() {
        let match = Match(
            game: .gonga,
            variant: .gonga101,
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
            variant: .gonga101,
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
        let playable = match(game: .gonga, variantId: "gonga-101")
        let matches = [playable, match(game: .okey, variantId: "okey-21")]

        XCTAssertEqual(matches.scorableMatch(playable.id)?.id, playable.id)
    }

    func test_aRouteNamingAMatchThisBuildCannotScoreResolvesToNothing() {
        let stranger = match(game: .gonga, variantId: "gonga-from-a-later-release")
        let matches = [match(game: .gonga, variantId: "gonga-101"), stranger]

        XCTAssertNil(matches.scorableMatch(stranger.id))
    }

    /// Deletion is the other way a route stops resolving: the id names a Match
    /// that is simply no longer among them.
    func test_aRouteNamingAMatchThatIsNoLongerThereResolvesToNothing() {
        let matches = [match(game: .gonga, variantId: "gonga-101")]

        XCTAssertNil(matches.scorableMatch(UUID()))
    }

    func test_aRouteNamingNothingResolvesToNothing() {
        let matches = [match(game: .gonga, variantId: "gonga-101")]

        XCTAssertNil(matches.scorableMatch(nil))
    }
}
