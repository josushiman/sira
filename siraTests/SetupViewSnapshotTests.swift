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

    /// Eight players, and the limit chips the two Gonga Variants collapsed
    /// into: `101 · 151 · Custom`, opening on 101 with the rules read back at
    /// it.
    func test_gonga_playerCountUpToEightAndLimitChips_paper() {
        assertSetup(.gongaStandard, theme: .paper)
    }

    func test_gonga_playerCountUpToEightAndLimitChips_felt() {
        assertSetup(.gongaStandard, theme: .felt)
    }

    /// Custom tapped and 201 typed into the revealed field, with the rules
    /// following it up: "Go over 201 and you're Out."
    private var customLimit: VariantParameter {
        var parameter = VariantParameter(for: .gongaStandard)
        parameter.enterCustom("201")
        return parameter
    }

    func test_gonga_customLimitRevealsTheField_paper() {
        assertSetup(.gongaStandard, parameter: customLimit, theme: .paper)
    }

    func test_gonga_customLimitRevealsTheField_felt() {
        assertSetup(.gongaStandard, parameter: customLimit, theme: .felt)
    }

    /// Out of range: 5 is still in the field, Start is dimmed, and the reason
    /// sits above the button that will not work.
    private var refusedLimit: VariantParameter {
        var parameter = VariantParameter(for: .gongaStandard)
        parameter.enterCustom("5")
        return parameter
    }

    func test_gonga_anOutOfRangeLimitCannotStart_paper() {
        assertSetup(.gongaStandard, parameter: refusedLimit, theme: .paper)
    }

    func test_gonga_anOutOfRangeLimitCannotStart_felt() {
        assertSetup(.gongaStandard, parameter: refusedLimit, theme: .felt)
    }

    /// Two teams and no player-count selector, with the starting score chips
    /// `21 · Custom` opening on 21 and the rules read back at it.
    func test_okeyStandard_teamsOnlyVariant_paper() {
        assertSetup(.okeyStandard, theme: .paper)
    }

    func test_okeyStandard_teamsOnlyVariant_felt() {
        assertSetup(.okeyStandard, theme: .felt)
    }

    /// Custom tapped and 31 typed into the revealed field, with the rules
    /// counting down from it.
    private var customStartingScore: VariantParameter {
        var parameter = VariantParameter(for: .okeyStandard)
        parameter.enterCustom("31")
        return parameter
    }

    func test_okeyStandard_customStartingScoreRevealsTheField_paper() {
        assertSetup(.okeyStandard, parameter: customStartingScore, theme: .paper)
    }

    func test_okeyStandard_customStartingScoreRevealsTheField_felt() {
        assertSetup(.okeyStandard, parameter: customStartingScore, theme: .felt)
    }

    /// Out of range: 100 is still in the field, Start is dimmed, and the reason
    /// sits above the button that will not work.
    private var refusedStartingScore: VariantParameter {
        var parameter = VariantParameter(for: .okeyStandard)
        parameter.enterCustom("100")
        return parameter
    }

    func test_okeyStandard_anOutOfRangeStartingScoreCannotStart_paper() {
        assertSetup(.okeyStandard, parameter: refusedStartingScore, theme: .paper)
    }

    func test_okeyStandard_anOutOfRangeStartingScoreCannotStart_felt() {
        assertSetup(.okeyStandard, parameter: refusedStartingScore, theme: .felt)
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
