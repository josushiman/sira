import XCTest
import SwiftUI
import SnapshotTesting
@testable import sira

final class SetupViewSnapshotTests: XCTestCase {
    private func assertSetup(
        _ variant: Variant,
        parameter: VariantParameter? = nil,
        theme: Theme,
        testName: String = #function
    ) {
        let view = NavigationStack {
            SetupView(variant: variant, initialParameter: parameter)
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

    /// The preselected state the screen opens on: 12 of `8 · 12 · Custom`,
    /// with the rules read back at 12.
    func test_okey101_roundCountChips_paper() {
        assertSetup(.okey101, theme: .paper)
    }

    func test_okey101_roundCountChips_felt() {
        assertSetup(.okey101, theme: .felt)
    }

    /// Custom tapped and a Round count typed into the revealed field, with the
    /// rules following it down to 5.
    private var customRoundCount: VariantParameter {
        var parameter = VariantParameter(for: .okey101)
        parameter.enterCustom("5")
        return parameter
    }

    func test_okey101_customRoundCountRevealsTheField_paper() {
        assertSetup(.okey101, parameter: customRoundCount, theme: .paper)
    }

    func test_okey101_customRoundCountRevealsTheField_felt() {
        assertSetup(.okey101, parameter: customRoundCount, theme: .felt)
    }

    /// Out of range: the typed number is still there, Start is dimmed, and the
    /// reason sits directly above the button that will not work.
    private var refusedRoundCount: VariantParameter {
        var parameter = VariantParameter(for: .okey101)
        parameter.enterCustom("500")
        return parameter
    }

    func test_okey101_anOutOfRangeRoundCountCannotStart_paper() {
        assertSetup(.okey101, parameter: refusedRoundCount, theme: .paper)
    }

    func test_okey101_anOutOfRangeRoundCountCannotStart_felt() {
        assertSetup(.okey101, parameter: refusedRoundCount, theme: .felt)
    }
}
