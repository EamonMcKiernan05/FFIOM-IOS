import Foundation
import SwiftUI

struct SquadPlayer: Codable, Identifiable, Hashable {
    let id: Int; let player_id: Int
    let player: PlayerInfo
    let position: String; let positionSlot: Int
    let isCaptain: Bool; let isViceCaptain: Bool; let isStarting: Bool
    let totalPoints: Double; let gwPoints: Double?
    let wasAutosub: Bool; let benchPriority: Int
    let purchasePrice: Double; let sellingPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case id, player_id, player, position
        case positionSlot = "position_slot"
        case isCaptain = "is_captain"; case isViceCaptain = "is_vice_captain"
        case isStarting = "is_starting"; case totalPoints = "total_points"
        case gwPoints = "gw_points"; case wasAutosub = "was_autosub"
        case benchPriority = "bench_priority"
        case purchasePrice = "purchase_price"; case sellingPrice = "selling_price"
    }
    
    var name: String { player.name }
    var teamName: String { player.team?.name ?? "Unknown" }
    var formattedPrice: String { String(format: "%.1fm", sellingPrice) }
    var positionBadge: String {
        let p = position.uppercased()
        if p.hasPrefix("GK") { return "GK" }
        if p.hasPrefix("DEF") { return "DEF" }
        if p.hasPrefix("MID") { return "MID" }
        return "FWD"
    }
    var positionColor: Color {
        let p = position.uppercased()
        if p.hasPrefix("GK") { return .blue }
        if p.hasPrefix("DEF") { return .green }
        if p.hasPrefix("MID") { return .purple }
        return .red
    }
}

struct PlayerInfo: Codable, Hashable {
    let id: Int; let name: String; let position: String
    let price: Double; let team: FootballTeam?
    let isInjured: Bool; let form: Double
    let selectedByPercent: Double; let totalPointsSeason: Double
    
    enum CodingKeys: String, CodingKey {
        case id, name, position, price, team, form
        case isInjured = "is_injured"; case selectedByPercent = "selected_by_percent"
        case totalPointsSeason = "total_points_season"
    }
}
