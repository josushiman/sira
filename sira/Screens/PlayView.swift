import SwiftUI

enum PlayTab: String, CaseIterable, Identifiable {
    case standings = "Standings"
    case scoresheet = "Scoresheet"

    var id: String { rawValue }
}

struct PlayView: View {
    @Binding var match: Match
    @State private var showingKeypadEntry = false
    @State private var showingOkeyEntry = false
    @State private var rejoinQueue: [Entrant.ID] = []
    @State private var selectedTab: PlayTab

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    /// Optional so Play still renders on its own in a preview or a snapshot,
    /// where nothing above it is doing any navigating.
    @Environment(Navigator.self) private var navigator: Navigator?

    init(match: Binding<Match>, initialTab: PlayTab = .standings) {
        _match = match
        _selectedTab = State(initialValue: initialTab)
    }

    private var engine: MatchEngine { match.variant.winCondition.engine }

    var body: some View {
        let standings = engine.standings(for: match)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PillTrack(options: PlayTab.allCases, label: \.rawValue, selection: $selectedTab)
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                switch selectedTab {
                case .standings:
                    standingsContent(standings)
                case .scoresheet:
                    ScoresheetView(match: match, engine: engine)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            addRoundButton(isOver: standings.isOver)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(theme.background)
        }
        .navigationDestination(isPresented: $showingKeypadEntry) {
            keypadRoundEntry(standings)
        }
        .navigationDestination(isPresented: $showingOkeyEntry) {
            okeyStandardRoundEntry
        }
        .sheet(item: rejoinBinding) { entrant in
            if let survivalEngine = engine as? SurvivalEngine {
                RejoinSheet(
                    entrant: entrant,
                    score: standings.ranked.first { $0.entrantID == entrant.id }?.total ?? 0,
                    limit: match.variant.limit ?? 0,
                    target: survivalEngine.rejoinTarget(for: match),
                    onAccept: { acceptRejoin(for: entrant) }
                )
            }
        }
    }

    @ViewBuilder
    private func standingsContent(_ standings: Standings) -> some View {
        if standings.isOver {
            MatchOverBanner(text: standings.result ?? "Match over")
                .padding(.bottom, 14)
        }

        CardSurface(cornerRadius: 24, padding: 6) {
            VStack(spacing: 0) {
                ForEach(Array(standings.ranked.enumerated()), id: \.element.id) { index, standing in
                    StandingRow(
                        standing: standing,
                        rank: index + 1,
                        badgeIndex: badgeIndex(for: standing.entrantID),
                        isLeader: index == 0 && !standing.isOut && !standings.isOver,
                        maxAbsTotal: maxAbsTotal(standings),
                        roomLeft: roomLeft(for: standing)
                    )
                }
            }
        }

        let stats = PlayStats(match: match, standings: standings)
        HStack(spacing: 10) {
            StatTile(label: stats.leadLabel, value: stats.leadValue)
            StatTile(label: stats.secondaryLabel, value: stats.secondaryValue)
        }
        .padding(.top, 14)
    }

    private func badgeIndex(for entrantID: Entrant.ID) -> Int {
        match.entrants.firstIndex { $0.id == entrantID } ?? 0
    }

    /// How much an Entrant can still take before passing the Variant's limit.
    /// Only Survival Variants have a limit to run out of, and an Entrant
    /// already Out has none left to report — both read as `nil`.
    private func roomLeft(for standing: EntrantStanding) -> Int? {
        guard let limit = match.variant.limit, !standing.isOut else { return nil }
        return max(0, limit - standing.total)
    }

    /// The largest total magnitude among all Standings, used to normalize
    /// each Standing's progress-bar width — matches the prototype's `maxAbs`.
    private func maxAbsTotal(_ standings: Standings) -> Int {
        let entrantMax = standings.ranked.map { abs($0.total) }.max() ?? 0
        let variantScale = match.variant.limit ?? match.variant.startingScore ?? entrantMax
        return max(1, variantScale)
    }

    private func keypadRoundEntry(_ standings: Standings) -> some View {
        let stillIn = match.entrants.filter { entrant in
            standings.ranked.first { $0.entrantID == entrant.id }.map { !$0.isOut } ?? true
        }
        let totals = Dictionary(uniqueKeysWithValues: standings.ranked.map { ($0.entrantID, $0.total) })
        let badgeIndices = Dictionary(uniqueKeysWithValues: match.entrants.enumerated().map { ($1.id, $0) })
        return RoundEntryView(
            entrants: stillIn,
            roundNumber: match.rounds.count + 1,
            totals: totals,
            badgeIndices: badgeIndices,
            neverLaidDownValue: match.variant.neverLaidDownValue,
            supportsCifte: match.variant.supportsCifte,
            game: match.game
        ) { deltas, cifteCallers, okeyAtanID in
            // Pop this push first and defer the Round append (which may present
            // the Rejoin sheet) to the next run loop turn — presenting a sheet in
            // the same update as a navigation transition is a race UIKit can
            // lose, silently dropping the Rejoin sheet.
            showingKeypadEntry = false
            DispatchQueue.main.async {
                match.rounds.append(Round(
                    deltas: deltas,
                    cifteCallers: cifteCallers,
                    okeyAtanID: okeyAtanID
                ))
                if let survivalEngine = engine as? SurvivalEngine {
                    rejoinQueue.append(contentsOf: survivalEngine.newlyOutEntrantIDs(for: match))
                }
            }
        }
    }

