//
//  ContentView.swift
//  sira
//
//  Created by Timur Mustafa on 18/08/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    /// Seeded for now, so the app behaves exactly as it did before the store
    /// was put behind a database. The container is in memory, so this is still
    /// a fresh two-Match history on every launch. Ticket 06 makes it durable
    /// and ticket 07 empties it.
    @State private var store = MatchStore.seeded()
    @State private var navigator = Navigator()

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .environment(store)
        .environment(navigator)
        // Home reads Matches with `@Query`, which needs the container the store
        // is writing to — the same one, so a Round added in Play shows up in
        // Home's summary without anything being told to refresh.
        .modelContainer(store.container)
        .themed()
    }
}

#Preview {
    ContentView()
}
