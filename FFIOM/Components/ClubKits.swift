import Foundation
import SwiftUI

// MARK: - Club Kit Data
// Maps team IDs to asset names in Assets.xcassets/Shirts/
// PDF kit images sourced from web UI: /static/img/shirts/*.svg (converted to PDF)

struct ClubKit: Hashable, Identifiable {
    let id: Int
    let teamId: Int
    let name: String
    let shortName: String
    let assetName: String  // Name of the PDF image in Assets.xcassets/Shirts/
    
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
        10: ClubKit(id: 10, teamId: 10, name: "Ayre United", shortName: "AYR", assetName: "Ayre-United"),
        11: ClubKit(id: 11, teamId: 11, name: "Braddan", shortName: "BRA", assetName: "Braddan"),
        2:  ClubKit(id: 2, teamId: 2, name: "Corinthians", shortName: "COR", assetName: "Corinthians"),
        13: ClubKit(id: 13, teamId: 13, name: "DHSOB", shortName: "DHS", assetName: "DHSOB"),
        12: ClubKit(id: 12, teamId: 12, name: "Foxdale", shortName: "FOX", assetName: "Foxdale"),
        3:  ClubKit(id: 3, teamId: 3, name: "Laxey", shortName: "LAX", assetName: "Laxey"),
        5:  ClubKit(id: 5, teamId: 5, name: "Onchan", shortName: "ONC", assetName: "Onchan"),
        1:  ClubKit(id: 1, teamId: 1, name: "Peel", shortName: "PEE", assetName: "Peel"),
        7:  ClubKit(id: 7, teamId: 7, name: "Ramsey", shortName: "RAM", assetName: "Ramsey"),
        8:  ClubKit(id: 8, teamId: 8, name: "Rushen United", shortName: "RUS", assetName: "Rushen-United"),
        4:  ClubKit(id: 4, teamId: 4, name: "St Johns", shortName: "STJ", assetName: "St-Johns"),
        6:  ClubKit(id: 6, teamId: 6, name: "St Marys", shortName: "STM", assetName: "St-Marys"),
        9:  ClubKit(id: 9, teamId: 9, name: "Union Mills", shortName: "UNI", assetName: "Union-Mills")
    ]
    
    static func forTeamId(_ teamId: Int?) -> ClubKit? {
        guard let id = teamId else { return nil }
        return all[id]
    }
    
    static func forTeamName(_ name: String) -> ClubKit? {
        let lower = name.lowercased()
        return all.values.first { 
            $0.name.lowercased().contains(lower) || lower.contains($0.name.lowercased()) 
        }
    }
    
    // Default fallback
    static let `default` = ClubKit(id: 0, teamId: 0, name: "Unknown", shortName: "UNK", assetName: "default")
}
