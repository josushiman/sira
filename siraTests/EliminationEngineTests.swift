import XCTest
@testable import sira

final class EliminationEngineTests: XCTestCase {
    private let variant = Variant.okeyStandard

    private func makeMatch(entrants: [Entrant], rounds: [Round]) -> Match {
        Match(game: .okey, variant: variant, mode: .teams, entrants: entrants, rounds: rounds)
    }

    func test_startsAtTheVariantsStartingScore() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(entrants: [a, b], rounds: [])

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 21)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 21)
    }

    func test_losingTeamTakesTwoPointPenalty() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(losingEntrantID: a.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 19)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 21)
    }

    // MARK: - Gösterge

    func test_gostergeFindDeductsOneFromTheOtherTeam() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(gostergeFinderID: a.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 21)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 20)
    }

    /// A finder that isn't in this Match deducts from nobody — otherwise a
    /// stale ID would quietly take a point off every team at the table.
    func test_gostergeFindByAnEntrantOutsideTheMatchDeductsNothing() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(gostergeFinderID: Entrant(name: "Team C").id)]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 21)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 21)
    }

    func test_penaltyAndGostergeCombineInTheSameRound() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(losingEntrantID: a.id, gostergeFinderID: b.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        // Team A: -2 penalty, -1 from Team B's find = 18.
        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 18)
        // Team B: unaffected by its own find.
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 21)
    }

    // MARK: - Round modifiers

    func test_cifteDoublesOnlyTheLossPenalty() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(cifteCallers: [a.id], losingEntrantID: a.id, gostergeFinderID: b.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        // Team A: -4 (doubled penalty) - 1 (Gösterge, never doubled) = 16.
        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 16)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 21)
    }

    /// With a single loser, Çifte's two branches collapse: called by the team
    /// that lost or by the team that won, the −4 lands on the same team. The
    /// entry screen still records which team called, because the scoresheet
    /// shows it — the totals just don't turn on it.
    func test_cifteCalledByBothTeamsStillDoublesOnlyOnce() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(cifteCallers: [a.id, b.id], losingEntrantID: a.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        // −4, the same as one caller: Çifte never contributes more than ×2.
        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 17)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 21)
    }

    func test_cifteCalledByTheWinningTeamDoublesTheSamePenalty() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(cifteCallers: [b.id], losingEntrantID: a.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 17)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 21)
    }

    func test_okeyAtmakDoublesOnlyTheLossPenalty() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(okeyAtanID: b.id, losingEntrantID: a.id, gostergeFinderID: b.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        // Team A: -4 (doubled penalty) - 1 (Gösterge, never doubled) = 16.
        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 16)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 21)
    }

    func test_cifteAndOkeyAtmakTogetherTakeTheLossToMinusEight() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(cifteCallers: [b.id], okeyAtanID: b.id, losingEntrantID: a.id, gostergeFinderID: b.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        // Team A: -8 (both modifiers) - 1 (Gösterge, still never scaled) = 12.
        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 12)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 21)
    }

    // MARK: - Match ending

    /// From an odd starting score the −2 penalties alone step past 0 without
    /// landing on it (21 → 1 → −1); it takes a Gösterge's −1 to hit 0 exactly.
    func test_matchEndsWhenAnEntrantReachesZero() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        var rounds = (0..<10).map { _ in Round(losingEntrantID: a.id) }
        rounds.append(Round(gostergeFinderID: b.id))
        let match = makeMatch(entrants: [a, b], rounds: rounds)

        let standings = EliminationEngine().standings(for: match)

        let teamA = standings.ranked.first { $0.entrantID == a.id }!
        XCTAssertEqual(teamA.total, 0)
        XCTAssertTrue(teamA.isOut)
        XCTAssertTrue(standings.isOver)
        XCTAssertEqual(standings.result, "Team B wins!")
    }

    func test_matchDoesNotEndWhileBothTeamsAboveZero() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(losingEntrantID: a.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertFalse(standings.isOver)
        XCTAssertNil(standings.result)
    }

    func test_penaltyCanTakeATeamBelowZero() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        // 21 − (9 × 2) = 3, then a doubled −4 penalty overshoots to −1.
        var rounds = (0..<9).map { _ in Round(losingEntrantID: a.id) }
        rounds.append(Round(cifteCallers: [a.id], losingEntrantID: a.id))
        let match = makeMatch(entrants: [a, b], rounds: rounds)

        let standings = EliminationEngine().standings(for: match)

        let teamA = standings.ranked.first { $0.entrantID == a.id }!
        XCTAssertEqual(teamA.total, -1)
        XCTAssertTrue(teamA.isOut)
        XCTAssertTrue(standings.isOver)
        XCTAssertEqual(standings.result, "Team B wins!")
    }

    // MARK: - Undo

    func test_standingsAfterAppendingThenUndoingARoundMatchStandingsBeforeAppending() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        var match = makeMatch(
            entrants: [a, b],
            rounds: [Round(losingEntrantID: a.id)]
        )

        let before = EliminationEngine().standings(for: match)

        match.addRound(Round(losingEntrantID: b.id, gostergeFinderID: a.id))
        match.undoLastRound()

        let after = EliminationEngine().standings(for: match)

        XCTAssertEqual(before, after)
    }

    // MARK: - Ranking

    func test_rankingOrdersHigherTotalFirst() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(losingEntrantID: a.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.map(\.name), ["Team B", "Team A"])
    }

    /// As for the keypad Engines: the countdown totals would survive any
    /// arrangement, but the delta from the last Round only means something if
    /// order does.
    func test_roundsStoredOutOfOrderStillScoreInSequenceOrder() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let inOrder = makeMatch(entrants: [a, b], rounds: [
            Round(losingEntrantID: a.id),
            Round(losingEntrantID: b.id, gostergeFinderID: a.id),
        ])

        let expected = EliminationEngine().standings(for: inOrder)
        let actual = EliminationEngine().standings(for: inOrder.withRoundsStoredOutOfOrder())

        XCTAssertEqual(actual, expected)
        // Team B took the −2 and the Gösterge deduction on the last Round.
        XCTAssertEqual(actual.ranked.first { $0.entrantID == b.id }?.deltaFromLastRound, -3)

        let reversed = makeMatch(entrants: [a, b], rounds: inOrder.rounds.reversed())
        XCTAssertNotEqual(EliminationEngine().standings(for: reversed), expected)
    }
}
