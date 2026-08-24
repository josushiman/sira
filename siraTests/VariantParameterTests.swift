import XCTest
@testable import sira

/// The number a Variant is played at, driven the way Setup drives it — chips
/// tapped, digits typed — with no view involved, the way `RoundEntryStateTests`
/// drives its struct.
final class VariantParameterTests: XCTestCase {

    // MARK: - What each Variant offers

    func test_okey101OffersEightAndTwelveWithTwelvePreselected() {
        let parameter = VariantParameter(for: .okey101)

        XCTAssertEqual(parameter.kind, .roundCount)
        XCTAssertEqual(parameter.presets, [8, 12])
        XCTAssertEqual(parameter.selection, .preset(12))
        XCTAssertEqual(parameter.value, 12)
        XCTAssertFalse(parameter.isCustom)
    }

    /// Gonga's chips become `101 · 151` once its two Variants merge into one.
    /// Until then each Gonga offers the one limit it ships with, so Setup asks
    /// the same question of it that it asks of Okey 101.
    func test_aSurvivalVariantOffersTheLimitItShipsWith() {
        let parameter = VariantParameter(for: .gonga151)

        XCTAssertEqual(parameter.kind, .limit)
        XCTAssertEqual(parameter.presets, [151])
        XCTAssertEqual(parameter.selection, .preset(151))
    }

    func test_anEliminationVariantOffersTheStartingScoreItShipsWith() {
        let parameter = VariantParameter(for: .okey21)

        XCTAssertEqual(parameter.kind, .startingScore)
        XCTAssertEqual(parameter.presets, [21])
        XCTAssertEqual(parameter.selection, .preset(21))
    }

    // MARK: - Choosing a number

    func test_tappingAPresetChoosesIt() {
        var parameter = VariantParameter(for: .okey101)

        parameter.select(8)

        XCTAssertEqual(parameter.value, 8)
        XCTAssertTrue(parameter.isStartable)
    }

    func test_customRevealsTheFieldAndTakesWhatIsTyped() {
        var parameter = VariantParameter(for: .okey101)

        parameter.selectCustom()
        XCTAssertTrue(parameter.isCustom)
        XCTAssertNil(parameter.value, "Custom starts empty rather than seeded with the preset")

        parameter.enterCustom("5")

        XCTAssertEqual(parameter.value, 5)
        XCTAssertTrue(parameter.isStartable)
    }

    /// A preset is a whole answer, not a correction to the custom value, so
    /// returning to one leaves nothing of what was typed behind — a later tap
    /// back onto Custom asks the question fresh rather than re-offering a
    /// number the player has already moved off.
    func test_returningToAPresetDiscardsTheCustomValue() {
        var parameter = VariantParameter(for: .okey101)
        parameter.enterCustom("5")

        parameter.select(12)
        XCTAssertEqual(parameter.value, 12)

        parameter.selectCustom()
        XCTAssertNil(parameter.value)
    }

    // MARK: - The range, and what happens outside it

    func test_bothEndsOfEachRangeStartAMatch() {
        assertStartable(.okey101, [1, 50])
        assertStartable(.gonga101, [11, 999])
        assertStartable(.okey21, [2, 99])
    }

    func test_theValuesJustOutsideEachRangeDoNot() {
        assertNotStartable(.okey101, [0, 51])
        assertNotStartable(.gonga101, [10, 1000])
        assertNotStartable(.okey21, [1, 100])
    }

    /// The number the player typed is the number they see. Clamping 500 to 50
    /// would start a Match at a length nobody chose, and the player would have
    /// no way of knowing it had happened.
    func test_anOutOfRangeValueIsLeftExactlyAsTyped() {
        var parameter = VariantParameter(for: .okey101)

        parameter.enterCustom("500")

        XCTAssertEqual(parameter.customText, "500")
        XCTAssertEqual(parameter.value, 500)
        XCTAssertFalse(parameter.isStartable)
    }

    func test_anEmptyFieldStartsNothingAndBlamesNoValue() {
        var parameter = VariantParameter(for: .okey101)

        parameter.selectCustom()

        XCTAssertFalse(parameter.isStartable)
        XCTAssertEqual(parameter.unstartableReason, "Rounds must be between 1 and 50")
    }

    func test_aRefusedValueSaysWhyInTheNumbersItWasJudgedBy() {
        var parameter = VariantParameter(for: .okey101)
        parameter.enterCustom("51")
        XCTAssertEqual(parameter.unstartableReason, "Rounds must be between 1 and 50")

        var gonga = VariantParameter(for: .gonga101)
        gonga.enterCustom("5")
        XCTAssertEqual(gonga.unstartableReason, "Limit must be between 11 and 999")

        var okey = VariantParameter(for: .okey21)
        okey.enterCustom("100")
        XCTAssertEqual(okey.unstartableReason, "Starting score must be between 2 and 99")
    }

    func test_aStartableValueHasNothingToExplain() {
        XCTAssertNil(VariantParameter(for: .okey101).unstartableReason)
    }

    // MARK: - How the number reads

    /// The phrase is the only thing that says which of the three numbers this
    /// is, so a card never has to carry a label saying "limit" or "rounds".
    func test_eachKindOfNumberReadsAsItsOwnPhrase() {
        XCTAssertEqual(VariantParameter.Kind.limit.phrase(for: 201), "to 201")
        XCTAssertEqual(VariantParameter.Kind.startingScore.phrase(for: 21), "from 21")
        XCTAssertEqual(VariantParameter.Kind.roundCount.phrase(for: 12), "12 rounds")
    }

    func test_aSingleRoundIsNotPluralised() {
        XCTAssertEqual(VariantParameter.Kind.roundCount.phrase(for: 1), "1 round")
    }

    func test_theKindFollowsFromTheWinCondition() {
        XCTAssertEqual(VariantParameter.Kind(.survival), .limit)
        XCTAssertEqual(VariantParameter.Kind(.elimination), .startingScore)
        XCTAssertEqual(VariantParameter.Kind(.fixedRounds), .roundCount)
    }

    // MARK: - Tapping a chip

    /// The chip row hands back whichever chip was tapped, and the parameter
    /// takes it apart — so what Setup calls is what these tests call.
    func test_choosingAChipTakesEitherKind() {
        var parameter = VariantParameter(for: .okey101)

        parameter.choose(.custom)
        XCTAssertTrue(parameter.isCustom)

        parameter.enterCustom("5")
        parameter.choose(.preset(8))

        XCTAssertEqual(parameter.value, 8)
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
            var parameter = VariantParameter(for: variant)
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
            var parameter = VariantParameter(for: variant)
            parameter.enterCustom("\(value)")
            XCTAssertFalse(parameter.isStartable, "\(value) should not start \(variant.label)", file: file, line: line)
        }
    }
}
