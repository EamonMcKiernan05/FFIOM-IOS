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

// Represents a pending transfer (player out → player in) before confirmation
struct PendingTransfer: Identifiable, Hashable {
    let id = UUID()
    var playerOutId: Int?
    var playerOut: Player?
    var playerInId: Int
    var playerIn: Player
    
    var priceChange: Double {
        guard let outPrice = playerOut?.price else { return Double(playerIn.price) }
        return playerIn.price - outPrice
    }
}
