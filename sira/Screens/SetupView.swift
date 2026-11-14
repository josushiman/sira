import SwiftUI

struct SetupView: View {
    let variant: Variant

    @Environment(MatchStore.self) private var store
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var entrantNames: [String]
    /// The number this Match will be played at, and the rules governing what
    /// the player is allowed to choose. Setup holds it and taps at it; every
    /// judgement about it — startable, why not, how it reads — belongs to the
    /// parameter rather than to this screen.
    @State private var parameter: VariantParameter?
    /// The Match this screen started, held directly rather than by id: it is a
    /// model class, so there is nothing to look it back up from.
    @State private var startedMatch: Match?

    /// `initialParameter` seeds the control mid-choice, so a snapshot can be
    /// taken of a revealed Custom field or a refused value without a test
    /// having to tap its way there — the same seam `RoundEntryView` opens for
    /// the same reason.
    init(variant: Variant, initialParameter: VariantParameter? = nil) {
        self.variant = variant
        _entrantNames = State(initialValue: Array(repeating: "", count: 2))
        _parameter = State(initialValue: variant.parameterKind == nil ? nil : initialParameter ?? VariantParameter(for: variant))
    }

    /// Every Variant is fixed to one Entrant mode, so Setup records the
    /// Variant's own mode instead of offering a Players/Teams choice.
    private var mode: EntrantMode { variant.entrantMode }
    /// The Match's own word for one Entrant, capitalized to open a name with.
    /// Labels the name rows and their placeholders; the fallback those
    /// placeholders stand for is `EntrantName`'s to build, off this same word.
    private var entrantLabel: String { mode.entrantNoun.capitalized }
    /// Only worth showing when the Variant actually allows more than the
    /// minimum — Okey is always exactly two teams.
    private var showsCountSelector: Bool { variant.maxEntrants > 2 }
    private var entrantCountOptions: [Int] { Array(2...variant.maxEntrants) }

    private var selection: Binding<VariantParameter.Selection> {
        Binding(
            get: { parameter?.selection ?? .custom },
            set: { parameter?.choose($0) }
        )
    }

    private var customText: Binding<String> {
        Binding(
            get: { parameter?.customText ?? "" },
            set: { parameter?.enterCustom($0) }
        )
    }

