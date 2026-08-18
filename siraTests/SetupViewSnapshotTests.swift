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

    func test_gonga_playersModeVariant_paper() {
        assertSetup(.gonga101, theme: .paper)
    }

    func test_gonga_playersModeVariant_felt() {
        assertSetup(.gonga101, theme: .felt)
    }

    func test_okeyStandard_teamsOnlyVariant_paper() {
        assertSetup(.okeyStandard, theme: .paper)
    }

    func test_okeyStandard_teamsOnlyVariant_felt() {
        assertSetup(.okeyStandard, theme: .felt)
    }

    func test_okey101_roundCountChips_paper() {
        assertSetup(.okey101, theme: .paper)
    }

    func test_okey101_roundCountChips_felt() {
        assertSetup(.okey101, theme: .felt)
    }
}
