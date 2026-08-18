import SwiftUI

struct HomeView: View {
    @Environment(MatchStore.self) private var store
    @State private var filter: MatchFilter = .active

    private var filteredMatches: [Match] {
        store.matches.filter { filter.includes($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $filter) {
                ForEach(MatchFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            if filteredMatches.isEmpty {
                ContentUnavailableView(emptyStateTitle, systemImage: "tray")
                    .frame(maxHeight: .infinity)
            } else {
                List(filteredMatches) { match in
                    NavigationLink {
                        PlayView(match: store.binding(for: match.id))
                    } label: {
                        MatchRow(match: match)
                    }
                    .swipeActions {
                        archiveButton(for: match)
                    }
                }
                .listStyle(.plain)
            }

            NavigationLink("Start Gonga Match") {
                SetupView()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Your Matches")
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

struct MatchRow: View {
    let match: Match

    private var summary: MatchSummary {
        MatchSummary(match: match, engine: match.variant.winCondition.engine)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(match.variant.label)
                    .font(.headline)
                if match.archived {
                    Text("Archived")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            Text(summary.text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(MatchStore.seeded())
}
