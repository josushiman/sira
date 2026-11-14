import Foundation

/// A required Setup score: its presets, legal range, current choice and
/// wording. Okey 101 needs no parameter.
///
/// A struct that owns interactive state together with the rules governing it
/// and touches no SwiftUI — the shape `RoundEntryState` already established, so
/// the rules are driven directly by tests rather than through a screen.
///
/// It exists rather than living in `SetupView`'s `@State` because the same
/// definition answers more than the one screen that holds it: the chips Setup
/// offers and whether Start is allowed, here — and, through `Kind`, the phrase
/// `Match.numberPhrase` names a Match by long after Setup is gone.
struct VariantParameter: Equatable {
    /// Which score a Win Condition requires, with its range and wording.
    enum Kind: Hashable {
        /// Survival: the score an Entrant must stay at or under.
        case limit
        /// Elimination: the score Entrants count down from.
        case startingScore

        /// The number a Win Condition takes.
        init?(_ winCondition: WinCondition) {
            switch winCondition {
            case .survival: self = .limit
            case .elimination: self = .startingScore
            case .lowestTotal: return nil
            }
        }

        /// What the number may be. Wide enough that no table playing a
        /// recognisable game is turned away, and narrow enough that a slipped
        /// digit is caught before it becomes a Match nobody can finish.
        var range: ClosedRange<Int> {
            switch self {
            case .limit: return 11...999
            case .startingScore: return 2...99
            }
        }

        /// What this number is called: the heading Setup asks for it under, and
        /// the word the refusal opens with when it will not do.
        var noun: String {
            switch self {
            case .limit: return "Limit"
            case .startingScore: return "Starting score"
            }
        }

        /// The score beside a Variant's label: `to 201` or `from 21`.
        func phrase(for value: Int) -> String {
            switch self {
            case .limit: return "to \(value)"
            case .startingScore: return "from \(value)"
            }
        }
    }

    /// Which chip is selected. Custom is a chip alongside the presets rather
    /// than a mode the control drops into, so leaving it is a tap on a number
    /// rather than an undo.
    enum Selection: Hashable {
        case preset(Int)
        case custom
    }

    let kind: Kind
    /// The preset values Setup offers as chips, in the order it shows them.
    /// The Custom chip follows them and is not one of these.
    let presets: [Int]
    private(set) var selection: Selection
    /// What has been typed into the custom field, exactly as typed. Held as
    /// text rather than a number because that is the only way a half-typed or
    /// out-of-range entry survives being read back: see `isStartable` for why
    /// nothing here is ever corrected.
    private(set) var customText: String = ""

    init(kind: Kind, presets: [Int], preselected: Int?) {
        self.kind = kind
        self.presets = presets
        self.selection = preselected.map(Selection.preset) ?? .custom
    }

    /// Whether the numeric field is showing.
    var isCustom: Bool { selection == .custom }

    /// The number currently chosen, in range or not, or `nil` when the custom
    /// field holds nothing that reads as a number.
    var value: Int? {
        switch selection {
        case .preset(let preset): return preset
        case .custom: return Int(customText)
        }
    }

    /// Out-of-range input is refused, never clamped to a different choice.
    var isStartable: Bool {
        value.map(kind.range.contains) ?? false
    }

    /// Why the Match will not start, phrased in the numbers the value was
    /// judged against so the player can see what would do instead. `nil` once
    /// there is nothing to explain.
    var unstartableReason: String? {
        guard !isStartable else { return nil }
        return "\(kind.noun) must be between \(kind.range.lowerBound) and \(kind.range.upperBound)"
    }

    /// Taps a chip, whichever it is — what the chip row binds to, so Setup
    /// hands over what was tapped rather than taking the selection apart to
    /// decide which mutator to call.
    mutating func choose(_ selection: Selection) {
        switch selection {
        case .preset(let preset): select(preset)
        case .custom: selectCustom()
        }
    }

    /// Taps a preset chip. The custom entry goes with it: a preset is a whole
    /// answer rather than a correction to what was typed, so coming back to
    /// Custom asks the question fresh instead of re-offering a number the
    /// player has already moved off.
    mutating func select(_ preset: Int) {
        selection = .preset(preset)
        customText = ""
    }

    /// Taps the Custom chip, revealing the field.
    mutating func selectCustom() {
        selection = .custom
    }

    /// Takes what is typed into the custom field, and moves the selection there
    /// if it is not already — typing is a way of choosing Custom.
    mutating func enterCustom(_ text: String) {
        selection = .custom
        customText = text
    }
}

extension VariantParameter {
    /// The number a Variant is played at, as it ships: the chips Setup opens
    /// with and which of them is already chosen.
    ///
    /// Okey offers the one preset it has always been played at and nothing
    /// else, because there is no second starting score tables commonly agree
    /// on — 21 stays a chip rather than becoming a bare prefilled field, so
    /// the standard game is something the player chooses rather than a default
    /// they failed to change.
    ///
    /// The presets are stated here and nowhere else: a Variant carries no
    /// numbers at all, so there is no constant for these to agree or disagree
    /// with. What Setup opens on is a question about what tables usually play,
    /// which is this type's business; how far a Match runs is the Match's.
    init?(for variant: Variant) {
        switch variant.winCondition {
        case .lowestTotal:
            return nil
        case .survival:
            self.init(kind: .limit, presets: [101, 151], preselected: 101)
        case .elimination:
            self.init(kind: .startingScore, presets: [21], preselected: 21)
        }
    }
}
