import SwiftUI

enum PlayTab: String, CaseIterable, Identifiable {
    case standings = "Standings"
    case scoresheet = "Scoresheet"

    var id: String { rawValue }
}

struct PlayView: View {
    @State private var match: Match
    @State private var showingRoundEntry = false
    @State private var rejoinQueue: [Entrant.ID] = []
    @State private var selectedTab: PlayTab = .standings

    private let engine = SurvivalEngine()

    init(initialMatch: Match) {
        _match = State(initialValue: initialMatch)
    }

    var body: some View {
        let standings = engine.standings(for: match)

        VStack(spacing: 0) {
            if standings.isOver {
                MatchOverBanner(text: standings.result ?? "Match over")
            }

            Picker("View", selection: $selectedTab) {
                ForEach(PlayTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            switch selectedTab {
            case .standings:
                List(standings.ranked) { standing in
                    StandingRow(standing: standing)
                }
                .listStyle(.plain)
            case .scoresheet:
                ScoresheetView(match: match, engine: engine)
            }

            HStack {
                Button("Undo") { undoLastRound() }
                    .buttonStyle(.bordered)
                    .disabled(match.rounds.isEmpty)

                Button("Add Round") { showingRoundEntry = true }
                    .buttonStyle(.borderedProminent)
                    .disabled(standings.isOver)
            }
            .padding()
        }
        .navigationTitle(match.variant.label)
        .sheet(isPresented: $showingRoundEntry) {
            RoundEntryView(entrants: match.entrants) { deltas, cifte in
                // Dismiss this sheet first and defer the Round append (which may
                // present the Rejoin sheet) to the next run loop turn — presenting
                // a new sheet in the same update as this one's dismissal is a race
                // UIKit can lose, silently dropping the Rejoin sheet.
                showingRoundEntry = false
                DispatchQueue.main.async {
                    match.rounds.append(Round(deltas: deltas, cifte: cifte))
                    rejoinQueue.append(contentsOf: engine.newlyOutEntrantIDs(for: match))
                }
            }
        }
        .sheet(item: rejoinBinding) { entrant in
            RejoinSheet(entrant: entrant, onAccept: { acceptRejoin(for: entrant) })
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
        let target = engine.rejoinTarget(for: match)
        match.rounds[match.rounds.count - 1].rejoins.append(RejoinEvent(id: entrant.id, to: target))
    }

    private func undoLastRound() {
        rejoinQueue.removeAll()
        match.undoLastRound()
    }
}

struct StandingRow: View {
    let standing: EntrantStanding

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(standing.name)
                    .font(.headline)
                    .strikethrough(standing.isOut)
                if standing.isOut {
                    Text("Out")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Spacer()
            Text("\(standing.total)")
                .font(.title3.monospacedDigit())
        }
        .opacity(standing.isOut ? 0.6 : 1)
    }
}

struct RejoinSheet: View {
    let entrant: Entrant
    let onAccept: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("\(entrant.name) is Out")
                .font(.title2.bold())
            Text("Offer a Rejoin? They'll come back in at the highest score still held by anyone still in.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Button("Rejoin") {
                    onAccept()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                Button("They're out") { dismiss() }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .presentationDetents([.medium])
    }
}

struct MatchOverBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.2))
    }
}

#Preview {
    NavigationStack {
        PlayView(initialMatch: Match(
            game: .gonga,
            variant: .gonga101,
            mode: .players,
            entrants: [Entrant(name: "Alice"), Entrant(name: "Bob")]
        ))
    }
}
