import SwiftUI

struct RoundEntryView: View {
    let entrants: [Entrant]
    let onSave: ([Entrant.ID: Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var digits = ""
    @State private var deltas: [Entrant.ID: Int] = [:]

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
            }
        }
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
            onSave(deltas)
        } else {
            index += 1
        }
    }
}

#Preview {
    RoundEntryView(entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")]) { _ in }
}
