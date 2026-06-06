import Foundation

// MARK: - User models

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?
    let displayName: String?
    let emailVerified: Bool?
    let createdAt: String?
    var totalPoints: Double = 0
    var budget: Double = 90.0
    var transfersRemaining: Int = 1
    var rank: Int?

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case displayName = "display_name"
        case emailVerified = "email_verified"
        case createdAt = "created_at"
        case totalPoints = "total_points"
        case budget
        case transfersRemaining = "transfers_remaining"
        case rank
    }
}

// Simplified user from /api/auth/login & /api/auth/register
struct AuthUser: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?
    let displayName: String?
    let emailVerified: Bool?
    let profilePictureUrl: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case displayName = "display_name"
        case emailVerified = "email_verified"
        case profilePictureUrl = "profile_picture_url"
        case createdAt = "created_at"
    }
}

// MARK: - Auth request bodies

struct LoginBody: Codable {
    let username: String
    let password: String
}

struct RegisterBody: Codable {
    let username: String
    let email: String
    let password: String
    let team_name: String?
}

// MARK: - Auth response

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let user: AuthUser
    let team: AuthTeam?

    struct AuthTeam: Codable { let id: Int }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case user
        case team
    }

    var token: String { accessToken }
}

// MARK: - Fantasy Team (user's team in the game)

struct FantasyTeam: Codable, Hashable {
    let id: Int
    let userId: Int
    let name: String
    let budgetRemaining: Double
    let season: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case budgetRemaining = "budget_remaining"
        case season
    }
}

// MARK: - Football Club (a real IOM football team — Peel, Lincoln, etc.)

struct FootballTeam: Codable, Hashable {
    let id: Int
    let name: String
    let shortName: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case shortName = "short_name"
    }
}
