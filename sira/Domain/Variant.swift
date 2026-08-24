import Foundation

/// Which Round Entry form a Variant uses.
enum RoundEntryStyle: Hashable {
    /// Per-Entrant numeric keypad (Gonga, Okey 101).
    case keypad
    /// Pick the losing team plus Gösterge steppers (Okey).
    case okeyStandard
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
    // The three shapes a number is taken in, kept here and left `nil` on every
    // shipped Variant: a Variant describes shape only, and the number it is
    // played at is chosen at Setup and stored on the Match (`Match.limit`,
    // `Match.startingScore`, `Match.roundCount`, read through
    // `Match.variantNumber`). They stay declared because "no Variant carries a
    // number" is the contract, and a contract nothing states is one nothing can
    // assert — see `VariantTests`.
    /// Survival: the score an Entrant must stay at or under before going Out.
    /// Always `nil`; the Match carries the limit.
    let limit: Int? = nil
    /// Elimination: the score Entrants count down from. Always `nil`; the
    /// Match carries the starting score.
    let startingScore: Int? = nil
    /// Fixed Rounds: the number of Rounds the Match runs for. Always `nil`;
    /// the Match carries the Round count.
    let roundCount: Int? = nil
    /// The single Entrant mode this Variant is played in. Every Variant is
    /// fixed to one — only Okey is played in Teams of 2; Gonga and Okey 101
    /// are individuals only — so Setup records this rather than offering
    /// a Players/Teams choice.
    let entrantMode: EntrantMode
    /// The largest number of Entrants Setup will let you pick. Teams Variants
    /// are always exactly 2; Gonga seats up to 8 players, Okey 101 up to 4.
    let maxEntrants: Int
    /// Whether Round entry offers the Çifte doubling toggle. Okey only —
    /// Gonga has no Çifte concept.
    let supportsCifte: Bool
    /// The rules as Setup reads them back once a number has been chosen, with
    /// `{n}` standing where that number goes. Separate from `ruleText`, which
    /// the Variant Picker shows before anything has been chosen and so cannot
    /// quote a number at all.
    ///
    /// Every Variant has one: all three take a number at Setup, so all three
    /// have rules to read back at whatever was chosen.
    let ruleTextTemplate: String
    var entryStyle: RoundEntryStyle = .keypad
    /// Keypad entry's "never laid down" quick-entry shortcut value (Okey 101: 101).
    /// `nil` for Variants that don't offer this shortcut.
    var neverLaidDownValue: Int? = nil

    /// The rules restated with `number` in them — what Setup shows under the
    /// control, so choosing 5 immediately reads back the game that choice
    /// makes.
    func ruleText(at number: Int) -> String {
        ruleTextTemplate.replacingOccurrences(of: "{n}", with: "\(number)")
    }
}

extension Variant {
    /// Gonga, played to whatever limit the table agreed on at Setup.
    ///
    /// One Variant rather than the two it replaces: Gonga 101 and Gonga 151
    /// were identical in Win Condition, Entrant mode, eight-player maximum,
    /// absence of Çifte and keypad entry, and differed by a single integer —
    /// which is a number to be asked for, not a ruleset to be chosen between.
    ///
    /// The id names the slot and not the number, so a genuinely different
    /// Gonga ruleset can be added later without this one's id having to lie.
    static let gongaStandard = Variant(
        id: "gonga-standard",
        game: .gonga,
        label: "Gonga",
        ruleText: "Accumulate points each Round. Go over the limit and you're Out. Last one standing wins.",
        winCondition: .survival,
        entrantMode: .players,
        maxEntrants: 8,
        supportsCifte: false,
        ruleTextTemplate: "Accumulate points each Round. Go over {n} and you're Out. Last one standing wins."
    )

    /// Okey as it is played by default, counting down from a starting score.
    ///
    /// Labelled "Okey" and not "Okey 21": the starting score becomes a Setup
    /// choice, and a name quoting a number the Variant no longer guarantees is
    /// worse than no number at all. The id names the slot rather than the
    /// number for the same reason.
    ///
    /// The Swift member stays qualified — `okeyStandard`, not `okey` — because
    /// `Game.okey` already exists and two `okey` members one type apart
    /// misresolve later even though they read fine today.
    static let okeyStandard = Variant(
        id: "okey-standard",
        game: .okey,
        label: "Okey",
        ruleText: "Teams of 2 count down from a starting score, chosen at Setup. The losing team takes \u{2212}2 each Round; each Gösterge find deducts 1 from the other team. First team to reach 0 loses.",
        winCondition: .elimination,
        entrantMode: .teams,
        maxEntrants: 2,
        supportsCifte: true,
        ruleTextTemplate: "Teams of 2 count down from {n}. The losing team takes \u{2212}2 each Round; each Gösterge find deducts 1 from the other team. First team to reach 0 loses.",
        entryStyle: .okeyStandard
    )

    static let okey101 = Variant(
        id: "okey-101",
        game: .okey,
        label: "Okey 101",
        ruleText: "Individuals only. Accumulate points each Round over a fixed number of Rounds, chosen at Setup. Lowest total when the Rounds run out wins.",
        winCondition: .fixedRounds,
        entrantMode: .players,
        maxEntrants: 4,
        supportsCifte: true,
        ruleTextTemplate: "Individuals only. Accumulate points each Round over {n} Rounds. Lowest total when the Rounds run out wins.",
        entryStyle: .keypad,
        neverLaidDownValue: 101
    )

    /// The Variants available for a Game, in the order the Variant Picker shows them.
    static func all(for game: Game) -> [Variant] {
        switch game {
        case .gonga: return [.gongaStandard]
        case .okey: return [.okeyStandard, .okey101]
        }
    }
}
