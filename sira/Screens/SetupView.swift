import SwiftUI

struct SetupView: View {
    let variant: Variant

    @Environment(MatchStore.self) private var store
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var entrantNames: [String]
    @State private var roundCount: Int
    /// The Match this screen started, held directly rather than by id: it is a
    /// model class, so there is nothing to look it back up from.
    @State private var startedMatch: Match?

    init(variant: Variant) {
        self.variant = variant
        _entrantNames = State(initialValue: Array(repeating: "", count: 2))
        _roundCount = State(initialValue: variant.roundCount ?? 8)
    }

    /// Every Variant is fixed to one Entrant mode, so Setup records the
    /// Variant's own mode instead of offering a Players/Teams choice.
    private var mode: EntrantMode { variant.entrantMode }
    private var entrantLabel: String { mode == .teams ? "Team" : "Player" }
    /// Only worth showing when the Variant actually allows more than the
    /// minimum — Okey 21 is always exactly two teams.
    private var showsCountSelector: Bool { variant.maxEntrants > 2 }
    private var entrantCountOptions: [Int] { Array(2...variant.maxEntrants) }
    private var offersRoundCountChoice: Bool { variant.winCondition == .fixedRounds }

    /// The Variant as this screen has it set up: the shipped rules, with the
    /// Round count the player picked where the Variant offers that choice.
    /// What the Match records its number from.
    private var chosenVariant: Variant {
        guard offersRoundCountChoice else { return variant }
        var chosen = variant
        chosen.roundCount = roundCount
        return chosen
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

                if offersRoundCountChoice {
                    labeledSection("Rounds") {
                        ChipSelector(options: [8, 12], label: { "\($0)" }, selection: $roundCount)
                    }
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

    private var startButton: some View {
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
        .background(theme.ink, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .buttonStyle(.plain)
    }

    private func startMatch() {
        let entrants = entrantNames.enumerated().map { index, name -> Entrant in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return Entrant(name: trimmed.isEmpty ? "\(entrantLabel) \(index + 1)" : trimmed)
        }
        // The Match names its Variant rather than copying it, so all Setup
        // records is the id plus the one number the Variant's Win Condition is
        // played at — including where that number came straight off the
        // Variant, so that every Match says what it was played at.
        let match = Match(
            game: variant.game,
            variant: chosenVariant,
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
        SetupView(variant: .gonga101)
    }
    .environment(MatchStore())
    .themed()
}

#Preview("Okey 21") {
    NavigationStack {
        SetupView(variant: .okey21)
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
