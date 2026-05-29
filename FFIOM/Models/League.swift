import Foundation

struct League: Codable, Identifiable, Hashable {
    let id: Int; let name: String; let code: String; let isPrivate: Bool
    var members: [LeaderboardEntry]?
    enum CodingKeys: String, CodingKey {
        case id, name, code, members; case isPrivate = "is_private"
    }
}
struct LeagueRequest: Codable { let name: String; let isPrivate: Bool }