    private var entrantCount: Binding<Int> {
        Binding(
            get: { entrantNames.count },
            set: { setEntrantCount($0) }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Who's playing?")
                    .siraStyle(.displayTitle)

                if showsCountSelector {
                    labeledSection("How many players") {
                        ChipSelector(options: entrantCountOptions, label: { "\($0)" }, selection: entrantCount)
                    }
                }

                labeledSection("Names") {
                    VStack(spacing: 8) {
                        ForEach(entrantNames.indices, id: \.self) { index in
                            NameRow(index: index, label: entrantLabel, name: $entrantNames[index])
                        }
                    }
                }

                if let parameter {
                    labeledSection(parameter.kind.noun) {
                        numberControl(parameter)
                    }
                } else {
                    Text(variant.ruleTextTemplate)
                        .siraStyle(.body)
                        .foregroundStyle(theme.ink.opacity(0.7))
                }
            }
            .padding(22)
        }
        .background(theme.background)
        .foregroundStyle(theme.ink)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            header
                .padding(.horizontal, 22)
                .padding(.top, 6)
                .background(theme.background)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            startButton
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(theme.background)
        }
        .navigationDestination(item: $startedMatch) { match in
            PlayView(match: match)
        }
    }

    /// The chips, the field they reveal, and the rules read back with whatever
    /// is currently chosen in them.
    @ViewBuilder
    private func numberControl(_ parameter: VariantParameter) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            ChipSelector(
                options: parameter.presets.map { VariantParameter.Selection.preset($0) } + [.custom],
                label: chipLabel,
                selection: selection
            )

            if parameter.isCustom {
                CardSurface(cornerRadius: 16, padding: 12) {
                    TextField("\(parameter.kind.range.lowerBound)–\(parameter.kind.range.upperBound)", text: customText)
                        .font(.sira(.monoValue))
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                }
            }

            // Read back from the number rather than from whether it is legal:
            // a refused 500 still describes the game 500 would make, and the
            // reason it is refused is said by the Start button, once.
            if let value = parameter.value {
                Text(variant.ruleText(at: value))
                    .siraStyle(.body)
                    .foregroundStyle(theme.ink.opacity(0.6))
            }
        }
    }

    private func chipLabel(_ selection: VariantParameter.Selection) -> String {
        switch selection {
        case .preset(let preset): return "\(preset)"
        case .custom: return "Custom"
        }
    }

    private func setEntrantCount(_ newValue: Int) {
        if newValue > entrantNames.count {
            entrantNames.append(contentsOf: Array(repeating: "", count: newValue - entrantNames.count))
        } else if newValue < entrantNames.count {
            entrantNames.removeLast(entrantNames.count - newValue)
        }
    }

    @ViewBuilder
    private func labeledSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(sira: .monoEyebrow, title)
                .foregroundStyle(theme.ink.opacity(0.5))
            content()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            BackButton { dismiss() }

            Text(sira: .monoEyebrow, variant.label)
                .foregroundStyle(theme.ink.opacity(0.5))

            Spacer()
        }
    }

    /// The button, and — above it, where the tap that is about to fail is
    /// aimed — the reason it will not start. Said once: the field itself does
    /// not turn red, because the number in it is not wrong, it is just not one
    /// this game can be played at.
    private var startButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let reason = parameter?.unstartableReason {
                Text(reason)
                    .siraStyle(.caption)
                    .foregroundStyle(theme.ink.opacity(0.6))
            }

            Button {
                startMatch()
            } label: {
                Text("Start Match")
                    .siraStyle(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(theme.background)
            .background(
                theme.ink.opacity(isStartable ? 1 : 0.3),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .buttonStyle(.plain)
            .disabled(!isStartable)
        }
    }

    private var isStartable: Bool { parameter?.isStartable ?? (variant.parameterKind == nil) }

    private func startMatch() {
        // Required Setup scores must be startable; Lowest Total needs none.
        guard isStartable else { return }

        // Named through `EntrantName` rather than here, so that a blank field
        // produces the same `Player 3` at Setup as a blank field does in the
        // rename sheet — one rule, not two that happen to agree today.
        //
        // The position in this list is the seat: the Match stamps Entrants
        // with their index as it is built, so the number Setup shows is the
        // one the Entrant will be sitting on afterwards.
        //
        // Nothing to be unique against yet, so nothing is passed: these
        // Entrants are not in a Match until the line below builds one.
        let entrants = entrantNames.enumerated().map { index, name in
            Entrant(name: EntrantName(name, seat: index, mode: mode).materialised)
        }
        // Store the Variant identity and its required Setup score, if any.
        let match = Match(
            game: variant.game,
            variant: variant,
            number: parameter?.value,
            mode: mode,
            entrants: entrants
        )
        store.add(match)
        startedMatch = match
    }
}

/// An entrant/team name-entry row: a colored dot-badge initial, an inline
/// text field, and (when empty) the fallback-name placeholder — matching the
/// prototype's Setup screen name rows.
private struct NameRow: View {
    let index: Int
    let label: String
    @Binding var name: String

    @Environment(\.theme) private var theme

    var body: some View {
        CardSurface(cornerRadius: 16, padding: 12) {
            HStack(spacing: 12) {
                DotBadge(text: initial, index: index, size: 32)
                TextField(placeholder, text: $name)
                    .font(.sira(.subheadline))
                    .textFieldStyle(.plain)
            }
        }
    }

    private var placeholder: String { "\(label) \(index + 1)" }

    private var initial: String { name.dotBadgeInitial }
}

#Preview {
    NavigationStack {
        SetupView(variant: .gongaStandard)
    }
    .environment(MatchStore())
    .themed()
}

#Preview("Okey") {
    NavigationStack {
        SetupView(variant: .okeyStandard)
    }
    .environment(MatchStore())
    .themed()
}

#Preview("Okey 101") {
    NavigationStack {
        SetupView(variant: .okey101)
    }
    .environment(MatchStore())
    .themed()
}
