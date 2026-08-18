import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Sıra").font(.largeTitle.bold())
            NavigationLink("Start Gonga Match") {
                SetupView()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Your Matches")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
