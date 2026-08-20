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

    // MARK: - Undo

    func test_undoLastRoundRemovesTheMostRecentRound() {
        let a = Entrant(name: "Alice")
        let firstRound = Round(deltas: [a.id: 10])
        var match = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a],
            rounds: [
                firstRound,
                Round(deltas: [a.id: 20]),
            ]
        )

        match.undoLastRound()

        XCTAssertEqual(match.rounds, [firstRound])
    }

    func test_undoLastRoundRemovesAnyRejoinAttachedToThatRound() {
        let a = Entrant(name: "Alice")
        var match = Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [a],
            rounds: [
                Round(deltas: [a.id: 10], rejoins: [RejoinEvent(id: a.id, to: 40)]),
            ]
        )

        match.undoLastRound()

        XCTAssertTrue(match.rounds.isEmpty)
    }

    func test_undoLastRoundOnMatchWithNoRoundsIsANoOp() {
        var match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [Entrant(name: "Alice")])

        match.undoLastRound()

        XCTAssertTrue(match.rounds.isEmpty)
    }

    func test_archiveSetsTheArchivedFlag() {
        var match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [Entrant(name: "Alice")])

        match.archive()

        XCTAssertTrue(match.archived)
    }

    func test_restoreClearsTheArchivedFlag() {
        var match = Match(
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
        var match = Match(
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
}
