import SwiftUI

struct SetupView: View {
    @State private var entrantNames: [String] = ["", ""]
    @State private var startedMatch: Match?

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
        .navigationDestination(item: $startedMatch) { match in
            PlayView(initialMatch: match)
        }
    }

    private func startMatch() {
        let entrants = entrantNames.enumerated().map { index, name -> Entrant in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return Entrant(name: trimmed.isEmpty ? "Entrant \(index + 1)" : trimmed)
        }
        startedMatch = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: entrants)
    }
}

#Preview {
    NavigationStack {
        SetupView()
    }
}
