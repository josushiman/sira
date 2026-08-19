import SwiftUI

struct SetupView: View {
    let variant: Variant

    @Environment(MatchStore.self) private var store
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var mode: EntrantMode
    @State private var entrantNames: [String]
    @State private var roundCount: Int
    @State private var startedMatchID: Match.ID?

    init(variant: Variant) {
        self.variant = variant
        _mode = State(initialValue: variant.teamsOnly ? .teams : .players)
        _entrantNames = State(initialValue: Array(repeating: "", count: 2))
        _roundCount = State(initialValue: variant.roundCount ?? 8)
    }

    private var modeChoosable: Bool { !variant.teamsOnly }
    private var entrantLabel: String { mode == .teams ? "Team" : "Entrant" }
    private var showsCountSelector: Bool { mode == .players }
    private var offersRoundCountChoice: Bool { variant.winCondition == .fixedRounds }

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

                if modeChoosable {
                    PillTrack(options: [.players, .teams], label: modeLabel, selection: $mode)
                }

                if showsCountSelector {
                    labeledSection("How many players") {
                        ChipSelector(options: [2, 3, 4], label: { "\($0)" }, selection: entrantCount)
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
        .onChange(of: mode) { _, newMode in
            if newMode == .teams { setEntrantCount(2) }
        }
        .navigationDestination(item: $startedMatchID) { id in
            PlayView(match: store.binding(for: id))
        }
    }

    private func modeLabel(_ mode: EntrantMode) -> String {
        switch mode {
        case .players: return "Players"
        case .teams: return "Teams of 2"
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
        }
        .foregroundStyle(theme.background)
        .background(theme.ink, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }

    private func startMatch() {
        let entrants = entrantNames.enumerated().map { index, name -> Entrant in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return Entrant(name: trimmed.isEmpty ? "\(entrantLabel) \(index + 1)" : trimmed)
        }
        let matchVariant = offersRoundCountChoice ? variant.choosingRoundCount(roundCount) : variant
        let match = Match(game: matchVariant.game, variant: matchVariant, mode: mode, entrants: entrants)
        store.add(match)
        startedMatchID = match.id
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

#Preview("Okey standard") {
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
