import Foundation
import SwiftUI

// MARK: - Club Kit Colors for Isle of Man Premier League (Canada Life Premier League)
// Source: Wikipedia club pages

struct ClubKit: Hashable {
    let teamId: Int
    let name: String
    let shortName: String
    let primaryColor: Color
    let secondaryColor: Color
    let pattern: KitPattern
    
    enum KitPattern: String, Codable {
        case solid
        case stripes
        case halves
        case sash
    }
}

// MARK: - Kit Data

extension ClubKit {
    static let all: [Int: ClubKit] = [
        10: ClubKit(teamId: 10, name: "Ayre United", shortName: "AYR",
                    primaryColor: .orange, secondaryColor: .black, pattern: .solid),
        11: ClubKit(teamId: 11, name: "Braddan", shortName: "BRA",
                    primaryColor: Color(red: 0, green: 0.2, blue: 0.63), secondaryColor: .white, pattern: .solid),
        2:  ClubKit(teamId: 2, name: "Corinthians", shortName: "COR",
                    primaryColor: .white, secondaryColor: .black, pattern: .solid),
        13: ClubKit(teamId: 13, name: "DHSOB", shortName: "DHS",
                    primaryColor: Color(red: 0.11, green: 0.08, blue: 0.39), secondaryColor: Color(red: 1, green: 0.84, blue: 0), pattern: .halves),
        12: ClubKit(teamId: 12, name: "Foxdale", shortName: "FOX",
                    primaryColor: Color(red: 0, green: 0.2, blue: 0.63), secondaryColor: .white, pattern: .stripes),
        3:  ClubKit(teamId: 3, name: "Laxey", shortName: "LAX",
                    primaryColor: Color(red: 0, green: 0.5, blue: 0), secondaryColor: .white, pattern: .stripes),
        5:  ClubKit(teamId: 5, name: "Onchan", shortName: "ONC",
                    primaryColor: Color(red: 1, green: 0.84, blue: 0), secondaryColor: Color(red: 0, green: 0.2, blue: 0.63), pattern: .solid),
        1:  ClubKit(teamId: 1, name: "Peel", shortName: "PEE",
                    primaryColor: .white, secondaryColor: Color(red: 0.8, green: 0, blue: 0), pattern: .stripes),
        7:  ClubKit(teamId: 7, name: "Ramsey", shortName: "RAM",
                    primaryColor: Color(red: 0, green: 0.2, blue: 0.63), secondaryColor: .white, pattern: .stripes),
        8:  ClubKit(teamId: 8, name: "Rushen United", shortName: "RUS",
                    primaryColor: Color(red: 1, green: 0.84, blue: 0), secondaryColor: .black, pattern: .stripes),
        4:  ClubKit(teamId: 4, name: "St Johns", shortName: "STJ",
                    primaryColor: Color(red: 0, green: 0.2, blue: 0.63), secondaryColor: Color(red: 1, green: 0.84, blue: 0), pattern: .stripes),
        6:  ClubKit(teamId: 6, name: "St Marys", shortName: "STM",
                    primaryColor: Color(red: 1, green: 0.84, blue: 0), secondaryColor: Color(red: 0, green: 0.5, blue: 0), pattern: .solid),
        9:  ClubKit(teamId: 9, name: "Union Mills", shortName: "UNI",
                    primaryColor: Color(red: 0.48, green: 0.18, blue: 0.56), secondaryColor: .white, pattern: .solid)
    ]
    
    static func forTeamId(_ teamId: Int?) -> ClubKit? {
        guard let id = teamId else { return nil }
        return all[id]
    }
    
    static func forTeamName(_ name: String) -> ClubKit? {
        let lower = name.lowercased()
        return all.values.first { $0.name.lowercased().contains(lower) || lower.contains($0.name.lowercased()) }
    }
    
    // Default fallback kit
    static let `default` = ClubKit(teamId: 0, name: "Unknown", shortName: "UNK",
                                   primaryColor: Color(red: 0.22, green: 0, blue: 0.24), secondaryColor: Color(red: 0, green: 1, blue: 0.53), pattern: .solid)
}
