import Foundation

/// Interactive state for the keypad Round Entry screen (Survival, Fixed
/// Rounds): a per-Entrant entered-digits buffer, which Entrant is currently
/// "active," and the Çifte toggle — independent of any view, mirroring how
/// `Scoresheet` derives its rows from a `Match` without touching SwiftUI.
struct RoundEntryState: Equatable {
    /// Still-in Entrants, in display order. Fixed for the state's lifetime.
    let entrants: [Entrant]
    private(set) var enteredDigits: [Entrant.ID: String] = [:]
    private(set) var activeEntrantID: Entrant.ID?
    var cifteOn = false

    init(entrants: [Entrant]) {
        self.entrants = entrants
        self.activeEntrantID = entrants.first?.id
    }

    /// The digits entered so far for `id`, or `nil` if nothing's been typed.
    func enteredValue(for id: Entrant.ID) -> Int? {
        guard let digits = enteredDigits[id], !digits.isEmpty else { return nil }
        return Int(digits)
    }

    /// The live Çifte-doubled preview for `id`'s entered value, or `nil` when
    /// Çifte is off or nothing's been entered yet.
    ///
    /// Presentation only. This is the one place in the entry layer that
    /// multiplies, and what it produces never reaches the Round that gets
    /// saved — see `rawDeltas` and `docs/adr/0005`.
    func doubledPreview(for id: Entrant.ID) -> Int? {
        guard cifteOn, let value = enteredValue(for: id) else { return nil }
        return value * 2
    }

    /// Matches the prototype's "ready" check: enabled once any Entrant has a value.
    var isReadyToSave: Bool {
        enteredDigits.values.contains { !$0.isEmpty }
    }

    /// This Round's per-Entrant deltas exactly as entered — never scaled by
    /// Çifte or any other Round modifier. `Round.deltas` stores raw counts and
    /// the Engines are the only place a multiplier is applied
    /// (`docs/adr/0005`); doubling here as well is what made Okey 101 Çifte
    /// Rounds score ×4.
    var rawDeltas: [Entrant.ID: Int] {
        var result: [Entrant.ID: Int] = [:]
        for entrant in entrants {
            guard let value = enteredValue(for: entrant.id) else { continue }
            result[entrant.id] = value
        }
        return result
    }

    mutating func selectActive(_ id: Entrant.ID) {
        activeEntrantID = id
    }

    /// Appends a digit to the active Entrant's buffer, stripping leading
    /// zeros and capping length at 4 digits, matching the prototype's `key()`.
    mutating func appendDigit(_ digit: Character) {
        guard let id = activeEntrantID, digit.isNumber else { return }
        var digits = (enteredDigits[id] ?? "") + String(digit)
        while digits.count > 1 && digits.first == "0" {
            digits.removeFirst()
        }
        enteredDigits[id] = String(digits.prefix(4))
    }

    /// Removes the active Entrant's last-entered digit.
    mutating func backspace() {
        guard let id = activeEntrantID, var digits = enteredDigits[id], !digits.isEmpty else { return }
        digits.removeLast()
        enteredDigits[id] = digits
    }

    /// Clears the active Entrant's entered value entirely (the prototype's `C` key).
    mutating func clearActive() {
        guard let id = activeEntrantID else { return }
        enteredDigits[id] = ""
    }

    /// Sets the active Entrant's value directly — the quick-entry shortcuts
    /// ("Won the round · 0", "Never laid down · 101") — then advances the
    /// active selection to the next still-in Entrant, matching the prototype.
    mutating func applyQuickEntry(_ value: Int) {
        guard let id = activeEntrantID else { return }
        enteredDigits[id] = "\(value)"
        if let index = entrants.firstIndex(where: { $0.id == id }), index + 1 < entrants.count {
            activeEntrantID = entrants[index + 1].id
        }
    }
}
