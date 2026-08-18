import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

final class RejoinSheetSnapshotTests: XCTestCase {
    private func assertRejoin(theme: Theme, testName: String = #function) {
        let view = RejoinSheet(
            entrant: Entrant(name: "Ali"),
            score: 112,
            limit: 101,
            target: 84,
            onAccept: {}
        )
        .environment(\.theme, theme)
        .frame(width: 402, height: 437)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 437)), testName: testName)
    }

    func test_rejoinSheet_paper() {
        assertRejoin(theme: .paper)
    }

    func test_rejoinSheet_felt() {
        assertRejoin(theme: .felt)
    }
}
