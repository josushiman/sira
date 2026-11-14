import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

final class VariantPickerViewSnapshotTests: XCTestCase {
    private func assertVariantPicker(_ game: Game, theme: Theme, testName: String = #function) {
        // NavigationLinks need a navigation environment. The legacy stack host
        // avoids iOS 27 NavigationStack inset feedback between image renders.
        let view = NavigationView {
            VariantPickerView(game: game)
        }
        .navigationViewStyle(.stack)
        .environment(\.theme, theme)
        .frame(width: 402, height: 874)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 402, height: 874)), testName: testName)
    }

    // Gonga has no cases here any more. It resolves to one Variant, so Home
    // opens Setup for it and the Picker is never on screen — a snapshot of it
    // would be a recording of a screen the app cannot reach.

    func test_okey_bothVariants_paper() {
        assertVariantPicker(.okey, theme: .paper)
    }

    func test_okey_bothVariants_felt() {
        assertVariantPicker(.okey, theme: .felt)
    }
}
