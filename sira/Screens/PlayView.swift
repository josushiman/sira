import SwiftUI

struct PlayView: View {
    @State private var match: Match
    @State private var showingRoundEntry = false

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

            List(standings.ranked) { standing in
                StandingRow(standing: standing)
            }
            .listStyle(.plain)

            Button("Add Round") { showingRoundEntry = true }
                .buttonStyle(.borderedProminent)
                .disabled(standings.isOver)
                .padding()
        }
        .navigationTitle(match.variant.label)
        .sheet(isPresented: $showingRoundEntry) {
            RoundEntryView(entrants: match.entrants) { deltas in
                match.rounds.append(Round(deltas: deltas))
                showingRoundEntry = false
            }
        }
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
