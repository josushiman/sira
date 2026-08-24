import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

/// The two surfaces deletion puts in front of the player: the menu a
/// press-and-hold on a Match card opens, and the confirmation that stands
/// between its Delete item and the deletion itself.
///
/// The menu's items are snapshot rather than the menu as iOS draws it — a
/// context menu is presented by the system, in the system's own chrome, and
/// nothing renders it into an image. What these pin down is what this app
/// supplies: the wording, the ordering, and Delete's destructive role.
final class MatchDeletionTests: XCTestCase {
    /// A Match dated like the fixtures, so the confirmation names a date that
    /// reads the same on every run.
    private func match(rounds: Int) -> Match {
        let alice = Entrant(name: "Alice")
        return Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [alice, Entrant(name: "Bob")],
            rounds: (0..<rounds).map { Round(deltas: [alice.id: 10 + $0]) },
            createdAt: .fixture(year: 2026, month: 3, day: 14, hour: 21)
        )
    }

    private func assertMenu(theme: Theme, testName: String = #function) {
        let view = VStack(alignment: .leading, spacing: 0) {
            MatchCardMenu {}
        }
        .padding(20)
        .background(theme.background)
        .environment(\.theme, theme)
        .frame(width: 300, height: 90)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 300, height: 90)), testName: testName)
    }

    private func assertConfirmation(theme: Theme, testName: String = #function) {
        let view = DeleteMatchSheet(deletion: PendingDeletion(match: match(rounds: 6)), onDelete: {})
            .environment(\.theme, theme)
            .frame(width: 402, height: 437)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 437)), testName: testName)
    }

    /// The confirmation's wording is the only thing standing between a mis-tap
    /// and an evening's scores, so what it says is asserted rather than left to
    /// a reader of the snapshot.
    func test_theConfirmationNamesTheMatchWhatGoesWithItAndThatThereIsNoUndo() {
        let text = DeleteMatchSheet.explanation(for: PendingDeletion(match: match(rounds: 6)))

        XCTAssertEqual(
            text,
            "14th March 2026 · 9pm, its players and all 6 Rounds played will be deleted for good. There is no undo."
        )
    }

    /// A Match with one Round, and one with none, are the two the plural
    /// wording would read wrong for.
    func test_theConfirmationCountsRoundsInWordsThatFitTheNumber() {
        XCTAssertEqual(
            DeleteMatchSheet.explanation(for: PendingDeletion(match: match(rounds: 1))),
            "14th March 2026 · 9pm, its players and the 1 Round played will be deleted for good. There is no undo."
        )
        XCTAssertEqual(
            DeleteMatchSheet.explanation(for: PendingDeletion(match: match(rounds: 0))),
            "14th March 2026 · 9pm and its players will be deleted for good. There is no undo."
        )
    }

    func test_contextMenu_paper() {
        assertMenu(theme: .paper)
    }

    func test_contextMenu_felt() {
        assertMenu(theme: .felt)
    }

    func test_deleteConfirmation_paper() {
        assertConfirmation(theme: .paper)
    }

    func test_deleteConfirmation_felt() {
        assertConfirmation(theme: .felt)
    }
}
