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
    /// The single Entrant mode this Variant is played in. Every Variant is
    /// fixed to one — only Okey standard is played in Teams of 2; Gonga
    /// 101/151 and Okey 101 are individuals only — so Setup records this
    /// rather than offering a Players/Teams choice.
    let entrantMode: EntrantMode
    /// The largest number of Entrants Setup will let you pick. Teams Variants
    /// are always exactly 2; Gonga seats up to 8 players, Okey 101 up to 4.
    let maxEntrants: Int
    /// Whether Round entry offers the Çifte doubling toggle. Okey only —
    /// Gonga has no Çifte concept.
    let supportsCifte: Bool
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
        entrantMode: .players,
        maxEntrants: 8,
        supportsCifte: false
    )

    static let gonga151 = Variant(
        id: "gonga-151",
        game: .gonga,
        label: "Gonga 151",
        ruleText: "The longer game. Accumulate points each Round, go over 151 and you're Out. Last one standing wins.",
        winCondition: .survival,
        limit: 151,
        startingScore: nil,
        roundCount: nil,
        entrantMode: .players,
        maxEntrants: 8,
        supportsCifte: false
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
        entrantMode: .teams,
        maxEntrants: 2,
        supportsCifte: true,
        entryStyle: .okeyStandard
    )

    static let okey101 = Variant(
        id: "okey-101",
        game: .okey,
        label: "Okey 101",
        ruleText: "Individuals only. Accumulate points each Round over a fixed number of Rounds (8 or 12, chosen at Setup). Lowest total when the Rounds run out wins.",
        winCondition: .fixedRounds,
        limit: nil,
        startingScore: nil,
        roundCount: 8,
        entrantMode: .players,
        maxEntrants: 4,
        supportsCifte: true,
        entryStyle: .keypad,
        neverLaidDownValue: 101
    )

    /// The Variants available for a Game, in the order the Variant Picker shows them.
    static func all(for game: Game) -> [Variant] {
        switch game {
        case .gonga: return [.gonga101, .gonga151]
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
