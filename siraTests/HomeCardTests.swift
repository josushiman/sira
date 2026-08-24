import XCTest
import SwiftData
@testable import sira

/// The values Home's list draws a Match with, and — the reason the type exists
/// — what happens to a card once the Match behind it is gone.
final class HomeCardTests: XCTestCase {
    private func match(
        mode: EntrantMode = .players,
        entrants: [Entrant] = [Entrant(name: "Alice"), Entrant(name: "Bob")],
        rounds: [Round] = [],
        archived: Bool = false
    ) -> Match {
        Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: mode,
            entrants: entrants,
            rounds: rounds,
            archived: archived,
            createdAt: .fixture(year: 2026, month: 3, day: 14, hour: 21)
        )
    }

    private func card(for match: Match) -> HomeCard {
        HomeCard(match: match, variant: .gongaStandard)
    }

    /// The crash this type was introduced for: Home used to hand each row the
    /// Match itself, and SwiftUI redraws a row in the same turn the Match
    /// behind it is deleted. Every property of a deleted model traps, so the
    /// row took the app down with it — reproducibly when another Match was
    /// left on screen to redraw alongside it.
    ///
    /// A card reads its Match once, in its init. This asserts that: the Match
    /// is deleted and saved, and the card still answers.
    func test_aCardStillReadsAfterItsMatchIsDeleted() {
        let store = MatchStore()
        let match = match(rounds: [Round(deltas: [:])])
        store.add(match)
        let card = card(for: match)

        store.delete(match)

        XCTAssertTrue(match.isGone)
        XCTAssertEqual(card.title, "14th March 2026 · 9pm")
        XCTAssertEqual(card.statusText, "Round 2")
        XCTAssertEqual(card.entrantsText, "2 players · to 101")
        XCTAssertEqual(card.variantLabel, "Gonga")
        XCTAssertEqual(card.roundCount, 1)
        XCTAssertFalse(card.archived)
    }

    func test_anUnfinishedMatchIsCardedWithTheRoundItIsOn() {
        let card = card(for: match(rounds: [Round(deltas: [:]), Round(deltas: [:])]))

        XCTAssertEqual(card.statusText, "Round 3")
        XCTAssertFalse(card.statusIsMuted)
    }

    /// Archived-but-unfinished is the one status that reads muted rather than
    /// as the accent-coloured "where the Match is up to" pill.
    func test_anArchivedMatchIsCardedAsArchivedAndMuted() {
        let card = card(for: match(archived: true))

        XCTAssertEqual(card.statusText, "Archived")
        XCTAssertTrue(card.statusIsMuted)
        XCTAssertTrue(card.archived)
    }

    /// A finished Match says so whether or not it was archived, and says it in
    /// the accent colour: the result is what the card is now for.
    func test_aFinishedMatchIsCardedAsFinishedEvenWhenArchived() {
        let alice = Entrant(name: "Alice")
        let bob = Entrant(name: "Bob")
        let card = card(
            for: match(
                entrants: [alice, bob],
                rounds: [Round(deltas: [alice.id: 102, bob.id: 3])],
                archived: true
            )
        )

        XCTAssertEqual(card.statusText, "Finished")
        XCTAssertFalse(card.statusIsMuted)
    }

    func test_teamsAreCountedAsTeamsAndOneOfEitherIsSingular() {
        XCTAssertEqual(card(for: match(mode: .teams)).entrantsText, "2 teams · to 101")
        XCTAssertEqual(
            card(for: match(mode: .teams, entrants: [Entrant(name: "Us")])).entrantsText,
            "1 team · to 101"
        )
        XCTAssertEqual(
            card(for: match(entrants: [Entrant(name: "Alice")])).entrantsText,
            "1 player · to 101"
        )
    }

    // MARK: - The number the Match is played at

    /// The card names the Match by what it is played at as well as who is
    /// playing it, so two Matches of the same Variant over different lengths
    /// are told apart on the list rather than only once one is opened.
    func test_theMetadataLineCarriesTheNumberAsAPhrase() {
        let okey101 = Match(
            game: .okey,
            variant: .okey101,
            number: 12,
            mode: .players,
            entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")]
        )

        XCTAssertEqual(HomeCard(match: okey101, variant: .okey101).entrantsText, "2 players · 12 rounds")
    }

    /// Two Gonga Matches at different limits are one Variant, told apart on
    /// the list by the number rather than by opening them — which is what the
    /// old pair of Variants used to do with their labels.
    func test_aGongaCardCarriesTheLimitThisMatchWasPlayedTo() {
        let entrants = (1...8).map { Entrant(name: "Player \($0)") }
        let toTwoHundredAndOne = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 201,
            mode: .players,
            entrants: entrants
        )
        let toOneOhOne = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: entrants.prefix(4).map { Entrant(name: $0.name) }
        )

        XCTAssertEqual(HomeCard(match: toTwoHundredAndOne, variant: .gongaStandard).entrantsText, "8 players · to 201")
        XCTAssertEqual(HomeCard(match: toOneOhOne, variant: .gongaStandard).entrantsText, "4 players · to 101")
    }

    /// An Okey Match reads back the score it counts down from, and reads it as
    /// a starting score rather than a limit — the phrase is the only thing
    /// that says which of the three numbers it is.
    func test_anOkeyCardCarriesTheStartingScoreThisMatchWasPlayedFrom() {
        let fromThirtyOne = Match(
            game: .okey,
            variant: .okeyStandard,
            number: 31,
            mode: .teams,
            entrants: [Entrant(name: "Us"), Entrant(name: "Them")]
        )
        let fromTwentyOne = Match(
            game: .okey,
            variant: .okeyStandard,
            number: 21,
            mode: .teams,
            entrants: [Entrant(name: "Us"), Entrant(name: "Them")]
        )

        XCTAssertEqual(HomeCard(match: fromThirtyOne, variant: .okeyStandard).entrantsText, "2 teams · from 31")
        XCTAssertEqual(HomeCard(match: fromTwentyOne, variant: .okeyStandard).entrantsText, "2 teams · from 21")
        XCTAssertEqual(HomeCard(match: fromThirtyOne, variant: .okeyStandard).variantLabel, "Okey")
    }

    /// Gonga's label is "Gonga" at every limit: the number it is played to
    /// rides beside the name and is never fused into it.
    func test_gongasLabelIsNeverFusedWithItsLimit() {
        let match = Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 201,
            mode: .players,
            entrants: [Entrant(name: "Alice")]
        )

        let card = HomeCard(match: match, variant: .gongaStandard)

        XCTAssertEqual(card.variantLabel, "Gonga")
        XCTAssertFalse(card.variantLabel.contains("201"))
    }

    /// The phrase reads off the Match's own number, not the Variant's, which is
    /// the whole point of asking for one at Setup.
    func test_theMetadataLineFollowsTheNumberThisMatchChose() {
        let shortMatch = Match(
            game: .okey,
            variant: .okey101,
            number: 5,
            mode: .players,
            entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")]
        )

        XCTAssertEqual(HomeCard(match: shortMatch, variant: .okey101).entrantsText, "2 players · 5 rounds")
    }

    /// The label never absorbs the number: "Okey 101" is the Variant, and the
    /// 12 Rounds it is being played over sit in the metadata line beside it.
    func test_theLabelIsNeverFusedWithTheNumber() {
        let match = Match(
            game: .okey,
            variant: .okey101,
            number: 12,
            mode: .players,
            entrants: [Entrant(name: "Alice")]
        )

        let card = HomeCard(match: match, variant: .okey101)

        XCTAssertEqual(card.variantLabel, "Okey 101")
        XCTAssertFalse(card.variantLabel.contains("12 rounds"))
    }
}
