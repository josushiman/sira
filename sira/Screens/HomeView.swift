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

    /// The Matches this filter shows, each with its Variant already resolved.
    /// A Match naming a Variant this build doesn't know has no rules to score
    /// or label it by, so `scorable` skips it — and it is skipped here rather
    /// than inside the list, so that a filter holding nothing else still reads
    /// as empty instead of showing nothing at all.
    private var filteredMatches: [(match: Match, variant: Variant)] {
        filter.apply(to: matches).scorable
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
                    // Deliberately a context menu and not a swipe action.
                    // Archive's swipe is safe to brush against; deletion is
                    // not, and it lives behind a press-and-hold and a
                    // confirmation rather than beside the gesture that hides a
                    // Match. It is attached here, above the filter, so the same
                    // menu is on the card in Active and in Archived.
                    .contextMenu {
                        MatchCardMenu {
                            pendingDeletion = PendingDeletion(match: match)
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
        .navigationDestination(item: $navigator.openMatchID) { id in
            // Looked up rather than handed over: the Match a route names may
            // not be there to open, which is no longer the impossible case it
            // was when the store's binding crashed on an unknown id.
            if let match = matches.first(where: { $0.id == id }) {
                PlayView(match: match)
            }
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
        guard let match = matches.first(where: { $0.id == deletion.id }) else { return }
        navigator.closeDeletedMatch(match.id)
        store.delete(match)
    }

    @ViewBuilder
    private func archiveButton(for match: Match) -> some View {
        if match.archived {
            Button("Restore") { store.restore(match) }.tint(.blue)
        } else {
            Button("Archive") { store.archive(match) }.tint(.gray)
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

    private var title: String { MatchDateTitle.text(for: match.createdAt) }

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

/// How a Match is named wherever one is shown: by when it was started, which
/// is what Home sorts by and never changes. Shared by the card and the delete
/// confirmation, so the Match named in the confirmation is spelled exactly as
/// the card the player pressed.
enum MatchDateTitle {
    /// "14th March 2026 · 9pm" — the minutes are only shown when there are
    /// any, so the common on-the-hour case stays short.
    static func text(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let ordinalDay = ordinalDayFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
        let monthAndYear = date.formatted(.dateTime.month(.wide).year())
        return "\(ordinalDay) \(monthAndYear) · \(time(for: date))"
    }

    /// 12-hour clock, lowercase, minutes elided on the hour: "9pm", "9:15pm".
    private static func time(for date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
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
}

/// A Match the player has asked to delete, read off the Match at the moment
/// they asked and held as plain values from then on.
///
/// Values rather than the Match itself, because confirming deletes the Match
/// while the sheet showing it is still coming down: a sheet holding the object
/// would be reading a deleted model to draw its last frame.
struct PendingDeletion: Identifiable {
    let id: Match.ID
    /// The Match named as its Home card names it.
    let title: String
    let roundCount: Int

    init(match: Match) {
        id = match.id
        title = MatchDateTitle.text(for: match.createdAt)
        roundCount = match.rounds.count
    }
}

/// What a press-and-hold on a Match card offers. Deletion only: Archive and
/// Restore keep the swipe they already have.
///
/// A view of its own rather than an inline menu body so that the items — their
/// wording, their order, and Delete's destructive role — can be snapshot like
/// any other surface. What the snapshot cannot show is the chrome around them,
/// which is the system's and is drawn in the system's colours whichever theme
/// the app is in.
struct MatchCardMenu: View {
    let onDelete: () -> Void

    var body: some View {
        Button(role: .destructive, action: onDelete) {
            Label("Delete Match", systemImage: "trash")
        }
    }
}

/// The confirmation between the menu item and the deletion.
///
/// A themed sheet rather than a system confirmation dialog, for the same
/// reason the Rejoin offer is one: this is a decision the app asks the player
/// to make, and it is drawn in the app's own surface, in whichever theme they
/// are in, rather than in system chrome that answers to neither.
///
/// The wording's whole job is to make sure nobody taps through it expecting to
/// get the Match back: it names what goes, says it goes for good, and says
/// there is no undo.
struct DeleteMatchSheet: View {
    let deletion: PendingDeletion
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            bottomSheet
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
    }

    private var bottomSheet: some View {
        BottomSheetContent {
            VStack(alignment: .leading, spacing: 10) {
                Text("Delete this Match?")
                    .siraStyle(.displayTitle)
                Text(explanation)
                    .siraStyle(.body)
                    .foregroundStyle(theme.ink.opacity(0.6))

                VStack(spacing: 9) {
                    deleteButton
                    cancelButton
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var explanation: String {
        let subject: String
        switch deletion.roundCount {
        case 0: subject = "\(deletion.title) and its players"
        case 1: subject = "\(deletion.title), its players and the 1 Round played"
        default: subject = "\(deletion.title), its players and all \(deletion.roundCount) Rounds played"
        }
        return "\(subject) will be deleted for good. There is no undo."
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Text("Delete Match")
                .siraStyle(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        // The palette's one warning colour — the red of a Gonga pip in Paper
        // and of a tile's dot in Felt — carried here so the destructive button
        // reads as destructive in both themes. White on it rather than a theme
        // ink, which is dark in one theme and light in the other and legible on
        // red in only one of them.
        .foregroundStyle(.white)
        .background(theme.pip, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .buttonStyle(.plain)
    }

    private var cancelButton: some View {
        Button { dismiss() } label: {
            Text("Keep it")
                .siraStyle(.subheadline)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        .foregroundStyle(theme.ink.opacity(0.75))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(theme.line, lineWidth: 1)
        }
        .buttonStyle(.plain)
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
