import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

final class RoundEntryViewSnapshotTests: XCTestCase {
    private let alice = Entrant(name: "Alice")
    private let bob = Entrant(name: "Bob")
    private let cem = Entrant(name: "Cem")

    private var entrants: [Entrant] { [alice, bob, cem] }
    private var totals: [Entrant.ID: Int] { [alice.id: 34, bob.id: 12, cem.id: 61] }
    private var badgeIndices: [Entrant.ID: Int] { [alice.id: 0, bob.id: 1, cem.id: 2] }

    private func assertEntry(
        initialState: RoundEntryState? = nil,
        neverLaidDownValue: Int? = nil,
        supportsCifte: Bool = true,
        game: Game = .okey,
        theme: Theme,
        testName: String = #function
    ) {
        let view = RoundEntryView(
            entrants: entrants,
            roundNumber: 3,
            totals: totals,
            badgeIndices: badgeIndices,
            neverLaidDownValue: neverLaidDownValue,
            supportsCifte: supportsCifte,
            game: game,
            initialState: initialState
        ) { _, _, _ in }
        .environment(\.theme, theme)
        .frame(width: 402, height: 874)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 874)), testName: testName)
    }

    func test_noValueEnteredYet_paper() {
        assertEntry(theme: .paper)
    }

    func test_noValueEnteredYet_felt() {
        assertEntry(theme: .felt)
    }

    private var partialValueState: RoundEntryState {
        var state = RoundEntryState(entrants: entrants)
        state.appendDigit("2")
        state.appendDigit("4")
        return state
    }

    func test_activeRowWithPartialValue_paper() {
        assertEntry(initialState: partialValueState, theme: .paper)
    }

    func test_activeRowWithPartialValue_felt() {
        assertEntry(initialState: partialValueState, theme: .felt)
    }

    /// The active row is a Çifte caller who hasn't won, so its chip is lit and
    /// its meta line carries both the mark and a ×2 preview.
    private var cifteCallerState: RoundEntryState {
        var state = partialValueState
        state.toggleCifteForActive()
        return state
    }

    func test_activeRowIsACifteCaller_paper() {
        assertEntry(initialState: cifteCallerState, theme: .paper)
    }

    func test_activeRowIsACifteCaller_felt() {
        assertEntry(initialState: cifteCallerState, theme: .felt)
    }

    /// Alice called Çifte and lost while Cem finished on the joker, so Alice's
    /// row previews ×4 and everyone else's ×2 — the surprising number the
    /// meta line exists to explain.
    private var quadrupledRowState: RoundEntryState {
        var state = cifteCallerState
        state.selectActive(bob.id)
        state.appendDigit("8")
        state.selectActive(cem.id)
        state.toggleOkeyAtanForActive()
        state.selectActive(alice.id)
        return state
    }

    func test_rowPreviewingQuadruple_paper() {
        assertEntry(initialState: quadrupledRowState, theme: .paper)
    }

    func test_rowPreviewingQuadruple_felt() {
        assertEntry(initialState: quadrupledRowState, theme: .felt)
    }

    func test_okey101NeverLaidDownShortcut_paper() {
        assertEntry(neverLaidDownValue: 101, theme: .paper)
    }

    /// Gonga has no Çifte concept, so its entry screen hides that chip — but
    /// the joker finish is played at every table, under a card-table name.
    func test_gongaShowsJokeriAttiWithoutACifteChip_paper() {
        assertEntry(supportsCifte: false, game: .gonga, theme: .paper)
    }

    func test_gongaShowsJokeriAttiWithoutACifteChip_felt() {
        assertEntry(supportsCifte: false, game: .gonga, theme: .felt)
    }

    /// The Gonga label applies to the marked row's meta line too, not just the
    /// chip.
    func test_gongaOkeyAtanRow_paper() {
        var state = RoundEntryState(entrants: entrants, supportsCifte: false)
        state.selectActive(bob.id)
        state.toggleOkeyAtanForActive()
        assertEntry(initialState: state, supportsCifte: false, game: .gonga, theme: .paper)
    }
}
