import SwiftUI

struct VariantPickerView: View {
    let game: Game

    var body: some View {
        List(Variant.all(for: game)) { variant in
            NavigationLink {
                SetupView(variant: variant)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(variant.label)
                        .font(.headline)
                    Text(variant.ruleText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(gameTitle)
    }

    private var gameTitle: String {
        switch game {
        case .gonga: return "Gonga"
        case .okey: return "Okey"
        }
    }
}

#Preview {
    NavigationStack {
        VariantPickerView(game: .okey)
    }
}