    private var okeyStandardRoundEntry: some View {
        OkeyStandardRoundEntryView(entrants: match.entrants, roundNumber: match.rounds.count + 1) { losingEntrantID, gostergeFinderID, cifteCallers, okeyAtti in
            showingOkeyEntry = false
            DispatchQueue.main.async {
                // Okey atmak is winning the Round, so the atan is the other team.
                let winnerID = match.entrants.first { $0.id != losingEntrantID }?.id
                match.rounds.append(Round(
                    cifteCallers: cifteCallers,
                    okeyAtanID: okeyAtti ? winnerID : nil,
                    losingEntrantID: losingEntrantID,
                    gostergeFinderID: gostergeFinderID
                ))
            }
        }
    }

    private var rejoinBinding: Binding<Entrant?> {
        Binding(
            get: { rejoinQueue.first.flatMap { id in match.entrants.first { $0.id == id } } },
            set: { newValue in
                if newValue == nil, !rejoinQueue.isEmpty {
                    rejoinQueue.removeFirst()
                }
            }
        )
    }

    private func acceptRejoin(for entrant: Entrant) {
        guard let survivalEngine = engine as? SurvivalEngine else { return }
        let target = survivalEngine.rejoinTarget(for: match)
        match.rounds[match.rounds.count - 1].rejoins.append(RejoinEvent(id: entrant.id, to: target))
    }

    /// Leaves the Match for Home, falling back to an ordinary dismiss where
    /// Home isn't an ancestor — a preview, or a snapshot of Play on its own.
    private func leave() {
        if let navigator {
            navigator.goHome()
        } else {
            dismiss()
        }
    }

    private func undoLastRound() {
        rejoinQueue.removeAll()
        match.undoLastRound()
    }

    private var header: some View {
        HStack(spacing: 11) {
            // The Match exists from the moment Play opens, so leaving means
            // leaving the Match — never stepping back into the Setup screen
            // that built it, Rounds scored or not.
            HomeButton { leave() }

            VStack(alignment: .leading, spacing: 5) {
                Text(match.variant.label)
                    .siraStyle(.subheadline)
                Text(sira: .monoLabel, playSubtitle)
                    .foregroundStyle(theme.ink.opacity(0.5))
            }

            Spacer()

            HStack(spacing: 7) {
                archiveButton
                undoButton
            }
        }
    }

    private var playSubtitle: String {
        let count = match.entrants.count
        let noun = match.mode == .teams ? (count == 1 ? "team" : "teams") : (count == 1 ? "player" : "players")
        return "\(count) \(noun)"
    }

    private var archiveButton: some View {
        Button {
            if match.archived {
                match.restore()
            } else {
                match.archive()
                // Archiving is done with this Match, so it lands on Home
                // rather than on whatever screen happened to push it.
                leave()
            }
        } label: {
            Text(match.archived ? "Restore" : "Archive")
                .siraStyle(.caption)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .contentShape(Capsule())
        }
        .foregroundStyle(theme.ink.opacity(0.7))
        .background(theme.track, in: Capsule())
        .buttonStyle(.plain)
    }

    private var undoButton: some View {
        Button {
            undoLastRound()
        } label: {
            Text("Undo")
                .siraStyle(.caption)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .contentShape(Capsule())
        }
        .foregroundStyle(theme.ink.opacity(match.rounds.isEmpty ? 0.35 : 1))
        .background(theme.surface, in: Capsule())
        .overlay {
            Capsule().stroke(theme.line, lineWidth: 1)
        }
        .buttonStyle(.plain)
        .disabled(match.rounds.isEmpty)
    }

