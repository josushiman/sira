import Foundation

struct EntrantStanding: Identifiable, Equatable {
    let entrantID: Entrant.ID
    var name: String
    var total: Int
    var isOut: Bool
    var deltaFromLastRound: Int

    var id: Entrant.ID { entrantID }
}

struct Standings: Equatable {
    var ranked: [EntrantStanding]
    var isOver: Bool
    var result: String?
}
