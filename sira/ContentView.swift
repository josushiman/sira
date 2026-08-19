//
//  ContentView.swift
//  sira
//
//  Created by Timur Mustafa on 18/08/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var store = MatchStore.seeded()
    @State private var navigator = Navigator()

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .environment(store)
        .environment(navigator)
        .themed()
    }
}

#Preview {
    ContentView()
}
