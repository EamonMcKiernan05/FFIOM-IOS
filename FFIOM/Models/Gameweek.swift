import Foundation
import SwiftUI

struct Gameweek: Codable {
    let id: Int
    let name: String
    let status: String
    let deadline: String?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, status, deadline
        case isActive = "is_active"
    }
    
    var statusDisplay: String {
        switch status.lowercased() {
        case "expired": return "Expired"; case "live": return "Live"
        case "open": return "Open"; case "upcoming": return "Upcoming"
        default: return status
        }
    }
    var statusColor: Color {
        switch status.lowercased() {
        case "expired": return .red; case "live": return .green
        case "open": return .orange; default: return .gray
        }
    }
}
