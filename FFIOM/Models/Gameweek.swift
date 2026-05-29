import Foundation
import SwiftUI

struct GameweekResponse: Codable {
    let gameweek: Gameweek
    let deadlineRemainingSeconds: Int?
    let deadlineRemainingFormatted: String?
    let scoringProgress: String?
    enum CodingKeys: String, CodingKey {
        case gameweek; case deadlineRemainingSeconds = "deadline_remaining_seconds"
        case deadlineRemainingFormatted = "deadline_remaining_formatted"
        case scoringProgress = "scoring_progress"
    }
}

struct Gameweek: Codable {
    let id: Int; let number: Int; let season: String
    let startDate: String?; let deadline: String?
    let closed: Bool; let scored: Bool
    enum CodingKeys: String, CodingKey {
        case id, number, season, closed, scored
        case startDate = "start_date"; case deadline
    }
    var name: String { "GW \(number)" }
    var status: String { if scored { return "Expired" }; if closed { return "Closed" }; return "Open" }
    var isActive: Bool { !closed && !scored }
    var statusDisplay: String { status }
    var statusColor: Color { if scored { return .red }; if closed { return .orange }; return .green }
}
