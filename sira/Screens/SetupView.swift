import SwiftUI

struct SetupView: View {
    let variant: Variant

    @Environment(MatchStore.self) private var store
    @State private var entrantNames: [String]
    @State private var startedMatchID: Match.ID?

    init(variant: Variant) {
        self.variant = variant
        _entrantNames = State(initialValue: Array(repeating: "", count: 2))
    }

    private var mode: EntrantMode { variant.teamsOnly ? .teams : .players }
    private var entrantLabel: String { variant.teamsOnly ? "Team" : "Entrant" }
    private var canAddEntrant: Bool { !variant.teamsOnly && entrantNames.count < 4 }
    private var canRemoveEntrant: Bool { !variant.teamsOnly && entrantNames.count > 2 }

    var body: some View {
        Form {
            Section(variant.teamsOnly ? "Teams" : "Entrants") {
                ForEach(entrantNames.indices, id: \.self) { index in
                    TextField("\(entrantLabel) \(index + 1)", text: $entrantNames[index])
                }
                if canAddEntrant {
                    Button("Add Entrant") { entrantNames.append("") }
                }
                if canRemoveEntrant {
                    Button("Remove Entrant", role: .destructive) { entrantNames.removeLast() }
                }
            }
            Section {
                Button("Start Match") { startMatch() }
            }
        }
        .navigationTitle(variant.label)
        .navigationDestination(item: $startedMatchID) { id in
            PlayView(match: store.binding(for: id))
        }
    }

    private func startMatch() {
        let entrants = entrantNames.enumerated().map { index, name -> Entrant in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return Entrant(name: trimmed.isEmpty ? "\(entrantLabel) \(index + 1)" : trimmed)
        }
        let match = Match(game: variant.game, variant: variant, mode: mode, entrants: entrants)
        store.add(match)
        startedMatchID = match.id
    }
}

#Preview {
    NavigationStack {
        SetupView(variant: .gonga101)
    }
    .environment(MatchStore())
}

#Preview("Okey standard") {
    NavigationStack {
        SetupView(variant: .okeyStandard)
    }
    .environment(MatchStore())
}
