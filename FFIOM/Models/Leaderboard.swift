import Foundation

struct LeaderboardResponse: Codable {
    let season: String; let totalTeams: Int
    let entries: [LeaderboardEntry]
    enum CodingKeys: String, CodingKey {
        case season; case totalTeams = "total_teams"; case entries
    }
}

struct LeaderboardEntry: Codable, Identifiable, Hashable {
    let rank: Int; let userId: Int; let username: String
    let teamName: String?; let totalPoints: Double
    let gameweekPoints: Double?; let overallRank: Int?
    var id: Int { rank }
    enum CodingKeys: String, CodingKey {
        case rank; case userId = "user_id"; case username
        case teamName = "team_name"; case totalPoints = "total_points"
        case gameweekPoints = "gameweek_points"; case overallRank = "overall_rank"
    }
}
