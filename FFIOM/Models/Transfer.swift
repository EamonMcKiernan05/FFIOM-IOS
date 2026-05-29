import Foundation

struct Transfer: Codable, Identifiable, Hashable {
    let id: Int; let playerIn: Player?; let playerOut: Player?
    let pointsHit: Int?; let gameweek: Int; let timestamp: String
    enum CodingKeys: String, CodingKey {
        case id, pointsHit, gameweek, timestamp
        case playerIn = "player_in"; case playerOut = "player_out"
    }
}

struct Chip: Codable, Identifiable {
    let id: String; let name: String; let description: String
    let used: Bool; let usageType: String
}
