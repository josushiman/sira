import XCTest
@testable import sira

final class RoundEntryStateTests: XCTestCase {
    func test_initiallyActivatesTheFirstEntrantAndHasNoEnteredValues() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let state = RoundEntryState(entrants: [a, b])

        XCTAssertEqual(state.activeEntrantID, a.id)
        XCTAssertNil(state.enteredValue(for: a.id))
        XCTAssertFalse(state.isReadyToSave)
        XCTAssertTrue(state.rawDeltas.isEmpty)
    }

    func test_tappingARowMakesItActive() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.selectActive(b.id)

        XCTAssertEqual(state.activeEntrantID, b.id)
    }

    func test_appendDigitWritesIntoTheActiveEntrantOnly() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.appendDigit("2")
        state.appendDigit("4")

        XCTAssertEqual(state.enteredValue(for: a.id), 24)
        XCTAssertNil(state.enteredValue(for: b.id))
    }

    func test_appendDigitStripsLeadingZerosAndCapsAtFourDigits() {
        var state = RoundEntryState(entrants: [Entrant(name: "Alice")])

        "05678".forEach { state.appendDigit($0) }

        XCTAssertEqual(state.enteredValue(for: state.activeEntrantID!), 5678)
    }

    func test_appendDigitOnASingleZeroStaysZero() {
        var state = RoundEntryState(entrants: [Entrant(name: "Alice")])

        state.appendDigit("0")

        XCTAssertEqual(state.enteredValue(for: state.activeEntrantID!), 0)
    }

    func test_backspaceRemovesTheLastDigit() {
        var state = RoundEntryState(entrants: [Entrant(name: "Alice")])
        let id = state.activeEntrantID!
        state.appendDigit("2")
        state.appendDigit("4")

        state.backspace()

        XCTAssertEqual(state.enteredValue(for: id), 2)
    }

    func test_backspaceToEmptyClearsTheEnteredValue() {
        var state = RoundEntryState(entrants: [Entrant(name: "Alice")])
        let id = state.activeEntrantID!
        state.appendDigit("2")

        state.backspace()

        XCTAssertNil(state.enteredValue(for: id))
        XCTAssertFalse(state.isReadyToSave)
    }

    func test_clearActiveResetsOnlyTheActiveEntrantsValue() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])
        state.appendDigit("9")
        state.selectActive(b.id)
        state.appendDigit("3")

        state.clearActive()

        XCTAssertNil(state.enteredValue(for: b.id))
        XCTAssertEqual(state.enteredValue(for: a.id), 9)
    }

    func test_applyQuickEntrySetsTheValueAndAdvancesToTheNextEntrant() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.applyQuickEntry(0)

        XCTAssertEqual(state.enteredValue(for: a.id), 0)
        XCTAssertEqual(state.activeEntrantID, b.id)
    }

    func test_applyQuickEntryOnTheLastEntrantLeavesItActive() {
        let a = Entrant(name: "Alice")
        var state = RoundEntryState(entrants: [a])

        state.applyQuickEntry(101)

        XCTAssertEqual(state.enteredValue(for: a.id), 101)
        XCTAssertEqual(state.activeEntrantID, a.id)
    }

    func test_isReadyToSaveOnceAtLeastOneValueIsEnteredEvenZero() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.applyQuickEntry(0)

        XCTAssertTrue(state.isReadyToSave)
    }

    func test_rawDeltasOnlyIncludeEntrantsWithAnEnteredValue() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.appendDigit("7")

        XCTAssertEqual(state.rawDeltas, [a.id: 7])
    }

    // MARK: - Çifte

    func test_cifteChipMarksTheActiveEntrantAsACaller() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.selectActive(b.id)
        state.toggleCifteForActive()

        XCTAssertTrue(state.isCifteCaller(b.id))
        XCTAssertFalse(state.isCifteCaller(a.id))
        XCTAssertEqual(state.cifteCallers, [b.id])
    }

    func test_cifteChipTappedAgainUnmarksThatCaller() {
        let a = Entrant(name: "Alice")
        var state = RoundEntryState(entrants: [a])

        state.toggleCifteForActive()
        state.toggleCifteForActive()

        XCTAssertFalse(state.isCifteCaller(a.id))
        XCTAssertTrue(state.cifteCallers.isEmpty)
    }

    func test_moreThanOneEntrantCanBeMarkedAsACaller() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.toggleCifteForActive()
        state.selectActive(b.id)
        state.toggleCifteForActive()

        XCTAssertEqual(state.cifteCallers, [a.id, b.id])
    }

    /// Gonga has no Çifte concept, so the state itself refuses to record one —
    /// hiding the chip is the screen's job, not the only line of defence.
    func test_cifteIsNotRecordedWhereTheVariantDoesNotSupportIt() {
        let a = Entrant(name: "Alice")
        var state = RoundEntryState(entrants: [a], supportsCifte: false)

        state.toggleCifteForActive()

        XCTAssertFalse(state.isCifteCaller(a.id))
        XCTAssertTrue(state.cifteCallers.isEmpty)
    }

    // MARK: - Okey atmak

    func test_okeyAtmakChipMarksTheActiveEntrantAndEntersZeroForThem() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.selectActive(b.id)
        state.toggleOkeyAtanForActive()

        XCTAssertEqual(state.okeyAtanID, b.id)
        XCTAssertEqual(state.enteredValue(for: b.id), 0)
        // The marked row stays active, so its lit chip still refers to it.
        XCTAssertEqual(state.activeEntrantID, b.id)
    }

    func test_markingAnotherEntrantMovesTheOkeyAtanRatherThanAddingASecond() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.toggleOkeyAtanForActive()
        state.selectActive(b.id)
        state.toggleOkeyAtanForActive()

        XCTAssertEqual(state.okeyAtanID, b.id)
    }

    func test_okeyAtmakChipTappedAgainClearsTheMarker() {
        let a = Entrant(name: "Alice")
        var state = RoundEntryState(entrants: [a])

        state.toggleOkeyAtanForActive()
        state.toggleOkeyAtanForActive()

        XCTAssertNil(state.okeyAtanID)
        // The 0 stays: it's an entered value like any other, and withdrawing
        // it silently would turn a mis-tap into a lost score.
        XCTAssertEqual(state.enteredValue(for: a.id), 0)
    }

    func test_markingTheOkeyAtanAdvancesToTheNextEntrant() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.toggleOkeyAtanForActive()

        // The mark settles Alice's score at 0, so the next Entrant is next.
        XCTAssertEqual(state.okeyAtanID, a.id)
        XCTAssertEqual(state.activeEntrantID, b.id)
    }

    func test_clearingTheOkeyAtanMarkerLeavesTheActiveRowWhereItIs() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.toggleOkeyAtanForActive()
        state.selectActive(a.id)
        state.toggleOkeyAtanForActive()

        XCTAssertNil(state.okeyAtanID)
        // Un-marking leaves a row with a value still to deal with — moving on
        // would take the player away from the correction they just started.
        XCTAssertEqual(state.activeEntrantID, a.id)
    }

    func test_markingTheOkeyAtanOnTheLastEntrantLeavesItActive() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.selectActive(b.id)
        state.toggleOkeyAtanForActive()

        XCTAssertEqual(state.activeEntrantID, b.id)
    }

    func test_okeyAtmakIsOfferedEvenWhereCifteIsNot() {
        let a = Entrant(name: "Alice")
        var state = RoundEntryState(entrants: [a], supportsCifte: false)

        state.toggleOkeyAtanForActive()

        XCTAssertEqual(state.okeyAtanID, a.id)
    }

    // MARK: - Preview

    func test_noPreviewWhenNoModifierReachesTheEntrant() {
        var state = RoundEntryState(entrants: [Entrant(name: "Alice")])
        state.appendDigit("6")

        XCTAssertNil(state.previews()[state.activeEntrantID!])
    }

    func test_noPreviewWhenNothingIsEnteredYet() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])
        state.selectActive(b.id)
        state.toggleCifteForActive()

        XCTAssertNil(state.previews()[b.id])
    }

    /// A caller who didn't win doubles only themselves, so the preview shows
    /// ×2 on their row and leaves everyone else's alone.
    func test_previewShowsDoubleForALosingCallerAndNothingForTheRest() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])
        state.appendDigit("1")
        state.appendDigit("2")
        state.toggleCifteForActive()
        state.selectActive(b.id)
        state.appendDigit("5")

        XCTAssertEqual(state.previews()[a.id], .init(multiplier: 2, value: 24))
        XCTAssertNil(state.previews()[b.id])
    }

    /// A caller who won doubles everyone else instead — the preview follows
    /// the same asymmetry the Engine scores.
    func test_previewShowsDoubleForEveryoneElseWhenTheCallerWon() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])
        state.toggleCifteForActive()
        state.appendDigit("0")
        state.selectActive(b.id)
        state.appendDigit("5")

        XCTAssertNil(state.previews()[a.id])
        XCTAssertEqual(state.previews()[b.id], .init(multiplier: 2, value: 10))
    }

    func test_previewShowsQuadrupleWhereBothModifiersReachTheSameEntrant() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])
        state.appendDigit("2")
        state.appendDigit("0")
        state.toggleCifteForActive()
        state.selectActive(b.id)
        state.toggleOkeyAtanForActive()

        XCTAssertEqual(state.previews()[a.id], .init(multiplier: 4, value: 80))
        // The atan's own doubled 0 is still 0.
        XCTAssertEqual(state.previews()[b.id], .init(multiplier: 2, value: 0))
    }

    /// Okey atmak *is* winning the Round, so a stray digit typed after the
    /// marker went on mustn't quietly recast the atan as a loser — which would
    /// flip every Çifte caller's effect for the whole Round.
    func test_theOkeyAtanStillCountsAsWinningIfANonZeroValueIsTypedOverTheirZero() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])
        state.toggleOkeyAtanForActive()
        // Marking moved on to Bob; the stray digits are typed after coming
        // back to Alice's row.
        state.selectActive(a.id)
        state.toggleCifteForActive()
        state.appendDigit("7")
        state.selectActive(b.id)
        state.appendDigit("5")

        // Alice called and won, so Bob takes her Çifte on top of the uniform
        // Okey atmak doubling — ×4. Alice takes only the uniform ×2, never her
        // own call, exactly as if her value had stayed 0.
        XCTAssertEqual(state.previews()[a.id], .init(multiplier: 2, value: 14))
        XCTAssertEqual(state.previews()[b.id], .init(multiplier: 4, value: 20))
    }

    // MARK: - Raw output

    /// The Engine is the only place a Round's scores get scaled
    /// (`docs/adr/0005`), so no modifier may touch what gets saved — doubling
    /// here as well is what made Okey 101 Çifte Rounds score ×4.
    func test_rawDeltasAreNeverScaledByAnyCombinationOfModifiers() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        let c = Entrant(name: "Cem")
        var state = RoundEntryState(entrants: [a, b, c])
        state.appendDigit("7")
        state.toggleCifteForActive()
        state.selectActive(b.id)
        state.appendDigit("3")
        state.toggleCifteForActive()
        state.selectActive(c.id)
        state.toggleOkeyAtanForActive()

        XCTAssertEqual(state.rawDeltas, [a.id: 7, b.id: 3, c.id: 0])
        XCTAssertEqual(state.cifteCallers, [a.id, b.id])
        XCTAssertEqual(state.okeyAtanID, c.id)
    }

    func test_hasModifiersOnlyOnceOneIsRecorded() {
        let a = Entrant(name: "Alice")
        var state = RoundEntryState(entrants: [a])
        XCTAssertFalse(state.hasModifiers)

        state.toggleCifteForActive()

        XCTAssertTrue(state.hasModifiers)
    }

    /// Modifier state is per-Round: the screen builds a fresh state each time,
    /// so nothing a player marked last Round can survive into this one.
    func test_aFreshStateCarriesNoModifiersFromAPreviousRound() {
        let a = Entrant(name: "Alice")
        var previous = RoundEntryState(entrants: [a])
        previous.toggleCifteForActive()
        previous.toggleOkeyAtanForActive()

        let next = RoundEntryState(entrants: [a])

        XCTAssertTrue(next.cifteCallers.isEmpty)
        XCTAssertNil(next.okeyAtanID)
        XCTAssertFalse(next.hasModifiers)
    }
}
