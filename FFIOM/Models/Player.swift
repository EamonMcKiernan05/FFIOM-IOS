import Foundation
import SwiftUI

// Player from /api/players/ list
struct Player: Codable, Identifiable, Hashable {
    let id: Int; let name: String
    let team: FootballTeam?
    var price: Double; let priceStart: Double
    let apps: Int; let goals: Int; let assists: Int
    let cleanSheets: Int
    let totalPoints: Double; let gwPoints: Double?
    let form: Double; let selectedByPercent: Double
    let isInjured: Bool; let injuryStatus: String?
    var isCaptain: Bool { false }
    var isViceCaptain: Bool { false }
    var isInStartingXI: Bool { false }
    
    enum CodingKeys: String, CodingKey {
        case id, name, team, price, apps, goals, assists, form
        case priceStart = "price_start"; case totalPoints = "total_points"
        case cleanSheets = "clean_sheets"; case gwPoints = "gw_points"
        case selectedByPercent = "selected_by_percent"
        case isInjured = "is_injured"; case injuryStatus = "injury_status"
    }
    var teamName: String { team?.name ?? "Unknown" }
    var formattedPrice: String { String(format: "%.1fm", price) }
}
