//
//  ContentView.swift
//  sira
//
//  Created by Timur Mustafa on 18/08/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    /// The store this app is running on, handed in by the scene that opened it
    /// (`siraApp`) rather than opened here. Nothing about a store belongs in a
    /// view's initialiser: opening one is launch work, it happens once, and a
    /// view cannot promise that. The Alice/Bob fixtures live in previews and
    /// view tests (`MatchStore.seeded()`), which is where they were always
    /// meant to be — and which is what makes opening this file's preview
    /// harmless to the player's real database.
    @State private var store: MatchStore
    @State private var navigator = Navigator()
    /// The Unlock, likewise handed in. The one object that talks to StoreKit is
    /// created where the app is assembled, in plain sight.
    @State private var unlockStore: UnlockStore

    init(store: MatchStore, unlockStore: UnlockStore) {
        _store = State(initialValue: store)
        _unlockStore = State(initialValue: unlockStore)
    }

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .environment(store)
        .environment(navigator)
        .environment(unlockStore)
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
            // Dismissing is what clears the failure, through the binding above;
            // the button only has to close the alert.
            Button("OK") {}
        } message: {
            Text(
                """
                Your last change is still here, but it couldn't be written to \
                this device — it may be out of storage. Free some space and \
                keep playing: the next Round saves everything at once.
                """
            )
        }
        // The app's first word to StoreKit: the price for this player's
        // storefront, and what this device is already entitled to. Not a
        // Restore — that prompts for an Apple Account password, and it lives on
        // the offer sheet where the player asked for it.
        .task { await unlockStore.prepare() }
        // And for as long as the app is up, transactions arriving from anywhere
        // else: another device, a Family Sharing member, an approved Ask to
        // Buy, or a revocation. A purchase reaching this stream lifts the wall
        // without the player buying anything in this session.
        .task { await unlockStore.observeUpdates() }
        .themed()
    }
}

// `#Preview` bodies are compiled in every configuration, not only Debug, so a
// preview drawing the Alice/Bob fixtures has to say where those fixtures exist
// — `MatchStore.seeded()` is `#if DEBUG` precisely so it cannot ship.
#if DEBUG

#Preview {
    // In memory and against a StoreKit that says nothing: a preview draws the
    // app, it does not open the player's database, and it certainly does not
    // sweep it.
    ContentView(store: .seeded(), unlockStore: .silent())
}

#endif
