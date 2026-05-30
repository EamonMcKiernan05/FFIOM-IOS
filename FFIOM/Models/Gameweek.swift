import Foundation
import SwiftUI

struct GameweekResponse: Codable {
    let gameweek: Gameweek
    let deadlineRemainingSeconds: Int?
    let deadlineRemainingFormatted: String?
    let scoringProgress: String?
    enum CodingKeys: String, CodingKey {
        case gameweek
        case deadlineRemainingSeconds = "deadline_remaining_seconds"
        case deadlineRemainingFormatted = "deadline_remaining_formatted"
        case scoringProgress = "scoring_progress"
    }
}

struct GameweeksList: Codable {
    let season: String
    let gameweeks: [Gameweek]
    let currentGw: Gameweek?
    enum CodingKeys: String, CodingKey {
        case season, gameweeks
        case currentGw = "current_gw"
    }
}

struct Gameweek: Codable, Identifiable {
    let id: Int
    let number: Int?
    let season: String?
    let startDate: String?
    let deadline: String?
    let closed: Bool?
    let scored: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case number, season, closed, scored
        case startDate = "start_date"
        case deadline
    }

    var displayNumber: Int { number ?? id }
    var name: String { "GW \(displayNumber)" }
    var status: String {
        if scored == true { return "Finished" }
        if closed == true { return "Closed" }
        return "Open"
    }
    var isActive: Bool { closed != true && scored != true }
    var statusDisplay: String { status }
    var statusColor: Color {
        if scored == true { return .gray }
        if closed == true { return .orange }
        return .green
    }
    var isPlayed: Bool { scored == true }
}
