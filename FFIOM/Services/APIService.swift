import Foundation

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    @Published var authToken: String?
    private let baseURL = "https://ffiom.com"
    private let keychain = KeychainService()
    
    private init() { self.authToken = keychain.getString(forKey: "authToken") }
    
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
            if hr.statusCode == 401 { await MainActor.run { self.logout() } }
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(hr.statusCode, msg)
        }
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw APIError.decodeError(error.localizedDescription) }
    }
    
    func login(username: String, password: String) async throws -> AuthResponse {
        let r = LoginRequest(username: username, password: password)
        let resp: AuthResponse = try await request(endpoint: "/api/auth/login", method: "POST", body: r, responseType: AuthResponse.self)
        authToken = resp.token; keychain.setString(resp.token, forKey: "authToken"); keychain.setString(resp.user.username, forKey: "username")
        return resp
    }
    func register(username: String, password: String, email: String? = nil) async throws -> AuthResponse {
        let r = RegisterRequest(username: username, password: password, email: email)
        let resp: AuthResponse = try await request(endpoint: "/api/auth/register", method: "POST", body: r, responseType: AuthResponse.self)
        authToken = resp.token; keychain.setString(resp.token, forKey: "authToken"); keychain.setString(resp.user.username, forKey: "username")
        return resp
    }
    func logout() { authToken = nil; keychain.remove("authToken"); keychain.remove("username") }
    func refreshSession() async -> Bool {
        guard authToken != nil else { return false }
        do { _ = try await request(endpoint: "/api/auth/me", responseType: User.self); return true }
        catch { logout(); return false }
    }
    func fetchGameweek() async throws -> Gameweek { try await request(endpoint: "/api/gameweek/current", responseType: Gameweek.self) }
    func fetchLeaderboard(limit: Int = 100) async throws -> [LeaderboardEntry] {
        try await request(endpoint: "/api/leaderboard?limit=\(limit)", responseType: [LeaderboardEntry].self)
    }
    func fetchMyTeam() async throws -> [Player] { try await request(endpoint: "/api/team", responseType: [Player].self) }
    func setCaptain(playerId: Int) async throws { try await request(endpoint: "/api/team/captain", method: "POST", body: ["player_id": playerId], responseType: Bool.self) }
    func setViceCaptain(playerId: Int) async throws { try await request(endpoint: "/api/team/vice-captain", method: "POST", body: ["player_id": playerId], responseType: Bool.self) }
    func setStartingXI(playerIds: [Int]) async throws { try await request(endpoint: "/api/team/starting-xi", method: "POST", body: ["player_ids": playerIds], responseType: Bool.self) }
    func addPlayer(playerId: Int) async throws { try await request(endpoint: "/api/transfers/add", method: "POST", body: ["player_id": playerId], responseType: Bool.self) }
    func removePlayer(playerId: Int) async throws { try await request(endpoint: "/api/transfers/remove", method: "POST", body: ["player_id": playerId], responseType: Bool.self) }
    func fetchTransferHistory() async throws -> [Transfer] { try await request(endpoint: "/api/transfers/history", responseType: [Transfer].self) }
    func useChip(chipId: String) async throws { try await request(endpoint: "/api/chips/use", method: "POST", body: ["chip_id": chipId], responseType: Bool.self) }
    func fetchPlayers(sortBy: String = "points", position: String? = nil, search: String? = nil) async throws -> [Player] {
        var ep = "/api/players?sort_by=\(sortBy)"
        if let p = position { ep += "&position=\(p)" }
        if let s = search { ep += "&search=\(s)" }
        return try await request(endpoint: ep, responseType: [Player].self)
    }
    func fetchFixtures(gameweek: Int? = nil) async throws -> [Fixture] {
        var ep = "/api/fixtures"
        if let g = gameweek { ep += "?gameweek=\(g)" }
        return try await request(endpoint: ep, responseType: [Fixture].self)
    }
    func fetchLeagues() async throws -> [League] { try await request(endpoint: "/api/leagues", responseType: [League].self) }
    func createLeague(name: String, isPrivate: Bool = false) async throws -> League {
        let r = LeagueRequest(name: name, isPrivate: isPrivate)
        return try await request(endpoint: "/api/leagues/create", method: "POST", body: r, responseType: League.self)
    }
    func joinLeague(code: String) async throws { try await request(endpoint: "/api/leagues/join", method: "POST", body: ["code": code], responseType: Bool.self) }
    func fetchLeagueStandings(leagueId: Int) async throws -> [LeaderboardEntry] {
        try await request(endpoint: "/api/leagues/\(leagueId)/standings", responseType: [LeaderboardEntry].self)
    }
    func fetchDreamTeam(gameweek: Int? = nil) async throws -> [Player] {
        var ep = "/api/dream-team"; if let g = gameweek { ep += "?gameweek=\(g)" }
        return try await request(endpoint: ep, responseType: [Player].self)
    }
    func fetchRankings(sortBy: String = "points", position: String? = nil) async throws -> [Player] {
        var ep = "/api/rankings?sort_by=\(sortBy)"
        if let p = position { ep += "&position=\(p)" }
        return try await request(endpoint: ep, responseType: [Player].self)
    }
    func fetchNotifications() async throws -> [AppNotification] { try await request(endpoint: "/api/notifications", responseType: [AppNotification].self) }
    func markAllNotificationsRead() async throws { try await request(endpoint: "/api/notifications/read-all", method: "POST", responseType: Bool.self) }
    func fetchMyStats() async throws -> User { try await request(endpoint: "/api/user/stats", responseType: User.self) }
}

enum APIError: LocalizedError {
    case invalidURL; case invalidResponse; case httpError(Int, String); case decodeError(String)
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .httpError(let c, let m): return "Server error (\(c)): \(m)"
        case .decodeError(let m): return "Parse error: \(m)"
        }
    }
}
