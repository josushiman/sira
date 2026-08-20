//
//  ContentView.swift
//  sira
//
//  Created by Timur Mustafa on 18/08/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    /// The app's own store, over the database on the device: whatever the
    /// player entered last time is what Home shows now, and a first launch
    /// shows nothing at all. The Alice/Bob fixtures live in previews and view
    /// tests (`MatchStore.seeded()`), which is where they were always meant to
    /// be.
    @State private var store = MatchStore.forApp()
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
        // Presented from the root so it reaches the player wherever they are:
        // the save that fails is almost always a Round being entered, several
        // screens deep.
        .alert(
            "Sıra couldn't save",
            isPresented: Binding(
                get: { store.saveFailure != nil },
                set: { presented in
                    if !presented { store.acknowledgeSaveFailure() }
                }
            )
        ) {
            Button("OK") { store.acknowledgeSaveFailure() }
        } message: {
            Text(
                """
                Your last change is still here, but it couldn't be written to \
                this device — it may be out of storage. Free some space and \
                keep playing: the next Round saves everything at once.
                """
            )
        }
        .themed()
    }
}

#Preview {
    ContentView()
}
