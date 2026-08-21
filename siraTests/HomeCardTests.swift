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
            variant: .gonga101,
            mode: mode,
            entrants: entrants,
            rounds: rounds,
            archived: archived,
            createdAt: .fixture(year: 2026, month: 3, day: 14, hour: 21)
        )
    }

    private func card(for match: Match) -> HomeCard {
        HomeCard(match: match, variant: .gonga101)
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
        XCTAssertEqual(card.entrantsText, "2 players")
        XCTAssertEqual(card.variantLabel, "Gonga 101")
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
        XCTAssertEqual(card(for: match(mode: .teams)).entrantsText, "2 teams")
        XCTAssertEqual(
            card(for: match(mode: .teams, entrants: [Entrant(name: "Us")])).entrantsText,
            "1 team"
        )
        XCTAssertEqual(
            card(for: match(entrants: [Entrant(name: "Alice")])).entrantsText,
            "1 player"
        )
    }
}
