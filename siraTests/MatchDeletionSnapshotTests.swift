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
final class MatchDeletionSnapshotTests: XCTestCase {
    /// A Match dated like the fixtures, so the confirmation names a date that
    /// reads the same on every run.
    private func match(rounds: Int) -> Match {
        let alice = Entrant(name: "Alice")
        return Match(
            game: .gonga,
            variant: .gonga101,
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
