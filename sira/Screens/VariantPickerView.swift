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
            Button {
                dismiss()
            } label: {
                Text("‹")
                    .siraStyle(.headline)
            }
            .frame(width: 34, height: 34)
            .background(theme.surface, in: Circle())
            .overlay { Circle().stroke(theme.line, lineWidth: 1) }
            .foregroundStyle(theme.ink)
            .buttonStyle(.plain)

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

/// A Variant row on the Variant picker, styled as the prototype's card:
/// label, a muted numeric tag, a hairline divider, then the rule text.
private struct VariantCard: View {
    let variant: Variant

    @Environment(\.theme) private var theme

    var body: some View {
        CardSurface(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(variant.label)
                        .siraStyle(.headline)
                    Spacer()
                    Text(sira: .monoValueLarge, tag)
                        .foregroundStyle(theme.ink.opacity(0.22))
                }

                Rectangle()
                    .fill(theme.line)
                    .frame(height: 1)

                Text(variant.ruleText)
                    .siraStyle(.body)
                    .foregroundStyle(theme.ink.opacity(0.6))
            }
        }
    }

    /// The prototype's short numeric tag per Variant — its Survival limit,
    /// Elimination starting score, or Fixed Rounds "never laid down" value,
    /// whichever the Variant defines.
    private var tag: String {
        if let limit = variant.limit { return "\(limit)" }
        if let startingScore = variant.startingScore { return "\(startingScore)" }
        if let neverLaidDownValue = variant.neverLaidDownValue { return "\(neverLaidDownValue)" }
        return ""
    }
}

#Preview {
    NavigationStack {
        VariantPickerView(game: .okey)
    }
    .themed()
}
