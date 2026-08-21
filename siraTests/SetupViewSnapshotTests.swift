import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

final class SetupViewSnapshotTests: XCTestCase {
    private func assertSetup(_ variant: Variant, theme: Theme, testName: String = #function) {
        let view = NavigationStack {
            SetupView(variant: variant)
        }
        .environment(MatchStore())
        .environment(\.theme, theme)
        .frame(width: 402, height: 874)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 874)), testName: testName)
    }

    func test_gonga101_playerCountUpToEight_paper() {
        assertSetup(.gonga101, theme: .paper)
    }

    func test_gonga101_playerCountUpToEight_felt() {
        assertSetup(.gonga101, theme: .felt)
    }

    func test_okey21_teamsOnlyVariant_paper() {
        assertSetup(.okey21, theme: .paper)
    }

    func test_okey21_teamsOnlyVariant_felt() {
        assertSetup(.okey21, theme: .felt)
    }

    func test_okey101_roundCountChips_paper() {
        assertSetup(.okey101, theme: .paper)
    }

    func test_okey101_roundCountChips_felt() {
        assertSetup(.okey101, theme: .felt)
    }
}
