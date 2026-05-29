import Foundation

struct LeaderboardEntry: Codable, Identifiable, Hashable {
    let id: Int; let username: String; let totalPoints: Double; let rank: Int
    enum CodingKeys: String, CodingKey {
        case id, username, rank; case totalPoints = "total_points"
    }
}
