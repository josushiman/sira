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
    /// Fixed Rounds: the number of Rounds the Match runs for.
    let roundCount: Int?
    let teamsOnly: Bool
    var entryStyle: RoundEntryStyle = .keypad
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

    /// The Variants available for a Game, in the order the Variant Picker shows them.
    static func all(for game: Game) -> [Variant] {
        switch game {
        case .gonga: return [.gonga101]
        case .okey: return [.okeyStandard]
        }
    }
}
