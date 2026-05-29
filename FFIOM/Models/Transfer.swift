import Foundation

struct Transfer: Codable, Identifiable, Hashable {
    let id: Int; let pointsHit: Int?; let gameweek: Int; let timestamp: String
    enum CodingKeys: String, CodingKey {
        case id; case pointsHit = "points_hit"; case gameweek; case timestamp
    }
}

struct Chip: Codable, Identifiable, Hashable {
    var id: String { type }; let name: String; let description: String
    let used: Bool; let type: String; let active: Bool; let available: Bool
}
