import XCTest
@testable import sira

/// The number a Variant is played at, driven the way Setup drives it — chips
/// tapped, digits typed — with no view involved, the way `RoundEntryStateTests`
/// drives its struct.
final class VariantParameterTests: XCTestCase {

    // MARK: - What each Variant offers

    func test_okey101NeedsNoSetupNumber() {
        XCTAssertNil(VariantParameter(for: .okey101))
        XCTAssertNil(Variant.okey101.parameterKind)
    }

    /// The two Gongas are one Variant with two chips: 101 is the game most
    /// tables play and opens preselected, and 151 — the second-most-common,
    /// and a whole Variant until now — is a single tap rather than a typing
    /// exercise.
    func test_gongaOffers101And151With101Preselected() {
        let parameter = VariantParameter(for: .gongaStandard)!

        XCTAssertEqual(parameter.kind, .limit)
        XCTAssertEqual(parameter.presets, [101, 151])
        XCTAssertEqual(parameter.selection, .preset(101))
        XCTAssertEqual(parameter.value, 101)
        XCTAssertFalse(parameter.isCustom)
    }

    /// Okey has one preset and a Custom chip beside it. 21 stays a chip rather
    /// than becoming a bare prefilled field, so the standard game is something
    /// the player chooses rather than a default they failed to change.
    func test_okeyOffers21Preselected() {
        let parameter = VariantParameter(for: .okeyStandard)!

        XCTAssertEqual(parameter.kind, .startingScore)
        XCTAssertEqual(parameter.presets, [21])
        XCTAssertEqual(parameter.selection, .preset(21))
        XCTAssertEqual(parameter.value, 21)
        XCTAssertFalse(parameter.isCustom)
    }

    func test_okeyTakesACustomStartingScore() {
        var parameter = VariantParameter(for: .okeyStandard)!

        parameter.enterCustom("31")

        XCTAssertTrue(parameter.isCustom)
        XCTAssertEqual(parameter.value, 31)
        XCTAssertTrue(parameter.isStartable)
    }

    // MARK: - Choosing a number

    func test_tappingAPresetChoosesIt() {
        var parameter = VariantParameter(for: .gongaStandard)!

        parameter.select(151)

        XCTAssertEqual(parameter.value, 151)
        XCTAssertTrue(parameter.isStartable)
    }

    func test_customRevealsTheFieldAndTakesWhatIsTyped() {
        var parameter = VariantParameter(for: .gongaStandard)!

        parameter.selectCustom()
        XCTAssertTrue(parameter.isCustom)
        XCTAssertNil(parameter.value, "Custom starts empty rather than seeded with the preset")

        parameter.enterCustom("201")

        XCTAssertEqual(parameter.value, 201)
        XCTAssertTrue(parameter.isStartable)
    }

    /// A preset is a whole answer, not a correction to the custom value, so
    /// returning to one leaves nothing of what was typed behind — a later tap
    /// back onto Custom asks the question fresh rather than re-offering a
    /// number the player has already moved off.
    func test_returningToAPresetDiscardsTheCustomValue() {
        var parameter = VariantParameter(for: .gongaStandard)!
        parameter.enterCustom("201")

        parameter.select(151)
        XCTAssertEqual(parameter.value, 151)

        parameter.selectCustom()
        XCTAssertNil(parameter.value)
    }

    // MARK: - The range, and what happens outside it

    func test_bothEndsOfEachRangeStartAMatch() {
        assertStartable(.gongaStandard, [11, 999])
        assertStartable(.okeyStandard, [2, 99])
    }

    func test_theValuesJustOutsideEachRangeDoNot() {
        assertNotStartable(.gongaStandard, [10, 1000])
        assertNotStartable(.okeyStandard, [1, 100])
    }

    /// The number the player typed is the number they see. Clamping 1000 to 999
    /// would start a Match at a limit nobody chose, and the player would have
    /// no way of knowing it had happened.
    func test_anOutOfRangeValueIsLeftExactlyAsTyped() {
        var parameter = VariantParameter(for: .gongaStandard)!

        parameter.enterCustom("1000")

        XCTAssertEqual(parameter.customText, "1000")
        XCTAssertEqual(parameter.value, 1000)
        XCTAssertFalse(parameter.isStartable)
    }

    func test_anEmptyFieldStartsNothingAndBlamesNoValue() {
        var parameter = VariantParameter(for: .gongaStandard)!

        parameter.selectCustom()

        XCTAssertFalse(parameter.isStartable)
        XCTAssertEqual(parameter.unstartableReason, "Limit must be between 11 and 999")
    }

    func test_aRefusedValueSaysWhyInTheNumbersItWasJudgedBy() {
        var gonga = VariantParameter(for: .gongaStandard)!
        gonga.enterCustom("5")
        XCTAssertEqual(gonga.unstartableReason, "Limit must be between 11 and 999")

        var okey = VariantParameter(for: .okeyStandard)!
        okey.enterCustom("100")
        XCTAssertEqual(okey.unstartableReason, "Starting score must be between 2 and 99")
    }

    func test_aStartableValueHasNothingToExplain() {
        XCTAssertNil(VariantParameter(for: .gongaStandard)!.unstartableReason)
    }

    // MARK: - How the number reads

    /// The phrase is the only thing that says which score this
    /// is, so a card never has to carry a label saying "limit" or "starting score".
    func test_eachKindOfNumberReadsAsItsOwnPhrase() {
        XCTAssertEqual(VariantParameter.Kind.limit.phrase(for: 201), "to 201")
        XCTAssertEqual(VariantParameter.Kind.startingScore.phrase(for: 21), "from 21")
    }

    func test_theKindFollowsFromTheWinCondition() {
        XCTAssertEqual(VariantParameter.Kind(.survival), .limit)
        XCTAssertEqual(VariantParameter.Kind(.elimination), .startingScore)
        XCTAssertNil(VariantParameter.Kind(.lowestTotal))
    }

    // MARK: - Tapping a chip

    /// The chip row hands back whichever chip was tapped, and the parameter
    /// takes it apart — so what Setup calls is what these tests call.
    func test_choosingAChipTakesEitherKind() {
        var parameter = VariantParameter(for: .gongaStandard)!

        parameter.choose(.custom)
        XCTAssertTrue(parameter.isCustom)

        parameter.enterCustom("201")
        parameter.choose(.preset(151))

        XCTAssertEqual(parameter.value, 151)
        XCTAssertEqual(parameter.customText, "", "A preset discards the custom value however it is tapped")
    }

    // MARK: - Helpers

    private func assertStartable(
        _ variant: Variant,
        _ values: [Int],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for value in values {
            var parameter = VariantParameter(for: variant)!
            parameter.enterCustom("\(value)")
            XCTAssertTrue(parameter.isStartable, "\(value) should start \(variant.label)", file: file, line: line)
        }
    }

    private func assertNotStartable(
        _ variant: Variant,
        _ values: [Int],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for value in values {
            var parameter = VariantParameter(for: variant)!
            parameter.enterCustom("\(value)")
            XCTAssertFalse(parameter.isStartable, "\(value) should not start \(variant.label)", file: file, line: line)
        }
    }
}
