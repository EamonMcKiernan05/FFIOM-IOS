import Foundation
import SwiftUI

struct Fixture: Codable, Identifiable, Hashable {
    let id: Int
    let gameweekId: Int
    let homeTeam: String
    let awayTeam: String
    let homeScore: Int?
    let awayScore: Int?
    let played: Bool
    let date: String?

    enum CodingKeys: String, CodingKey {
        case id
        case gameweekId = "gameweek_id"
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case homeScore = "home_score"
        case awayScore = "away_score"
        case played, date
    }

    var isFinished: Bool { played }
    var scoreString: String {
        if let h = homeScore, let a = awayScore { return "\(h) - \(a)" }
        return "vs"
    }
    var dateFormatted: String {
        guard let d = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-ddTHH:mm:ss"
        if let date = formatter.date(from: d) {
            let display = DateFormatter()
            display.dateFormat = "EEE d MMM"
            return display.string(from: date)
        }
        return d
    }
    var timeString: String {
        guard let d = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-ddTHH:mm:ss"
        if let date = formatter.date(from: d) {
            let display = DateFormatter()
            display.dateFormat = "HH:mm"
            return display.string(from: date)
        }
        return ""
    }
}

struct FixturesResponse: Codable {
    let fixtures: [Fixture]
}

// MARK: - Fixture extensions for transfer overlay
extension Fixture {
    func opponent(forTeam teamName: String) -> String {
        if homeTeam == teamName { return awayTeam }
        if awayTeam == teamName { return homeTeam }
        return homeTeam
    }
    
    func isHome(forTeam teamName: String) -> Bool {
        homeTeam == teamName
    }
}

// MARK: - Surname helper
extension String {
    var surname: String {
        let parts = split(separator: " ")
        return parts.last?.description.capitalized ?? self
    }
}
