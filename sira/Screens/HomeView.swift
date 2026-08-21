import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(MatchStore.self) private var store
    /// Every Match there is, read through the framework rather than kept in a
    /// hand-maintained array: `@Query` re-runs itself when the context changes,
    /// so a Match started in Setup or a Round added in Play reaches this list
    /// without anything having to tell it to. Filtering and ordering stay with
    /// `MatchFilter`, which is where Home's own rules live.
    @Query private var matches: [Match]
    /// What's pushed above Home. Held outside this view so that Play, however
    /// deep it sits, can clear it and come straight back here — see
    /// `Navigator`.
    @Environment(Navigator.self) private var navigator
    @Environment(\.theme) private var theme
    @State private var filter: MatchFilter = .active
    /// The Match whose deletion is being confirmed, or `nil` when no
    /// confirmation is on screen. Everything the sheet shows is read off the
    /// Match here, when the menu item is tapped, rather than while the sheet is
    /// up: confirming deletes the Match out from under a sheet that is still
    /// dismissing, and a deleted model is not something to be reading
    /// properties from.
    @State private var pendingDeletion: PendingDeletion?

    /// The Match the route into Play resolves to, or nothing.
    ///
    /// The route names a Match by id, and the id is resolved through
    /// `scorableMatch` rather than against every stored Match: it can name one
    /// that was deleted, or one whose Variant id this build doesn't know, and
    /// Play has no rules to score either. Resolving here rather than inside
    /// the destination is what keeps such a Match from ever being pushed —
    /// there is no screen to retreat from, so the player simply stays on Home
    /// instead of watching a blank one appear and go away again.
    ///
    /// Not `filteredMatches`: archiving the Match being played is no reason to
    /// close it, and the Archived filter is a view of Home's list rather than
    /// a statement about what can be scored.
    private var openMatch: Binding<Match?> {
        Binding(
            get: { matches.scorableMatch(navigator.openMatchID) },
            set: { navigator.openMatchID = $0?.id }
        )
    }

    /// The cards this filter shows, each drawn from a Match whose Variant is
    /// already resolved. A Match naming a Variant this build doesn't know has
    /// no rules to score or label it by, so `scorable` skips it — and it is
    /// skipped here rather than inside the list, so that a filter holding
    /// nothing else still reads as empty instead of showing nothing at all.
    ///
    /// Cards rather than Matches, so that nothing below this line holds a
    /// model that can be deleted out from under it — see `HomeCard`. A Match
    /// already deleted is dropped before anything reads it: `@Query`'s array
    /// can still name one for the redraw that follows the deletion, and every
    /// property of a deleted Match traps rather than answering.
    private var filteredMatches: [HomeCard] {
        filter
            .apply(to: matches.filter { !$0.isGone })
            .scorable
            // A closure rather than `.map(HomeCard.init)`: the unapplied
            // initializer is a function value that carries none of the main
            // actor this view runs on, which the compiler warns about today
            // and rejects outright under the Swift 6 language mode.
            .map { HomeCard(match: $0.match, variant: $0.variant) }
    }

    /// `.swipeActions` only has an effect on rows inside a `List` — a plain
    /// `ScrollView`/`VStack` silently ignores it — so Home's whole scrollable
    /// body is a `List` with every non-interactive row stripped of List's
    /// default chrome (separators, background, insets) to read as the
    /// prototype's plain, ungrouped layout.
    var body: some View {
        @Bindable var navigator = navigator
        // Read once per pass, not once per mention. Building the cards scores
        // every Match it lists, and `filteredMatches` is asked for twice in
        // the body below — once to decide whether the list is empty and once
        // to fill it.
        let cards = filteredMatches
        return List {
            plainRow(topPadding: 10, bottomPadding: 0) { header }
            plainRow(topPadding: 12, bottomPadding: 20) { heroSection }
            plainRow(topPadding: 0, bottomPadding: 28) { gameCardsRow }
            plainRow(topPadding: 0, bottomPadding: 12) { sectionHeader }

            if cards.isEmpty {
                plainRow(topPadding: 0, bottomPadding: 0) {
                    Text(emptyStateTitle)
                        .siraStyle(.body)
                        .foregroundStyle(theme.ink.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 26)
                }
            } else {
                ForEach(cards) { card in
                    Button {
                        navigator.openMatchID = card.id
                    } label: {
                        MatchCard(card: card)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 10, trailing: 22))
                    .swipeActions {
                        archiveButton(for: card)
                    }
                    // Deliberately a context menu and not a swipe action.
                    // Archive's swipe is safe to brush against; deletion is
                    // not, and it lives behind a press-and-hold and a
                    // confirmation rather than beside the gesture that hides a
                    // Match. It is attached here, above the filter, so the same
                    // menu is on the card in Active and in Archived.
                    .contextMenu {
                        MatchCardMenu {
                            pendingDeletion = PendingDeletion(card: card)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .foregroundStyle(theme.ink)
        .background(theme.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $pendingDeletion) { deletion in
            DeleteMatchSheet(deletion: deletion) { delete(deletion) }
        }
        .navigationDestination(item: $navigator.pickingVariantsFor) { game in
            VariantPickerView(game: game)
        }
        .navigationDestination(item: openMatch) { match in
            PlayView(match: match)
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

    /// Carries out the deletion the player has just confirmed: the
    /// confirmation comes down, the Match goes, and anything pointing at it
    /// stops pointing at it.
    ///
    /// Order matters. The route is cleared before the Match is deleted so that
    /// nothing is left holding a route to an object that no longer exists, and
    /// the sheet is dismissed first so it is on its way out before its subject
    /// is gone.
    private func delete(_ deletion: PendingDeletion) {
        pendingDeletion = nil
        guard let match = match(deletion.id) else { return }
        navigator.closeDeletedMatch(match.id)
        store.delete(match)
    }

    /// The Match a card stands for, or nothing if it is already gone. Cards
    /// hold values rather than models (`HomeCard`), so the Match a swipe or a
    /// confirmation acts on is looked up when the player acts, not held from
    /// when the row was drawn.
    private func match(_ id: Match.ID) -> Match? {
        matches.first { !$0.isGone && $0.id == id }
    }

    @ViewBuilder
    private func archiveButton(for card: HomeCard) -> some View {
        if card.archived {
            Button("Restore") {
                if let match = match(card.id) { store.restore(match) }
            }
            .tint(.blue)
        } else {
            Button("Archive") {
                if let match = match(card.id) { store.archive(match) }
            }
            .tint(.gray)
        }
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
    /// Everything the card draws, read off the Match by Home rather than by
    /// this view — see `HomeCard` for why the card holds no Match of its own.
    let card: HomeCard

    @Environment(\.theme) private var theme

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

                Text(card.summaryText)
                    .siraStyle(.monoLabel)
                    .foregroundStyle(theme.ink.opacity(0.5))
            }
        }
        .opacity(card.archived ? 0.62 : 1)
    }

    /// Kept to one line — a long month plus minutes ("14th September 2026 ·
    /// 10:15pm") shrinks slightly rather than wrapping the date in two.
    private var titleText: some View {
        Text(card.title)
            .siraStyle(.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    private var pills: some View {
        HStack(spacing: 5) {
            StatusPill(
                text: card.statusText,
                foreground: card.statusIsMuted ? theme.ink.opacity(0.6) : theme.onAccent,
                background: card.statusIsMuted ? theme.track : theme.accent
            )
            metaPill(card.entrantsText)
            metaPill(card.variantLabel)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func metaPill(_ text: String) -> some View {
        StatusPill(text: text, foreground: theme.ink.opacity(0.6), background: theme.track)
    }

    @ViewBuilder
    private var gameBadge: some View {
        switch card.game {
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

// `#Preview` bodies are compiled in every configuration, not only Debug, so a
// preview drawing the Alice/Bob fixtures has to say where those fixtures exist
// — `MatchStore.seeded()` is `#if DEBUG` precisely so it cannot ship.
#if DEBUG

#Preview("Home — populated") {
    HomePreview(store: .seeded())
}

#Preview("Home — empty") {
    HomePreview(store: MatchStore())
}

/// Home with a store and its container wired together, which `@Query` needs and
/// a bare `.environment(store)` no longer supplies.
private struct HomePreview: View {
    let store: MatchStore

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .environment(store)
        .environment(Navigator())
        .modelContainer(store.container)
        .themed()
    }
}

#endif
