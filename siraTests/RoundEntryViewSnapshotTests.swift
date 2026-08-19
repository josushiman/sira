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
            initialState: initialState
        ) { _, _ in }
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

    func test_cifteOn_paper() {
        var state = partialValueState
        state.cifteOn = true
        assertEntry(initialState: state, theme: .paper)
    }

    func test_cifteOn_felt() {
        var state = partialValueState
        state.cifteOn = true
        assertEntry(initialState: state, theme: .felt)
    }

    func test_okey101NeverLaidDownShortcut_paper() {
        assertEntry(neverLaidDownValue: 101, theme: .paper)
    }

    /// Gonga has no Çifte concept, so its entry screen shows only the
    /// "Won the round" shortcut.
    func test_gongaHidesTheCifteChip_paper() {
        assertEntry(supportsCifte: false, theme: .paper)
    }

    func test_gongaHidesTheCifteChip_felt() {
        assertEntry(supportsCifte: false, theme: .felt)
    }
}
