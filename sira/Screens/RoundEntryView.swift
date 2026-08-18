import SwiftUI

struct RoundEntryView: View {
    let entrants: [Entrant]
    /// The keypad's "never laid down" quick-entry shortcut value (Okey 101:
    /// 101). `nil` hides that shortcut for Variants that don't offer it.
    var neverLaidDownValue: Int? = nil
    let onSave: ([Entrant.ID: Int], Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var digits = ""
    @State private var deltas: [Entrant.ID: Int] = [:]
    @State private var cifteOn = false

    private var currentEntrant: Entrant { entrants[index] }
    private var currentValue: Int { Int(digits) ?? 0 }
    private var isLastEntrant: Bool { index == entrants.count - 1 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(currentEntrant.name)
                    .font(.title2.bold())
                Text(digits.isEmpty ? "0" : digits)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                if cifteOn {
                    Text("Çifte \u{2014} saves as \(currentValue * 2)")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }

                quickEntryShortcuts

                keypad

                HStack {
                    Button("Clear") { digits = "" }
                    Spacer()
                    Button(isLastEntrant ? "Save Round" : "Next") { advance() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Round \u{2014} \(currentEntrant.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Toggle("Çifte", isOn: $cifteOn)
                        .toggleStyle(.button)
                        .tint(.orange)
                }
            }
        }
    }

    private var quickEntryShortcuts: some View {
        HStack {
            Button("Won round (0)") { digits = "0" }
            if let neverLaidDownValue {
                Button("Never laid down (\(neverLaidDownValue))") { digits = "\(neverLaidDownValue)" }
            }
        }
        .buttonStyle(.bordered)
    }

    private var keypad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(1...9, id: \.self) { digit in
                keypadButton("\(digit)") { digits.append("\(digit)") }
            }
            keypadButton("⌫") { if !digits.isEmpty { digits.removeLast() } }
            keypadButton("0") { digits.append("0") }
            Color.clear
        }
    }

    private func keypadButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.title2)
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.bordered)
    }

    private func advance() {
        deltas[currentEntrant.id] = currentValue
        digits = ""
        if isLastEntrant {
            onSave(deltas, cifteOn)
        } else {
            index += 1
        }
    }
}

#Preview {
    RoundEntryView(entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")]) { _, _ in }
}

#Preview("Okey 101") {
    RoundEntryView(
        entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")],
        neverLaidDownValue: 101
    ) { _, _ in }
}
