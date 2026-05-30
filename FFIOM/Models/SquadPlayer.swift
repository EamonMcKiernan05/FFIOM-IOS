import Foundation
import SwiftUI

struct SquadPlayer: Codable, Identifiable, Hashable {
    let id: Int; let player_id: Int
    let player: PlayerInfo
    let positionSlot: Int?
    let isCaptain: Bool; let isViceCaptain: Bool; let isStarting: Bool
    let totalPoints: Double; let gwPoints: Double?
    let wasAutosub: Bool; let benchPriority: Int?
    let purchasePrice: Double
    
    enum CodingKeys: String, CodingKey {
        case id, player_id, player
        case positionSlot = "position_slot"
        case isCaptain = "is_captain"; case isViceCaptain = "is_vice_captain"
        case isStarting = "is_starting"; case totalPoints = "total_points"
        case gwPoints = "gw_points"; case wasAutosub = "was_autosub"
        case benchPriority = "bench_priority"
        case purchasePrice = "purchase_price"
    }
    
    var name: String { player.name }
    var teamName: String { player.teamName }
    var formattedPrice: String { String(format: "%.1fm", purchasePrice) }
}

struct PlayerInfo: Codable, Hashable {
    let id: Int; let name: String
    let teamId: Int?
    let price: Double
    
    enum CodingKeys: String, CodingKey {
        case id, name, price
        case teamId = "team_id"
    }
    
    var teamName: String { "Team \(teamId ?? 0)" }
}
