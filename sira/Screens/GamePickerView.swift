import SwiftUI

struct GamePickerView: View {
    var body: some View {
        List(Game.allCases, id: \.self) { game in
            NavigationLink(gameTitle(game)) {
                VariantPickerView(game: game)
            }
        }
        .navigationTitle("New Match")
    }

    private func gameTitle(_ game: Game) -> String {
        switch game {
        case .gonga: return "Gonga"
        case .okey: return "Okey"
        }
    }
}

#Preview {
    NavigationStack {
        GamePickerView()
    }
}
