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
    @State private var store: MatchStore
    @State private var navigator = Navigator()
    /// The Unlock, over the real App Store. Built from the same store, because
    /// the local flag it caches lives beside the meter — see `UnlockCache`.
    ///
    /// Built here rather than in `MatchStore.forApp()` so that the one object
    /// that talks to StoreKit is created where the app is assembled, in plain
    /// sight, rather than folded into the store that talks to the disk.
    @State private var unlock: UnlockStore

    init() {
        let store = MatchStore.forApp()
        _store = State(initialValue: store)
        _unlock = State(initialValue: UnlockStore(
            operations: .storeKit,
            cache: .stored(in: store)
        ))
    }

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .environment(store)
        .environment(navigator)
        .environment(unlock)
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
        .task { await unlock.prepare() }
        // And for as long as the app is up, transactions arriving from anywhere
        // else: another device, a Family Sharing member, an approved Ask to
        // Buy, or a revocation. A purchase reaching this stream lifts the wall
        // without the player buying anything in this session.
        .task { await unlock.observeUpdates() }
        .themed()
    }
}

#Preview {
    ContentView()
}
