import Foundation

struct User: Codable, Identifiable {
    let id: Int; let username: String; let email: String?
    var totalPoints: Double = 0; var budget: Double = 90.0
    var transfersRemaining: Int = 1; var rank: Int?
    enum CodingKeys: String, CodingKey {
        case id, username, email; case totalPoints = "total_points"
        case budget; case transfersRemaining = "transfers_remaining"; case rank
    }
}

struct LoginRequest: Codable { let username: String; let password: String }
struct RegisterRequest: Codable { let username: String; let password: String; let email: String }

struct TeamInfo: Codable, Hashable {
    let id: Int; let userId: Int; let name: String
    let budgetRemaining: Double; let season: String?
    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"; case name
        case budgetRemaining = "budget_remaining"; case season
    }
}

struct AuthResponse: Codable {
    let accessToken: String; let tokenType: String
    let user: User; let team: TeamInfo?
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"; case tokenType = "token_type"
        case user; case team
    }
    var token: String { accessToken }
}
