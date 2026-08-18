import SwiftUI

struct OkeyStandardRoundEntryView: View {
    let entrants: [Entrant]
    let onSave: (_ losingEntrantID: Entrant.ID?, _ gostergeFinds: [Entrant.ID: Int], _ cifte: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var losingEntrantID: Entrant.ID?
    @State private var gostergeFinds: [Entrant.ID: Int] = [:]
    @State private var cifteOn = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Who lost the Round?") {
                    Picker("Losing team", selection: $losingEntrantID) {
                        Text("Nobody").tag(Entrant.ID?.none)
                        ForEach(entrants) { entrant in
                            Text(entrant.name).tag(Optional(entrant.id))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Gösterge") {
                    ForEach(entrants) { entrant in
                        Stepper(
                            "\(entrant.name): \(gostergeFinds[entrant.id] ?? 0)",
                            value: Binding(
                                get: { gostergeFinds[entrant.id] ?? 0 },
                                set: { gostergeFinds[entrant.id] = $0 }
                            ),
                            in: 0...1
                        )
                    }
                }

                Section {
                    Toggle("Çifte", isOn: $cifteOn)
                        .tint(.orange)
                }
            }
            .navigationTitle("Okey Round")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Round") {
                        onSave(losingEntrantID, gostergeFinds, cifteOn)
                    }
                }
            }
        }
    }
}

#Preview {
    OkeyStandardRoundEntryView(entrants: [Entrant(name: "Team A"), Entrant(name: "Team B")]) { _, _, _ in }
}