    @ViewBuilder
    private func addRoundButton(isOver: Bool) -> some View {
        Button {
            switch match.variant.entryStyle {
            case .keypad: showingKeypadEntry = true
            case .okeyStandard: showingOkeyEntry = true
            }
        } label: {
            Text(isOver ? "Match finished" : "Add round \(match.rounds.count + 1) scores")
                .siraStyle(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .foregroundStyle(isOver ? theme.ink.opacity(0.5) : theme.background)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isOver ? theme.surface : theme.ink)
                .overlay {
                    if isOver {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(theme.line, lineWidth: 1)
                    }
                }
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .disabled(isOver)
    }
}

/// A Standings row: rank, dot badge, name with LEADS/OUT tag, a progress bar
/// scaled to the Match's biggest total with the Entrant's Room left beside it,
/// and the score with its last delta.
struct StandingRow: View {
    let standing: EntrantStanding
    let rank: Int
    let badgeIndex: Int
    let isLeader: Bool
    let maxAbsTotal: Int
    /// Points before this Entrant passes the limit, where the Variant has one.
    var roomLeft: Int?

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            Text(sira: .monoLabel, standing.isOut ? "—" : "\(rank)")
                .foregroundStyle(theme.ink.opacity(0.35))
                .frame(width: 14, alignment: .leading)

            DotBadge(text: initial, index: badgeIndex, size: 34)
                .opacity(standing.isOut ? 0.4 : 1)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Text(standing.name)
                        .siraStyle(.headline)
                        .lineLimit(1)
                    if standing.isOut {
                        StatusPill(text: "Out", foreground: theme.background, background: theme.accent2)
                    } else if isLeader {
                        StatusPill(text: "Leads", foreground: theme.onAccent, background: theme.accent)
                    }
                }

                HStack(spacing: 10) {
                    progressBar
                    if let roomLeft {
                        Text(sira: .monoLabel, "\(roomLeft) left")
                            .foregroundStyle(theme.ink.opacity(0.42))
                            .fixedSize()
                    }
                }
            }

            VStack(alignment: .trailing, spacing: 7) {
                Text("\(standing.total)")
                    .siraStyle(.monoValueLarge)
                    .foregroundStyle(isLeader ? theme.accent : theme.ink)
                Text(deltaText)
                    .siraStyle(.monoLabel)
                    .foregroundStyle(theme.ink.opacity(0.42))
            }
            .frame(minWidth: 52, alignment: .trailing)
        }
        .padding(13)
        .background {
            if isLeader {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(theme.track)
            }
        }
        .opacity(standing.isOut ? 0.5 : 1)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let fraction = min(1, Double(abs(standing.total)) / Double(maxAbsTotal))
            ZStack(alignment: .leading) {
                Capsule().fill(theme.track)
                Capsule()
                    .fill(standing.isOut ? theme.line : (isLeader ? theme.accent : theme.ink.opacity(0.35)))
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 4)
    }

    private var initial: String { standing.name.dotBadgeInitial }

    private var deltaText: String {
        standing.deltaFromLastRound == 0 && standing.total == 0 ? "—" : signedText(standing.deltaFromLastRound)
    }

    private func signedText(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }
}

/// One of Play's two summary tiles above Standings: a label over a value.
private struct StatTile: View {
    let label: String
    let value: String

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(sira: .monoEyebrow, label)
                .foregroundStyle(theme.ink.opacity(0.5))
            Text(value)
                .siraStyle(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.line, lineWidth: 1)
        }
    }
}

/// The Rejoin offer shown when an Entrant busts, styled as the prototype's
/// slide-up bottom sheet (`BottomSheetContent`) via native `.sheet(item:)`.
struct RejoinSheet: View {
    let entrant: Entrant
    let score: Int
    let limit: Int
    let target: Int
    let onAccept: () -> Void

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
                Text("\(entrant.name) is Out")
                    .siraStyle(.displayTitle)
                Text("\(entrant.name) passed \(limit) on \(score). They can rejoin at the highest score still on the table.")
                    .siraStyle(.body)
                    .foregroundStyle(theme.ink.opacity(0.6))

                VStack(spacing: 9) {
                    Button {
                        onAccept()
                        dismiss()
                    } label: {
                        Text("Rejoin at \(target)")
                            .siraStyle(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                    .foregroundStyle(theme.background)
                    .background(theme.ink, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .buttonStyle(.plain)

                    Button {
                        dismiss()
                    } label: {
                        Text("They're out")
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
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// The accent-colored "Match over" banner shown above Standings once the
/// Match's Win Condition is met.
struct MatchOverBanner: View {
    let text: String

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(sira: .monoEyebrow, "Match over")
                .foregroundStyle(theme.onAccent.opacity(0.65))
            Text(text)
                .siraStyle(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .foregroundStyle(theme.onAccent)
        .background(theme.accent, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        PlayView(match: .constant(Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")]
        )))
    }
    .themed()
}

#Preview("Okey standard") {
    NavigationStack {
        PlayView(match: .constant(Match(
            game: .okey,
            variant: .okeyStandard,
            mode: .teams,
            entrants: [Entrant(name: "Team A"), Entrant(name: "Team B")]
        )))
    }
    .themed()
}

#Preview("Okey 101") {
    NavigationStack {
        PlayView(match: .constant(Match(
            game: .okey,
            variant: .okey101,
            mode: .players,
            entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")]
        )))
    }
    .themed()
}
