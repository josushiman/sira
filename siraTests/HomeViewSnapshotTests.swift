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

    func test_emptyState_paper() {
        assertHome(MatchStore(), theme: .paper)
    }

    func test_emptyState_felt() {
        assertHome(MatchStore(), theme: .felt)
    }
}
