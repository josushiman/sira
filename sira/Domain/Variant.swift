import Foundation

/// Which Round Entry form a Variant uses.
enum RoundEntryStyle: Hashable {
    /// Per-Entrant numeric keypad (Gonga 101/151, Okey 101).
    case keypad
    /// Pick the losing team plus Gösterge steppers (Okey 21).
    case okey21
}

struct Variant: Identifiable, Hashable {
    /// Stable identity for this Variant, and a persistence contract once the
    /// app ships: a Match stores this string and resolves its rules from it,
    /// so renaming one orphans every Match that names it. Treat these ids as
    /// frozen — add a new Variant rather than retitling an existing id, and
    /// keep `VariantTests` asserting each one explicitly.
    let id: String
    let game: Game
    let label: String
    let ruleText: String
    let winCondition: WinCondition
    /// Survival: the score an Entrant must stay at or under before going Out.
    let limit: Int?
    /// Elimination: the score Entrants count down from.
    let startingScore: Int?
    /// Fixed Rounds: the number of Rounds the Match runs for. Var rather than
    /// let because a Match resolving this Variant applies the Round count
    /// chosen at Setup (Okey 101: 8 or 12) on top of it.
    var roundCount: Int?
    /// The single Entrant mode this Variant is played in. Every Variant is
    /// fixed to one — only Okey 21 is played in Teams of 2; Gonga
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

    static let okey21 = Variant(
        id: "okey-21",
        game: .okey,
        label: "Okey 21",
        ruleText: "Teams of 2 count down from 21. The losing team takes \u{2212}2 each Round; each Gösterge find deducts 1 from the other team. First team to reach 0 loses.",
        winCondition: .elimination,
        limit: nil,
        startingScore: 21,
        roundCount: nil,
        entrantMode: .teams,
        maxEntrants: 2,
        supportsCifte: true,
        entryStyle: .okey21
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
        case .okey: return [.okey21, .okey101]
        }
    }
}
