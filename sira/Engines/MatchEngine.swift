import Foundation

protocol MatchEngine {
    func standings(for match: Match) -> Standings
}
