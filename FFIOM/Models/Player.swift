import Foundation
import SwiftUI

struct Player: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let team: String
    let teamShort: String?
    let position: String
    var price: Double
    var totalPoints: Double
    var form: Double
    var goals: Int
    var assists: Int
    var selectedByPercent: Double
    var isCaptain: Bool
    var isViceCaptain: Bool
    var isInStartingXI: Bool
    var gameweekPoints: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, name, team, position, price
        case teamShort = "team_short"
        case totalPoints = "total_points"
        case form, goals, assists
        case selectedByPercent = "selected_by_percent"
        case isCaptain = "is_captain"
        case isViceCaptain = "is_vice_captain"
        case isInStartingXI = "is_in_starting_xi"
        case gameweekPoints = "gameweek_points"
    }
    
    var formattedPrice: String { String(format: "%.1fm", price) }
    
    var positionBadge: String {
        switch position.prefix(2).uppercased() {
        case "GK": return "GK"; case "DE": return "DE"
        case "MF": return "MF"; case "FW": return "FW"
        default: return position.prefix(2).uppercased()
        }
    }
    
    var positionColor: Color {
        switch position.lowercased() {
        case "goalkeeper", "gk": return .blue
        case "defender", "de": return .green
        case "midfielder", "mf": return .purple
        case "forward", "fw": return .red
        default: return .gray
        }
    }
}
