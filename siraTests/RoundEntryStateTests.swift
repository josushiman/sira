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
        XCTAssertTrue(state.deltas.isEmpty)
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

    func test_deltasOnlyIncludeEntrantsWithAnEnteredValue() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])

        state.appendDigit("7")

        XCTAssertEqual(state.deltas, [a.id: 7])
    }

    func test_deltasAreDoubledWhenCifteIsOn() {
        let a = Entrant(name: "Alice")
        let b = Entrant(name: "Bob")
        var state = RoundEntryState(entrants: [a, b])
        state.appendDigit("7")
        state.selectActive(b.id)
        state.appendDigit("3")
        state.cifteOn = true

        XCTAssertEqual(state.deltas, [a.id: 14, b.id: 6])
    }

    func test_doubledPreviewIsNilWhenCifteIsOff() {
        var state = RoundEntryState(entrants: [Entrant(name: "Alice")])
        state.appendDigit("6")

        XCTAssertNil(state.doubledPreview(for: state.activeEntrantID!))
    }

    func test_doubledPreviewIsNilWhenNothingIsEnteredYet() {
        var state = RoundEntryState(entrants: [Entrant(name: "Alice")])
        state.cifteOn = true

        XCTAssertNil(state.doubledPreview(for: state.activeEntrantID!))
    }

    func test_doubledPreviewReflectsTheLiveEnteredValue() {
        var state = RoundEntryState(entrants: [Entrant(name: "Alice")])
        state.cifteOn = true
        state.appendDigit("1")
        state.appendDigit("2")

        XCTAssertEqual(state.doubledPreview(for: state.activeEntrantID!), 24)
    }
}
