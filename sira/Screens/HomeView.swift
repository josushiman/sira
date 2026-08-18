import SwiftUI

struct HomeView: View {
    @Environment(MatchStore.self) private var store
    @Environment(\.theme) private var theme
    @State private var filter: MatchFilter = .active

    private var filteredMatches: [Match] {
        store.matches.filter { filter.includes($0) }
    }

    /// `.swipeActions` only has an effect on rows inside a `List` — a plain
    /// `ScrollView`/`VStack` silently ignores it — so Home's whole scrollable
    /// body is a `List` with every non-interactive row stripped of List's
    /// default chrome (separators, background, insets) to read as the
    /// prototype's plain, ungrouped layout.
    var body: some View {
        List {
            plainRow(topPadding: 10, bottomPadding: 0) { header }
            plainRow(topPadding: 12, bottomPadding: 20) { heroSection }
            plainRow(topPadding: 0, bottomPadding: 28) { gameCardsRow }
            plainRow(topPadding: 0, bottomPadding: 12) { sectionHeader }

            if filteredMatches.isEmpty {
                plainRow(topPadding: 0, bottomPadding: 0) {
                    Text(emptyStateTitle)
                        .siraStyle(.body)
                        .foregroundStyle(theme.ink.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 26)
                }
            } else {
                ForEach(filteredMatches) { match in
                    chevronlessLink(destination: PlayView(match: store.binding(for: match.id))) {
                        MatchCard(match: match)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 10, trailing: 22))
                    .swipeActions {
                        archiveButton(for: match)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .foregroundStyle(theme.ink)
        .background(theme.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func plainRow(topPadding: CGFloat, bottomPadding: CGFloat, @ViewBuilder content: () -> some View) -> some View {
        content()
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: topPadding, leading: 22, bottom: bottomPadding, trailing: 22))
    }

    /// A `NavigationLink` without List's automatic disclosure chevron — the
    /// prototype's cards don't show one. The real link is invisible and
    /// sized to fill `label`'s frame; `label` itself ignores hit testing so
    /// every tap reaches the link underneath.
    @ViewBuilder
    private func chevronlessLink(destination: some View, @ViewBuilder label: () -> some View) -> some View {
        ZStack {
            NavigationLink(destination: destination) { EmptyView() }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0)
            label()
                .allowsHitTesting(false)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Keep the\nscore honest.")
                .siraStyle(.displayHero)
            Text("Two games, four variants, one running tally that nobody can argue with.")
                .siraStyle(.body)
                .foregroundStyle(theme.ink.opacity(0.55))
        }
    }

    private var gameCardsRow: some View {
        HStack(spacing: 14) {
            ForEach(Game.allCases, id: \.self) { game in
                chevronlessLink(destination: VariantPickerView(game: game)) {
                    GameGlyphCard(game: game)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline, spacing: 9) {
            Text("Sıra")
                .siraStyle(.headline)
                .fontWeight(.heavy)
            Rectangle()
                .fill(theme.ink.opacity(0.25))
                .frame(width: 26, height: 1)
            Text(sira: .monoEyebrow, "Gonga · Okey")
                .foregroundStyle(theme.ink.opacity(0.5))
            Spacer()
        }
        .padding(.top, 10)
    }

    private var sectionHeader: some View {
        HStack(spacing: 10) {
            Text(sira: .monoEyebrow, "Your games")
                .foregroundStyle(theme.ink.opacity(0.5))
                .fixedSize()
                .layoutPriority(1)
            Rectangle()
                .fill(theme.ink.opacity(0.12))
                .frame(height: 1)
            FilterPillRow(options: MatchFilter.allCases, label: \.rawValue, selection: $filter)
                .layoutPriority(1)
        }
        .padding(.bottom, 12)
    }

    private var emptyStateTitle: String {
        switch filter {
        case .active: return "No Active Matches"
        case .all: return "No Matches"
        case .archived: return "No Archived Matches"
        }
    }

    @ViewBuilder
    private func archiveButton(for match: Match) -> some View {
        if match.archived {
            Button("Restore") { restore(match) }.tint(.blue)
        } else {
            Button("Archive") { archive(match) }.tint(.gray)
        }
    }

    private func archive(_ match: Match) {
        store.binding(for: match.id).wrappedValue.archive()
    }

    private func restore(_ match: Match) {
        store.binding(for: match.id).wrappedValue.restore()
    }
}

/// The inline Game card at the top of Home — replaces the old `GamePickerView`
/// screen. Tapping it navigates directly to that Game's Variant picker.
private struct GameGlyphCard: View {
    let game: Game

    @Environment(\.theme) private var theme

    var body: some View {
        CardSurface(padding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                glyph
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .siraStyle(.headline)
                    Text(subtitle)
                        .siraStyle(.monoLabel)
                        .tracking(1)
                        .foregroundStyle(theme.ink.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var glyph: some View {
        switch game {
        case .gonga:
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(theme.cardBack)
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(theme.line, lineWidth: 1))
                    .frame(width: 34, height: 48)
                    .rotationEffect(.degrees(-13))
                    .offset(x: 6, y: 6)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(theme.cardFace)
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(theme.line, lineWidth: 1))
                    .frame(width: 34, height: 48)
                    .overlay {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(theme.pip)
                            .frame(width: 13, height: 13)
                            .rotationEffect(.degrees(45))
                    }
                    .rotationEffect(.degrees(7))
                    .offset(x: 16, y: 2)
            }
            .frame(height: 58, alignment: .top)
        case .okey:
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(theme.cardBack)
                    .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(theme.line, lineWidth: 1))
                    .frame(width: 32, height: 46)
                    .rotationEffect(.degrees(-8))
                    .offset(x: 4, y: 8)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(theme.tile)
                    .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(.black.opacity(0.12), lineWidth: 1))
                    .frame(width: 32, height: 46)
                    .overlay {
                        VStack(spacing: 4) {
                            Text("7")
                                .siraStyle(.monoValue)
                                .foregroundStyle(theme.tileInk)
                            Circle()
                                .fill(theme.pip)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .rotationEffect(.degrees(5))
                    .offset(x: 18, y: 3)
            }
            .frame(height: 58, alignment: .top)
        }
    }

    private var title: String {
        switch game {
        case .gonga: return "Gonga"
        case .okey: return "Okey"
        }
    }

    private var subtitle: String {
        switch game {
        case .gonga: return "101 / 151"
        case .okey: return "21 / 101"
        }
    }
}

/// A Match row on Home, styled as the prototype's card: game badge, title,
/// status pill, a dashed divider, then the leader/result line.
private struct MatchCard: View {
    let match: Match

    @Environment(\.theme) private var theme

    private var standings: Standings {
        match.variant.winCondition.engine.standings(for: match)
    }

    private var summary: MatchSummary {
        MatchSummary(match: match, engine: match.variant.winCondition.engine)
    }

    private var statusText: String {
        if standings.isOver { return "Finished" }
        if match.archived { return "Archived" }
        return "Round \(match.rounds.count + 1)"
    }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 13) {
                    gameBadge
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text(match.variant.label)
                                .siraStyle(.headline)
                            StatusPill(
                                text: statusText,
                                foreground: match.archived && !standings.isOver ? theme.ink.opacity(0.6) : theme.onAccent,
                                background: match.archived && !standings.isOver ? theme.track : theme.accent
                            )
                        }
                    }
                }

                DashedDivider()

                Text(summary.text)
                    .siraStyle(.monoLabel)
                    .foregroundStyle(theme.ink.opacity(0.5))
            }
        }
        .opacity(match.archived ? 0.62 : 1)
    }

    @ViewBuilder
    private var gameBadge: some View {
        switch match.game {
        case .gonga:
            Text("♦")
                .siraStyle(.headline)
                .foregroundStyle(theme.pip)
                .frame(width: 38, height: 38)
                .background(theme.cardFace, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(theme.line, lineWidth: 1)
                }
        case .okey:
            Text("7")
                .siraStyle(.monoValue)
                .foregroundStyle(theme.tileInk)
                .frame(width: 38, height: 38)
                .background(theme.tile, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(theme.line, lineWidth: 1)
                }
        }
    }
}

#Preview("Home — populated") {
    NavigationStack {
        HomeView()
    }
    .environment(MatchStore.seeded())
    .themed()
}

#Preview("Home — empty") {
    NavigationStack {
        HomeView()
    }
    .environment(MatchStore())
    .themed()
}
