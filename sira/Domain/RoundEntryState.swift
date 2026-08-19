import Foundation

/// Interactive state for the keypad Round Entry screen (Survival, Fixed
/// Rounds): a per-Entrant entered-digits buffer, which Entrant is currently
/// "active," and this Round's modifiers — independent of any view, mirroring
/// how `Scoresheet` derives its rows from a `Match` without touching SwiftUI.
///
/// One state per Round: the screen builds a fresh one each time it's pushed,
/// so no modifier can carry into the next Round's entry.
struct RoundEntryState: Equatable {
    /// Still-in Entrants, in display order. Fixed for the state's lifetime.
    let entrants: [Entrant]
    /// Whether this Variant has a Çifte concept at all. Gonga doesn't, so the
    /// state refuses to record a caller — rather than leaving the view as the
    /// only thing standing between Gonga and a doubled Round.
    let supportsCifte: Bool
    private(set) var enteredDigits: [Entrant.ID: String] = [:]
    private(set) var activeEntrantID: Entrant.ID?
    /// The Entrants marked as having called Çifte this Round.
    private(set) var cifteCallers: Set<Entrant.ID> = []
    /// The Entrant marked as the Okey atan — the one who did Okey atmak this
    /// Round.
    private(set) var okeyAtanID: Entrant.ID?

    init(entrants: [Entrant], supportsCifte: Bool = true) {
        self.entrants = entrants
        self.supportsCifte = supportsCifte
        self.activeEntrantID = entrants.first?.id
    }

    /// The digits entered so far for `id`, or `nil` if nothing's been typed.
    func enteredValue(for id: Entrant.ID) -> Int? {
        guard let digits = enteredDigits[id], !digits.isEmpty else { return nil }
        return Int(digits)
    }

    /// What one Entrant's entered value will actually score, and the
    /// multiplier that gets it there — so a row can show `×4 → 96` rather
    /// than leaving a surprising number unexplained.
    struct ScaledPreview: Equatable {
        let multiplier: Int
        let value: Int
    }

    /// Whether `id` is marked as a Çifte caller this Round.
    func isCifteCaller(_ id: Entrant.ID) -> Bool {
        cifteCallers.contains(id)
    }

    /// Whether `id` is marked as the Okey atan this Round.
    func isOkeyAtan(_ id: Entrant.ID) -> Bool {
        okeyAtanID == id
    }

    /// Whether the active row already carries each mark — what the chips light
    /// from, so one chip reads as both "apply" and "applied".
    var isActiveCifteCaller: Bool {
        activeEntrantID.map(isCifteCaller) ?? false
    }

    var isActiveOkeyAtan: Bool {
        activeEntrantID.map(isOkeyAtan) ?? false
    }

    /// Whether any modifier has been recorded this Round.
    var hasModifiers: Bool {
        !cifteCallers.isEmpty || okeyAtanID != nil
    }

    /// Every Entrant's live preview, in one pass — absent for anyone who has
    /// entered nothing yet or whose value nothing scales.
    ///
    /// Derived by handing the Round this entry *would* save to the same
    /// derivation the Engines use, so the preview can't drift from the score.
    /// The rules live in `Round` and are never restated here.
    ///
    /// Presentation only. This is the one place in the entry layer that
    /// multiplies, and what it produces never reaches the Round that gets
    /// saved — see `rawDeltas` and `docs/adr/0005`.
    func previews() -> [Entrant.ID: ScaledPreview] {
        let round = Round(deltas: rawDeltas, cifteCallers: cifteCallers, okeyAtanID: okeyAtanID)
        let multipliers = round.keypadMultipliers(for: entrants.map(\.id))
        var result: [Entrant.ID: ScaledPreview] = [:]
        for entrant in entrants {
            guard let value = enteredValue(for: entrant.id) else { continue }
            let multiplier = multipliers[entrant.id] ?? 1
            guard multiplier > 1 else { continue }
            result[entrant.id] = ScaledPreview(multiplier: multiplier, value: value * multiplier)
        }
        return result
    }

    /// Matches the prototype's "ready" check: enabled once any Entrant has a value.
    var isReadyToSave: Bool {
        enteredDigits.values.contains { !$0.isEmpty }
    }

    /// This Round's per-Entrant deltas exactly as entered — never scaled by
    /// Çifte, Okey atmak or any other Round modifier. `Round.deltas` stores
    /// raw counts and the Engines are the only place a multiplier is applied
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

    /// Toggles the active Entrant's Çifte caller status — the chip acts on
    /// whichever row is selected, the convention the quick-entry shortcuts
    /// already teach. Tapping it again un-marks that caller.
    mutating func toggleCifteForActive() {
        guard supportsCifte, let id = activeEntrantID else { return }
        if cifteCallers.contains(id) {
            cifteCallers.remove(id)
        } else {
            cifteCallers.insert(id)
        }
    }

    /// Marks the active Entrant as the Okey atan and enters 0 for them: they
    /// finished the Round, so they scored nothing and shouldn't have to record
    /// that separately.
    ///
    /// Exclusive — applying it to another row moves the marker rather than
    /// adding a second, since only one Entrant can finish a Round. Applying it
    /// to the current atan clears the marker, and deliberately leaves their 0
    /// alone: it's an entered value like any other, editable from the keypad,
    /// and silently withdrawing it would turn a mis-tap into a lost score.
    ///
    /// The active row doesn't advance, unlike the quick-entry shortcuts — the
    /// row just marked is the one whose chip is now lit, and moving off it
    /// would make the marker look like it hadn't taken.
    mutating func toggleOkeyAtanForActive() {
        guard let id = activeEntrantID else { return }
        if okeyAtanID == id {
            okeyAtanID = nil
        } else {
            okeyAtanID = id
            enteredDigits[id] = "0"
        }
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
