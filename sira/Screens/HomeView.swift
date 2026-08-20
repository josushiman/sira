import SwiftUI

struct HomeView: View {
    @Environment(MatchStore.self) private var store
    /// What's pushed above Home. Held outside this view so that Play, however
    /// deep it sits, can clear it and come straight back here — see
    /// `Navigator`.
    @Environment(Navigator.self) private var navigator
    @Environment(\.theme) private var theme
    @State private var filter: MatchFilter = .active

    /// The Matches this filter shows, each with its Variant already resolved.
    /// A Match naming a Variant this build doesn't know has no rules to score
    /// or label it by, so it is skipped rather than shown under a substitute —
    /// and skipped here rather than inside the list, so that a filter holding
    /// nothing else still reads as empty instead of showing nothing at all.
    private var filteredMatches: [(match: Match, variant: Variant)] {
        filter.apply(to: store.matches).compactMap { match in
            match.variant.map { (match: match, variant: $0) }
        }
    }

    /// `.swipeActions` only has an effect on rows inside a `List` — a plain
    /// `ScrollView`/`VStack` silently ignores it — so Home's whole scrollable
    /// body is a `List` with every non-interactive row stripped of List's
    /// default chrome (separators, background, insets) to read as the
    /// prototype's plain, ungrouped layout.
    var body: some View {
        @Bindable var navigator = navigator
        return List {
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
                ForEach(filteredMatches, id: \.match.id) { match, variant in
                    Button {
                        navigator.openMatchID = match.id
                    } label: {
                        MatchCard(match: match, variant: variant)
                    }
                    .buttonStyle(.plain)
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
        .navigationDestination(item: $navigator.pickingVariantsFor) { game in
            VariantPickerView(game: game)
        }
        .navigationDestination(item: $navigator.openMatchID) { id in
            PlayView(match: store.binding(for: id))
        }
    }

    @ViewBuilder
    private func plainRow(topPadding: CGFloat, bottomPadding: CGFloat, @ViewBuilder content: () -> some View) -> some View {
        content()
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: topPadding, leading: 22, bottom: bottomPadding, trailing: 22))
    }

    /// The Match cards, like the Game cards below, deliberately use a plain
    /// `Button` driving an item binding rather than a `NavigationLink`: a link
    /// leaves `List` owning the push, which nothing can then pop, and Play
    /// needs to be poppable from its own Home button.
    ///
    /// The Game cards deliberately use a plain `Button` driving
    /// `pickingVariantsFor` rather than a `NavigationLink`. Both cards live in
    /// a single `List` row, and `List` binds row-level navigation to *a* link
    /// inside that row — with two links sharing a row it resolves the wrong
    /// one, which is what made Back, after picking Okey, land on Gonga's
    /// Variant picker instead of Home. A Button carries no such row semantics,
    /// so each card pushes exactly the Game it shows.
    @ViewBuilder
    private func gameCardButton(for game: Game, @ViewBuilder label: () -> some View) -> some View {
        Button {
            navigator.pickingVariantsFor = game
        } label: {
            label()
                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
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
                gameCardButton(for: game) {
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

/// A Match row on Home, styled as the prototype's card: game badge, the date
/// the Match was started, a row of meta pills (round, table size, Variant), a
/// dashed divider, then the leader/result line.
private struct MatchCard: View {
    let match: Match
    /// Resolved by Home before the card is built — a Match whose Variant id
    /// resolves to nothing never gets a card at all.
    let variant: Variant

    @Environment(\.theme) private var theme

    private var standings: Standings {
        variant.winCondition.engine.standings(for: match)
    }

    private var summary: MatchSummary {
        MatchSummary(match: match, engine: variant.winCondition.engine)
    }

    /// When the Match was started, as "14th March 2026 · 9pm" — the minutes
    /// are only shown when there are any, so the common on-the-hour case stays
    /// short.
    private var title: String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: match.createdAt)
        let ordinalDay = Self.ordinalDayFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
        let monthAndYear = match.createdAt.formatted(.dateTime.month(.wide).year())
        return "\(ordinalDay) \(monthAndYear) · \(time)"
    }

    /// 12-hour clock, lowercase, minutes elided on the hour: "9pm", "9:15pm".
    private var time: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: match.createdAt)
        let minute = calendar.component(.minute, from: match.createdAt)
        let suffix = hour < 12 ? "am" : "pm"
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        return minute == 0
            ? "\(hour12)\(suffix)"
            : String(format: "%d:%02d%@", hour12, minute, suffix)
    }

    private static let ordinalDayFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()

    private var statusText: String {
        if standings.isOver { return "Finished" }
        if match.archived { return "Archived" }
        return "Round \(match.rounds.count + 1)"
    }

    /// Archived-but-unfinished is the one status that reads muted rather than
    /// as the accent-coloured "where the Match is up to" pill.
    private var statusIsMuted: Bool {
        match.archived && !standings.isOver
    }

    private var entrantsText: String {
        let count = match.entrants.count
        switch match.mode {
        case .players: return "\(count) \(count == 1 ? "player" : "players")"
        case .teams: return "\(count) \(count == 1 ? "team" : "teams")"
        }
    }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 13) {
                    gameBadge
                    VStack(alignment: .leading, spacing: 8) {
                        titleText
                        pills
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

    /// Kept to one line — a long month plus minutes ("14th September 2026 ·
    /// 10:15pm") shrinks slightly rather than wrapping the date in two.
    private var titleText: some View {
        Text(title)
            .siraStyle(.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    private var pills: some View {
        HStack(spacing: 5) {
            StatusPill(
                text: statusText,
                foreground: statusIsMuted ? theme.ink.opacity(0.6) : theme.onAccent,
                background: statusIsMuted ? theme.track : theme.accent
            )
            metaPill(entrantsText)
            metaPill(variant.label)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func metaPill(_ text: String) -> some View {
        StatusPill(text: text, foreground: theme.ink.opacity(0.6), background: theme.track)
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
    .environment(Navigator())
    .themed()
}

#Preview("Home — empty") {
    NavigationStack {
        HomeView()
    }
    .environment(MatchStore())
    .environment(Navigator())
    .themed()
}
