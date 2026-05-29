import Foundation

struct AppNotification: Codable, Identifiable, Hashable {
    let id: Int; let message: String; let timestamp: String
    let isRead: Bool; let type: String
    enum CodingKeys: String, CodingKey {
        case id, message, timestamp, type; case isRead = "is_read"
    }
}
