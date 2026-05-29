import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?
    var totalPoints: Double
    var budget: Double
    var transfersRemaining: Int
    var rank: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, username, email
        case totalPoints = "total_points"
        case budget
        case transfersRemaining = "transfers_remaining"
        case rank
    }
}

struct LoginRequest: Codable { let username: String; let password: String }
struct RegisterRequest: Codable { let username: String; let password: String; let email: String? }
struct AuthResponse: Codable { let token: String; let user: User }
