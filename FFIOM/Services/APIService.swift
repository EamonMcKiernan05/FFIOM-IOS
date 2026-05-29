import Foundation

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    @Published var authToken: String?
    @Published var currentUserId: Int?
    private let baseURL = "https://ffiom.com"
    private let keychain = KeychainService()
    
    private init() {
        self.authToken = keychain.getString(forKey: "authToken")
        if let uid = keychain.getString(forKey: "userId") {
            self.currentUserId = Int(uid)
        }
    }
    
    private func headers() -> [String: String] {
        var h: [String: String] = ["Content-Type": "application/json", "Accept": "application/json"]
        if let t = authToken { h["Authorization"] = "Bearer \(t)" }
        return h
    }
    
    func request<T: Codable>(endpoint: String, method: String = "GET",
                             body: Encodable? = nil, responseType: T.Type) async throws -> T {
        guard let uc = URLComponents(string: "\(baseURL)\(endpoint)") else { throw APIError.invalidURL }
        var req = URLRequest(url: uc.url!); req.httpMethod = method; req.allHTTPHeaderFields = headers()
        if let body = body { req.httpBody = try? JSONEncoder().encode(body) }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let hr = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(hr.statusCode) else {
            if hr.statusCode == 401 { await logout() }
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(hr.statusCode, msg)
        }
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw APIError.decodeError(error.localizedDescription) }
    }
    
    func login(username: String, password: String) async throws -> AuthResponse {
        let r = LoginRequest(username: username, password: password)
        let resp: AuthResponse = try await request(endpoint: "/api/users/login", method: "POST", body: r, responseType: AuthResponse.self)
        authToken = resp.token; currentUserId = resp.user.id
        keychain.setString(resp.token, forKey: "authToken")
        keychain.setString("\(resp.user.id)", forKey: "userId")
        keychain.setString(resp.user.username, forKey: "username")
        return resp
    }
    func register(username: String, password: String, email: String? = nil) async throws -> AuthResponse {
        let r = RegisterRequest(username: username, password: password, email: email)
        let resp: AuthResponse = try await request(endpoint: "/api/users/register", method: "POST", body: r, responseType: AuthResponse.self)
        authToken = resp.token; currentUserId = resp.user.id
        keychain.setString(resp.token, forKey: "authToken")
        keychain.setString("\(resp.user.id)", forKey: "userId")
        keychain.setString(resp.user.username, forKey: "username")
        return resp
    }
    func logout() {
        authToken = nil; currentUserId = nil
        keychain.remove("authToken"); keychain.remove("userId"); keychain.remove("username")
    }
    func refreshSession() async -> Bool {
        guard authToken != nil else { return false }
        do { _ = try await request(endpoint: "/api/users/me", responseType: User.self); return true }
        catch { logout(); return false }
    }
    
    // MARK: - Gameweeks
    func fetchGameweek() async throws -> Gameweek {
        try await request(endpoint: "/api/gameweeks/current", responseType: Gameweek.self)
    }
    func fetchGameweeks() async throws -> [Gameweek] {
        try await request(endpoint: "/api/gameweeks/", responseType: [Gameweek].self)
    }
    
    // MARK: - Leaderboard
    func fetchLeaderboard(limit: Int = 100) async throws -> [LeaderboardEntry] {
        try await request(endpoint: "/api/leaderboard?limit=\(limit)", responseType: [LeaderboardEntry].self)
    }
    
    // MARK: - My Team
    func fetchMyTeam() async throws -> [Player] {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        return try await request(endpoint: "/api/users/\(uid)/squad", responseType: [Player].self)
    }
    func setCaptain(playerId: Int) async throws {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        try await request(endpoint: "/api/users/\(uid)/team/captain", method: "PUT", body: ["player_id": playerId], responseType: Bool.self)
    }
    func setViceCaptain(playerId: Int) async throws {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        try await request(endpoint: "/api/users/\(uid)/team/vice-captain", method: "PUT", body: ["player_id": playerId], responseType: Bool.self)
    }
    func setStartingXI(playerIds: [Int]) async throws {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        try await request(endpoint: "/api/users/\(uid)/team/formation", method: "PUT", body: ["player_ids": playerIds], responseType: Bool.self)
    }
    
    // MARK: - Players
    func fetchPlayers(sortBy: String = "goals", position: String? = nil, search: String? = nil) async throws -> [Player] {
        var ep = "/api/players/?order_by=\(sortBy)"
        if let p = position { ep += "&position=\(p)" }
        if let s = search { ep += "&search=\(s)" }
        return try await request(endpoint: ep, responseType: [Player].self)
    }
    func fetchRankings(sortBy: String = "points", position: String? = nil) async throws -> [Player] {
        var ep = "/api/players/rankings?sort_by=\(sortBy)"
        if let p = position { ep += "&position=\(p)" }
        return try await request(endpoint: ep, responseType: [Player].self)
    }
    func fetchTopPlayers(gameweek: Int? = nil, limit: Int = 20) async throws -> [Player] {
        var ep = "/api/players/top?limit=\(limit)"
        if let gw = gameweek { ep += "&gameweek_id=\(gw)" }
        return try await request(endpoint: ep, responseType: [Player].self)
    }
    
    // MARK: - Fixtures
    func fetchFixtures() async throws -> [Fixture] {
        try await request(endpoint: "/api/fixtures/", responseType: [Fixture].self)
    }
    
    // MARK: - User
    func fetchCurrentUser() async throws -> User {
        try await request(endpoint: "/api/users/me", responseType: User.self)
    }
    func fetchMyStats() async throws -> User {
        try await request(endpoint: "/api/users/me", responseType: User.self)
    }
    
    // MARK: - Transfers
    func fetchTransferHistory() async throws -> [Transfer] {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        return try await request(endpoint: "/api/users/\(uid)/team/history", responseType: [Transfer].self)
    }
    
    // MARK: - Chips
    func getChipStatus() async throws -> Chip {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        return try await request(endpoint: "/api/users/\(uid)/team/chip", responseType: Chip.self)
    }
    func setChip(chipType: String) async throws {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        try await request(endpoint: "/api/users/\(uid)/team/chip", method: "POST", body: ["chip_type": chipType], responseType: Bool.self)
    }
    
    // MARK: - Stubs for missing API endpoints
    func fetchLeagues() async throws -> [League] { return [] }
    func createLeague(name: String, isPrivate: Bool = false) async throws -> League { throw APIError.invalidResponse }
    func joinLeague(code: String) async throws { throw APIError.invalidResponse }
    func fetchLeagueStandings(leagueId: Int) async throws -> [LeaderboardEntry] { return [] }
    func fetchNotifications() async throws -> [AppNotification] { return [] }
    func markAllNotificationsRead() async throws {}
    func fetchDreamTeam(gameweek: Int? = nil) async throws -> [Player] { return try await fetchTopPlayers(limit: 11) }
    func addPlayer(playerId: Int) async throws { throw APIError.invalidResponse }
    func removePlayer(playerId: Int) async throws { throw APIError.invalidResponse }
}

enum APIError: LocalizedError {
    case invalidURL; case invalidResponse; case httpError(Int, String); case decodeError(String); case notAuthenticated
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .httpError(let c, let m): return "Server error (\(c)): \(m)"
        case .decodeError(let m): return "Parse error: \(m)"
        case .notAuthenticated: return "Not authenticated"
        }
    }
}
