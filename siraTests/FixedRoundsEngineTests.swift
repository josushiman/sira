import XCTest
@testable import sira

final class FixedRoundsEngineTests: XCTestCase {
    private let variant = Variant.okey101

    private func makeMatch(entrants: [Entrant], rounds: [Round]) -> Match {
        Match(game: .okey, variant: variant, mode: .players, entrants: entrants, rounds: rounds)
    }

    func test_accumulatesDeltasAcrossRounds() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [
                Round(deltas: [a.id: 20, b.id: 5]),
                Round(deltas: [a.id: 10, b.id: 15]),
            ]
        )

        let standings = FixedRoundsEngine().standings(for: match)

        let aliceTotal = standings.ranked.first { $0.entrantID == a.id }!.total
        let bobTotal = standings.ranked.first { $0.entrantID == b.id }!.total
        XCTAssertEqual(aliceTotal, 30)
        XCTAssertEqual(bobTotal, 20)
        XCTAssertFalse(standings.isOver)
    }

    // MARK: - Çifte

    /// The call came off: the caller finished the Round on 0, and everyone
    /// *else* pays double for it.
    func test_cifteCallerWhoWinsDoublesEveryoneElseAndNotThemselves() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [Round(deltas: [a.id: 0, b.id: 5, c.id: 10], cifteCallers: [a.id])]
        )

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 0)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 10)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == c.id }!.total, 20)
    }

    /// The call didn't come off: the caller carries the cost alone.
    func test_cifteCallerWhoLosesDoublesOnlyThemselves() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [Round(deltas: [a.id: 20, b.id: 5, c.id: 0], cifteCallers: [a.id])]
        )

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 40)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 5)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == c.id }!.total, 0)
    }

    /// Two callers, one of whom won: the losing caller is reached by both
    /// rules — their own and the winner's — and still doubles only once.
    func test_twoCifteCallersOneWinningLeaveTheLoserAtDoubleNotQuadruple() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [Round(deltas: [a.id: 0, b.id: 20, c.id: 10], cifteCallers: [a.id, b.id])]
        )

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 0)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 40)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == c.id }!.total, 20)
    }

    // MARK: - Okey atmak

    func test_okeyAtmakDoublesEveryEntrantsDeltaForThatRound() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [Round(deltas: [a.id: 10, b.id: 5, c.id: 0], okeyAtanID: c.id)]
        )

        let standings = FixedRoundsEngine().standings(for: match)

        let alice = standings.ranked.first { $0.entrantID == a.id }!
        XCTAssertEqual(alice.total, 20)
        XCTAssertEqual(alice.deltaFromLastRound, 20)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 10)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == c.id }!.total, 0)
    }

    /// The two modifiers stack per Entrant, and ×4 is as far as they go.
    func test_losingCifteCallerInAnOkeyAtmakRoundTakesQuadrupleWhileOthersTakeDouble() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cara")
        let match = makeMatch(
            entrants: [a, b, c],
            rounds: [Round(deltas: [a.id: 20, b.id: 5, c.id: 0], cifteCallers: [a.id], okeyAtanID: c.id)]
        )

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 80)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 10)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == c.id }!.total, 0)
    }

    /// The Okey atan may also have called Çifte — they won, so their doubled 0
    /// is still 0, and nothing needs to forbid the combination.
    func test_okeyAtanWhoAlsoCalledCifteDoublesEveryoneElseAndStaysAtZero() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 0, b.id: 5], cifteCallers: [a.id], okeyAtanID: a.id)]
        )

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 0)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 20)
    }

    /// Regression: the Round-entry screen used to double for Çifte *and* the
    /// Engine doubled the same Round again, so an Okey 101 Çifte Round scored
    /// ×4. Neither suite caught it, because the Engine tests build `Round`
    /// fixtures by hand and the entry tests never reach an Engine — so this
    /// one crosses the seam, entering values the way a player does and
    /// scoring the Round that entry actually produces.
    func test_cifteRoundEnteredOnTheKeypadScoresDoubleNotQuadruple() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var entry = RoundEntryState(entrants: [a, b])
        entry.appendDigit("1")
        entry.appendDigit("0")
        entry.toggleCifteForActive()
        entry.selectActive(b.id)
        entry.appendDigit("5")

        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(
                deltas: entry.rawDeltas,
                cifteCallers: entry.cifteCallers,
                okeyAtanID: entry.okeyAtanID
            )]
        )
        let standings = FixedRoundsEngine().standings(for: match)

        let alice = standings.ranked.first { $0.entrantID == a.id }!
        let bob = standings.ranked.first { $0.entrantID == b.id }!
        // Alice called and didn't win, so she doubles once — 20, never 40.
        XCTAssertEqual(alice.total, 20)
        XCTAssertEqual(bob.total, 5)
    }

    /// The other half of the seam: what the screen previews for a row is what
    /// the Engine goes on to score it at, for both modifiers at once.
    func test_keypadPreviewMatchesWhatTheEngineScores() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var entry = RoundEntryState(entrants: [a, b])
        entry.appendDigit("2")
        entry.appendDigit("0")
        entry.toggleCifteForActive()
        entry.selectActive(b.id)
        entry.toggleOkeyAtanForActive()

        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(
                deltas: entry.rawDeltas,
                cifteCallers: entry.cifteCallers,
                okeyAtanID: entry.okeyAtanID
            )]
        )
        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertEqual(entry.previews()[a.id], .init(multiplier: 4, value: 80))
        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 80)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 0)
    }

    func test_noOneIsEverMarkedOut() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 500, b.id: 5])]
        )

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertTrue(standings.ranked.allSatisfy { !$0.isOut })
    }

    func test_matchDoesNotEndBeforeTheConfiguredRoundCount() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let rounds = (0..<7).map { _ in Round(deltas: [a.id: 5, b.id: 10]) }
        let match = makeMatch(entrants: [a, b], rounds: rounds)

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertFalse(standings.isOver)
        XCTAssertNil(standings.result)
    }

    /// The Match runs for the Round count chosen at Setup, not the Variant's
    /// default — a 12-Round Okey 101 Match is still going after 8 Rounds.
    func test_matchRunsForTheSetupChosenRoundCountRatherThanTheVariantsDefault() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let rounds = (0..<8).map { _ in Round(deltas: [a.id: 5, b.id: 10]) }
        let match = Match(
            game: .okey,
            variantId: Variant.okey101.id,
            roundCount: 12,
            mode: .players,
            entrants: [a, b],
            rounds: rounds
        )

        XCTAssertFalse(FixedRoundsEngine().standings(for: match).isOver)

        // Grown to twelve in place: a Match is a reference type, so a second
        // name for it would be the same Match rather than an eight-Round copy.
        for _ in 0..<4 {
            match.addRound(Round(deltas: [a.id: 5, b.id: 10]))
        }

        XCTAssertTrue(FixedRoundsEngine().standings(for: match).isOver)
    }

    func test_lowestTotalWinsOnceTheConfiguredRoundCountIsReached() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let rounds = (0..<8).map { _ in Round(deltas: [a.id: 5, b.id: 10]) }
        let match = makeMatch(entrants: [a, b], rounds: rounds)

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertTrue(standings.isOver)
        XCTAssertEqual(standings.result, "Alice wins!")
        XCTAssertEqual(standings.ranked.map(\.name), ["Alice", "Bob"])
    }

    func test_tiedLowestTotalAtTheEndProducesATieResult() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let rounds = (0..<8).map { _ in Round(deltas: [a.id: 5, b.id: 5]) }
        let match = makeMatch(entrants: [a, b], rounds: rounds)

        let standings = FixedRoundsEngine().standings(for: match)

        XCTAssertTrue(standings.isOver)
        XCTAssertEqual(standings.result, "Tie between Alice and Bob!")
    }

    // MARK: - Undo

    func test_standingsAfterAppendingThenUndoingARoundMatchStandingsBeforeAppending() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(deltas: [a.id: 20, b.id: 5])]
        )

        let before = FixedRoundsEngine().standings(for: match)

        match.addRound(Round(deltas: [a.id: 10, b.id: 15], cifteCallers: [a.id, b.id]))
        match.undoLastRound()

        let after = FixedRoundsEngine().standings(for: match)

        XCTAssertEqual(before, after)
    }

    /// The delta from the last Round is the order-sensitive half of Standings:
    /// totals are a sum and would survive any arrangement, but "last" only
    /// means something if order does. Storage order must not get to answer it.
    func test_roundsStoredOutOfOrderStillScoreInSequenceOrder() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let inOrder = makeMatch(entrants: [a, b], rounds: [
            Round(deltas: [a.id: 20, b.id: 0]),
            Round(deltas: [a.id: 5, b.id: 30]),
        ])

        let expected = FixedRoundsEngine().standings(for: inOrder)
        let actual = FixedRoundsEngine().standings(for: inOrder.withRoundsStoredOutOfOrder())

        XCTAssertEqual(actual, expected)
        XCTAssertEqual(actual.ranked.first { $0.entrantID == b.id }?.deltaFromLastRound, 30)

        // And the fixture really is order-sensitive, so the equality above
        // isn't passing because both arrangements happen to score alike.
        let reversed = makeMatch(entrants: [a, b], rounds: inOrder.rounds.reversed())
        XCTAssertNotEqual(FixedRoundsEngine().standings(for: reversed), expected)
    }
}
