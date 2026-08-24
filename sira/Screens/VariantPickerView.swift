import SwiftUI

struct VariantPickerView: View {
    let game: Game

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Which variant?")
                    .siraStyle(.displayTitle)

                VStack(spacing: 12) {
                    ForEach(Variant.all(for: game)) { variant in
                        NavigationLink {
                            SetupView(variant: variant)
                        } label: {
                            VariantCard(variant: variant)
                        }
                        .buttonStyle(.plain)
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
    }

    private var header: some View {
        HStack(spacing: 12) {
            BackButton { dismiss() }

            Text(sira: .monoEyebrow, gameTitle)
                .foregroundStyle(theme.ink.opacity(0.5))

            Spacer()
        }
    }

    private var gameTitle: String {
        switch game {
        case .gonga: return "Gonga"
        case .okey: return "Okey"
        }
    }
}

/// A Variant row on the Variant picker: label, a hairline divider, then the
/// rule text.
///
/// The prototype's muted numeric tag is deliberately absent. The Picker runs
/// before Setup, so no number has been chosen yet — the tag could only ever
/// show a constant as decoration, and now that Setup asks for the number it
/// would be quoting a value the player is one screen away from choosing.
private struct VariantCard: View {
    let variant: Variant

    @Environment(\.theme) private var theme

    var body: some View {
        CardSurface(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text(variant.label)
                    .siraStyle(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(theme.line)
                    .frame(height: 1)

                Text(variant.ruleText)
                    .siraStyle(.body)
                    .foregroundStyle(theme.ink.opacity(0.6))
            }
        }
    }
}

#Preview {
    NavigationStack {
        VariantPickerView(game: .okey)
    }
    .themed()
}
