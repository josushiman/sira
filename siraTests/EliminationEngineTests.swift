import XCTest
@testable import sira

final class EliminationEngineTests: XCTestCase {
    private let variant = Variant.okeyStandard
    /// The score these Matches count down from unless a test says otherwise.
    /// Stated here because the Variant no longer carries one: Okey is played
    /// from whatever its table chose, and 21 is what tables usually choose.
    private let startingScore = 21

    private func makeMatch(entrants: [Entrant], number: Int? = nil, rounds: [Round]) -> Match {
        Match(
            game: .okey,
            variant: variant,
            number: number ?? startingScore,
            mode: .teams,
            entrants: entrants,
            rounds: rounds
        )
    }

    func test_startsAtTheStartingScoreTheMatchWasSetUpAt() {
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

    // MARK: - A chosen starting score

    /// The countdown starts wherever the table said it did, not at the score
    /// the Variant ships with.
    func test_teamsBeginAtTheStartingScoreThisMatchChose() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(entrants: [a, b], number: 31, rounds: [])

        let standings = EliminationEngine().standings(for: match)

        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 31)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 31)
    }

    /// Changing the length has not changed the game: the losing team still
    /// takes −2 and each Gösterge find still deducts 1, neither scaled by a
    /// starting score of 31 rather than 21.
    func test_thePenaltyAndTheGostergeDoNotScaleWithTheStartingScore() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            number: 31,
            rounds: [Round(losingEntrantID: a.id, gostergeFinderID: b.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        // Team A: −2 penalty, −1 from Team B's find = 28.
        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 28)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 31)
    }

    /// 0 is still the finish line at any starting score. Seven −2 Rounds end a
    /// Match started at 14 and leave one started at 21 with a Round still to
    /// play, so this fails against a Match scored by the Variant's constant.
    func test_theMatchEndsAtZeroFromWhateverScoreItStartedAt() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let rounds = (0..<7).map { _ in Round(losingEntrantID: a.id) }
        let match = makeMatch(entrants: [a, b], number: 14, rounds: rounds)

        let standings = EliminationEngine().standings(for: match)

        let teamA = standings.ranked.first { $0.entrantID == a.id }!
        XCTAssertEqual(teamA.total, 0)
        XCTAssertTrue(teamA.isOut)
        XCTAssertTrue(standings.isOver)
        XCTAssertEqual(standings.result, "Team B wins!")
    }

    /// Çifte and Okey atmak stack to ×4 on the penalty at a custom starting
    /// score exactly as they do at 21, and the Gösterge find is still not
    /// scaled by either.
    func test_theModifiersStackTheSameWayAtACustomStartingScore() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            number: 31,
            rounds: [Round(cifteCallers: [b.id], okeyAtanID: b.id, losingEntrantID: a.id, gostergeFinderID: b.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        // Team A: −8 (both modifiers) − 1 (Gösterge, still never scaled) = 22.
        XCTAssertEqual(standings.ranked.first { $0.entrantID == a.id }!.total, 22)
        XCTAssertEqual(standings.ranked.first { $0.entrantID == b.id }!.total, 31)
    }

    /// A Match whose starting score cannot be resolved is not one starting at
    /// zero, with both teams already lost. It has nothing to be scored by, and
    /// `scorable` keeps it away from here — but the Engine says nothing about
    /// it either way rather than inventing a score.
    func test_aMatchWithNoResolvableStartingScoreScoresNothing() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = Match(
            game: .okey,
            variantId: "okey-nonesuch",
            mode: .teams,
            entrants: [a, b],
            rounds: [Round(losingEntrantID: a.id)]
        )

        let standings = EliminationEngine().standings(for: match)

        XCTAssertTrue(standings.ranked.isEmpty)
        XCTAssertFalse(standings.isOver)
        XCTAssertNil(standings.result)
    }

    // MARK: - Undo

    func test_standingsAfterAppendingThenUndoingARoundMatchStandingsBeforeAppending() {
        let a = Entrant(name: "Team A")
        let b = Entrant(name: "Team B")
        let match = makeMatch(
            entrants: [a, b],
            rounds: [Round(losingEntrantID: a.id)]
        )

        let before = EliminationEngine().standings(for: match)

        match.addRound(Round(losingEntrantID: b.id, gostergeFinderID: a.id))
        _ = match.undoLastRound()

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
        let actual = EliminationEngine().standings(for: inOrder.withEntrantsAndRoundsStoredOutOfOrder())

        XCTAssertEqual(actual, expected)
        // Team B took the −2 and the Gösterge deduction on the last Round.
        XCTAssertEqual(actual.ranked.first { $0.entrantID == b.id }?.deltaFromLastRound, -3)

        let reversed = makeMatch(entrants: [a, b], rounds: inOrder.rounds.reversed())
        XCTAssertNotEqual(EliminationEngine().standings(for: reversed), expected)
    }
}
