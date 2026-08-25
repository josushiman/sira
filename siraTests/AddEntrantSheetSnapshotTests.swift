import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

/// The Add sheet's visual decisions, in the two themes — the mode-aware copy,
/// the free seat's badge colour, and the refused-name state. Shaped after
/// `RenameEntrantSheetSnapshotTests`, whose sheet this one is deliberately the
/// twin of.
final class AddEntrantSheetSnapshotTests: XCTestCase {
    private func match(mode: EntrantMode, names: [String]) -> Match {
        let entrants = names.map { Entrant(name: $0) }
        return Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: mode,
            entrants: entrants,
            rounds: [Round(deltas: [entrants[0].id: 61, entrants[1].id: 40])]
        )
    }

    private func assertAdd(
        mode: EntrantMode,
        names: [String],
        initialName: String = "",
        theme: Theme,
        testName: String = #function
    ) throws {
        let match = match(mode: mode, names: names)
        let addition = try XCTUnwrap(
            RosterAddition(
                match: match,
                variant: .gongaStandard,
                standings: SurvivalEngine().standings(for: match)
            )
        )
        let view = AddEntrantSheet(
            addition: addition,
            entrants: match.entrants,
            mode: mode,
            initialName: initialName,
            onAdd: { _ in }
        )
        .environment(\.theme, theme)
        .frame(width: 402, height: 500)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 500)), testName: testName)
    }

    /// The untouched field: the placeholder names the free seat's fallback,
    /// the badge already wears that seat's colour, and the button says the
    /// number the row promised.
    func test_addSheet_playerCopy_paper() throws {
        try assertAdd(mode: .players, names: ["Ali", "Veli"], theme: .paper)
    }

    func test_addSheet_playerCopy_felt() throws {
        try assertAdd(mode: .players, names: ["Ali", "Veli"], theme: .felt)
    }

    /// Team copy, off the Match's own Entrant mode rather than its Game.
    func test_addSheet_teamCopy_paper() throws {
        try assertAdd(mode: .teams, names: ["Bizimkiler", "Onlar"], theme: .paper)
    }

    func test_addSheet_teamCopy_felt() throws {
        try assertAdd(mode: .teams, names: ["Bizimkiler", "Onlar"], theme: .felt)
    }

    /// A name already at the table: nobody is being renamed here, so nobody is
    /// exempt — the clash is named under the field and Add is dimmed.
    func test_addSheet_duplicateName_paper() throws {
        try assertAdd(mode: .players, names: ["Ali", "Veli"], initialName: "veli", theme: .paper)
    }

    func test_addSheet_duplicateName_felt() throws {
        try assertAdd(mode: .players, names: ["Ali", "Veli"], initialName: "veli", theme: .felt)
    }
}
