import SwiftUI

struct SetupView: View {
    @Environment(MatchStore.self) private var store
    @State private var entrantNames: [String] = ["", ""]
    @State private var startedMatchID: Match.ID?

    private var canAddEntrant: Bool { entrantNames.count < 4 }
    private var canRemoveEntrant: Bool { entrantNames.count > 2 }

    var body: some View {
        Form {
            Section("Entrants") {
                ForEach(entrantNames.indices, id: \.self) { index in
                    TextField("Entrant \(index + 1)", text: $entrantNames[index])
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
        .navigationTitle(Variant.gonga101.label)
        .navigationDestination(item: $startedMatchID) { id in
            PlayView(match: store.binding(for: id))
        }
    }

    private func startMatch() {
        let entrants = entrantNames.enumerated().map { index, name -> Entrant in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return Entrant(name: trimmed.isEmpty ? "Entrant \(index + 1)" : trimmed)
        }
        let match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: entrants)
        store.add(match)
        startedMatchID = match.id
    }
}

#Preview {
    NavigationStack {
        SetupView()
    }
    .environment(MatchStore())
}
