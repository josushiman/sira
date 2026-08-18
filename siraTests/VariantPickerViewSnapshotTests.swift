import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

final class VariantPickerViewSnapshotTests: XCTestCase {
    private func assertVariantPicker(_ game: Game, theme: Theme, testName: String = #function) {
        let view = NavigationStack {
            VariantPickerView(game: game)
        }
        .environment(\.theme, theme)
        .frame(width: 402, height: 874)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 874)), testName: testName)
    }

    func test_gonga_singleVariant_paper() {
        assertVariantPicker(.gonga, theme: .paper)
    }

    func test_gonga_singleVariant_felt() {
        assertVariantPicker(.gonga, theme: .felt)
    }

    func test_okey_teamsOnlyVariant_paper() {
        assertVariantPicker(.okey, theme: .paper)
    }

    func test_okey_teamsOnlyVariant_felt() {
        assertVariantPicker(.okey, theme: .felt)
    }
}
