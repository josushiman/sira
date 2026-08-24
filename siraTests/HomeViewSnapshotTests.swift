import XCTest
import SwiftUI
import SwiftData
import SnapshotTesting
@testable import sira

final class HomeViewSnapshotTests: XCTestCase {
    private func assertHome(_ store: MatchStore, theme: Theme, testName: String = #function) {
        let view = NavigationStack {
            HomeView()
        }
        .environment(store)
        .environment(Navigator())
        // Home reads its Matches with `@Query`, which reads the container
        // rather than the store object — without this it renders an empty list
        // whatever the store holds.
        .modelContainer(store.container)
        .environment(\.theme, theme)
        .frame(width: 402, height: 1200)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 1200)), testName: testName)
    }

    func test_populatedMatchListAndInlineGameCards_paper() {
        assertHome(.seeded(), theme: .paper)
    }

    func test_populatedMatchListAndInlineGameCards_felt() {
        assertHome(.seeded(), theme: .felt)
    }

    /// Two Gonga Matches, one to 101 and one to 201. They carry the same
    /// label, so the metadata line is the only thing telling them apart — the
    /// job the two old Gonga Variants used to do with their names.
    ///
    /// The second seats eight, which is also the widest that line gets:
    /// `8 players · to 201` beside a Round pill and the Variant label, in a
    /// row that neither wraps nor truncates. A custom limit is what made it
    /// long enough to be worth pinning.
    private func storeWithTwoLimits() -> MatchStore {
        let store = MatchStore()

        let alice = Entrant(name: "Alice")
        let bob = Entrant(name: "Bob")
        store.add(Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [alice, bob],
            rounds: [Round(deltas: [alice.id: 20, bob.id: 15])],
            createdAt: .fixture(year: 2026, month: 3, day: 14, hour: 21)
        ))

        let eight = ["Carol", "Dede", "Emre", "Fatma", "Gizem", "Hakan", "Işıl", "Kerem"]
            .map { Entrant(name: $0) }
        store.add(Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 201,
            mode: .players,
            entrants: eight,
            rounds: [Round(deltas: Dictionary(uniqueKeysWithValues: eight.enumerated().map { ($0.element.id, $0.offset * 20) }))],
            createdAt: .fixture(year: 2026, month: 3, day: 12, hour: 20)
        ))

        return store
    }

    func test_twoMatchesOfOneVariantAtDifferentLimits_paper() {
        assertHome(storeWithTwoLimits(), theme: .paper)
    }

    func test_twoMatchesOfOneVariantAtDifferentLimits_felt() {
        assertHome(storeWithTwoLimits(), theme: .felt)
    }

    func test_emptyState_paper() {
        assertHome(MatchStore(), theme: .paper)
    }

    func test_emptyState_felt() {
        assertHome(MatchStore(), theme: .felt)
    }
}
