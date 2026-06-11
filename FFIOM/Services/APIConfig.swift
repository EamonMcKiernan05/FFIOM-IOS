import Foundation

/// Centralized API configuration — externalized from APIService for staging/production switching.
/// Reads from Info.plist key `API_BASE_URL` with a fallback default.
enum APIConfig {
    /// Base URL for the FFIOM API backend.
    /// Configurable via Info.plist key `API_BASE_URL`.
    static var baseURL: String {
        Bundle.main.infoDictionary?["API_BASE_URL"] as? String
            ?? "https://ffiom.com"
    }

    /// Request timeout in seconds.
    static let requestTimeout: TimeInterval = 30

    /// Default cache duration for non-authenticated requests (in seconds).
    static let defaultCacheDuration: TimeInterval = 300
}
