import Foundation

struct Fixture: Codable, Identifiable, Hashable {
    let id: Int
    let homeTeam: String
    let awayTeam: String
    let homeScore: Int?
    let awayScore: Int?
    let gameweek: Int
    let date: String?
    let isFinished: Bool
    
    enum CodingKeys: String, CodingKey {
        case id; case homeTeam = "home_team"; case awayTeam = "away_team"
        case homeScore = "home_score"; case awayScore = "away_score"
        case gameweek; case date; case isFinished = "is_finished"
    }
    var scoreString: String {
        if let h = homeScore, let a = awayScore { return "\(h) - \(a)" }
        return "vs"
    }
}
