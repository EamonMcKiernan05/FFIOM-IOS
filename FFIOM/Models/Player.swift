import Foundation
import SwiftUI

// Player from /api/players/ list
struct Player: Codable, Identifiable, Hashable {
    let id: Int; let name: String
    let team: FootballTeam?; let position: String
    var price: Double; let priceStart: Double
    let apps: Int; let goals: Int; let assists: Int
    let totalPoints: Double; let gwPoints: Double?
    let form: Double; let selectedByPercent: Double
    let isInjured: Bool
    var isCaptain: Bool { false }
    var isViceCaptain: Bool { false }
    var isInStartingXI: Bool { false }
    
    enum CodingKeys: String, CodingKey {
        case id, name, team, position, price, apps, goals, assists, form
        case priceStart = "price_start"; case totalPoints = "total_points"
        case gwPoints = "gw_points"; case selectedByPercent = "selected_by_percent"
        case isInjured = "is_injured"
    }
    var teamName: String { team?.name ?? "Unknown" }
    var formattedPrice: String { String(format: "%.1fm", price) }
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
