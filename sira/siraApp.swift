//
//  siraApp.swift
//  sira
//
//  Created by Timur Mustafa on 18/08/2026.
//

import SwiftUI

@main
struct siraApp: App {
    /// The app's own store, over the database on the device — built here, once,
    /// where the app is assembled, rather than in the initialiser of whichever
    /// view happens to be the root. A view's `init` carries no promise about
    /// how many times it runs, and the launch work below must happen exactly
    /// once.
    @State private var store: MatchStore
    /// The Unlock, over the real App Store. Built from the same store, because
    /// the local flag it caches lives beside the meter — see `UnlockCache`.
    @State private var unlockStore: UnlockStore

    init() {
        let store = MatchStore.forApp()
        // The app's deliberate first act, named at the call site rather than
        // hidden inside `forApp()`: a Match set up and never scored is
        // unreachable now that Home lists Started Matches only, and a launch is
        // the moment it can be tidied away without taking a live Match with it.
        store.discardUnstartedMatches()
        _store = State(initialValue: store)
        _unlockStore = State(initialValue: UnlockStore(
            operations: .storeKit,
            cache: .stored(in: store)
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store, unlockStore: unlockStore)
        }
    }
}
