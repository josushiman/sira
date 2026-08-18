import Foundation

/// Which Round Entry form a Variant uses.
enum RoundEntryStyle: Hashable {
    /// Per-Entrant numeric keypad (Gonga 101/151, Okey 101).
    case keypad
    /// Pick the losing team plus Gösterge steppers (Okey standard).
    case okeyStandard
}

struct Variant: Identifiable, Hashable {
    let id: String
    let game: Game
    let label: String
    let ruleText: String
    let winCondition: WinCondition
    /// Survival: the score an Entrant must stay at or under before going Out.
    let limit: Int?
    /// Elimination: the score Entrants count down from.
    let startingScore: Int?
    /// Fixed Rounds: the number of Rounds the Match runs for. Settable at
    /// Setup so a chosen round count (Okey 101: 8 or 12) can be recorded on
    /// the Match's own copy of the Variant via `choosingRoundCount(_:)`.
    var roundCount: Int?
    let teamsOnly: Bool
    var entryStyle: RoundEntryStyle = .keypad
    /// Keypad entry's "never laid down" quick-entry shortcut value (Okey 101: 101).
    /// `nil` for Variants that don't offer this shortcut.
    var neverLaidDownValue: Int? = nil
}

extension Variant {
    static let gonga101 = Variant(
        id: "gonga-101",
        game: .gonga,
        label: "Gonga 101",
        ruleText: "Accumulate points each Round. Go over 101 and you're Out. Last one standing wins.",
        winCondition: .survival,
        limit: 101,
        startingScore: nil,
        roundCount: nil,
        teamsOnly: false
    )

    static let okeyStandard = Variant(
        id: "okey-standard",
        game: .okey,
        label: "Okey (standard)",
        ruleText: "Teams of 2 count down from 20. The losing team takes \u{2212}2 each Round; each Gösterge find deducts 1 from the other team. First team to reach 0 loses.",
        winCondition: .elimination,
        limit: nil,
        startingScore: 20,
        roundCount: nil,
        teamsOnly: true,
        entryStyle: .okeyStandard
    )

    static let okey101 = Variant(
        id: "okey-101",
        game: .okey,
        label: "Okey 101",
        ruleText: "Accumulate points each Round over a fixed number of Rounds (8 or 12, chosen at Setup). Lowest total when the Rounds run out wins.",
        winCondition: .fixedRounds,
        limit: nil,
        startingScore: nil,
        roundCount: 8,
        teamsOnly: false,
        entryStyle: .keypad,
        neverLaidDownValue: 101
    )

    /// The Variants available for a Game, in the order the Variant Picker shows them.
    static func all(for game: Game) -> [Variant] {
        switch game {
        case .gonga: return [.gonga101]
        case .okey: return [.okeyStandard, .okey101]
        }
    }

    /// Returns a copy of this Variant with its Round count set to `roundCount`,
    /// used by Setup to record Okey 101's 8-or-12 choice on the Match's own
    /// copy before the Match is created.
    func choosingRoundCount(_ roundCount: Int) -> Variant {
        var copy = self
        copy.roundCount = roundCount
        return copy
    }
}
