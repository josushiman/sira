import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

/// The rename sheet's visual decisions, in the two themes — the mode-aware
/// copy and the refused-name state, neither of which prose pins down. Shaped
/// after `RejoinSheetSnapshotTests`, the other sheet on this screen.
final class RenameEntrantSheetSnapshotTests: XCTestCase {
    private static let players = [
        Entrant(name: "Ali").withSequence(0),
        Entrant(name: "Veli").withSequence(1)
    ]
    private static let teams = [
        Entrant(name: "Bizimkiler").withSequence(0),
        Entrant(name: "Onlar").withSequence(1)
    ]

    private func assertRename(
        entrants: [Entrant],
        renaming index: Int = 0,
        mode: EntrantMode,
        initialName: String? = nil,
        theme: Theme,
        testName: String = #function
    ) {
        let view = RenameEntrantSheet(
            entrant: entrants[index],
            entrants: entrants,
            mode: mode,
            initialName: initialName,
            onSave: { _ in }
        )
        .environment(\.theme, theme)
        .frame(width: 402, height: 500)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 500)), testName: testName)
    }

    /// Player copy: "Nothing this player has scored changes."
    func test_renameSheet_playerCopy_paper() {
        assertRename(entrants: Self.players, mode: .players, theme: .paper)
    }

    func test_renameSheet_playerCopy_felt() {
        assertRename(entrants: Self.players, mode: .players, theme: .felt)
    }

    /// Team copy, off the Match's own Entrant mode rather than its Game.
    func test_renameSheet_teamCopy_paper() {
        assertRename(entrants: Self.teams, mode: .teams, theme: .paper)
    }

    func test_renameSheet_teamCopy_felt() {
        assertRename(entrants: Self.teams, mode: .teams, theme: .felt)
    }

    /// Ali typed onto Veli's name: the clash is named under the field and Save
    /// is dimmed, rather than the sheet accepting the tap and failing later.
    func test_renameSheet_duplicateName_paper() {
        assertRename(entrants: Self.players, mode: .players, initialName: "veli", theme: .paper)
    }

    func test_renameSheet_duplicateName_felt() {
        assertRename(entrants: Self.players, mode: .players, initialName: "veli", theme: .felt)
    }
}
