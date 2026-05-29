import Foundation

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    @Published var authToken: String?
    @Published var currentUserId: Int?
    @Published var currentTeamId: Int?
    private let baseURL = "https://ffiom.com"
    private let keychain = KeychainService()
    
    private init() {
        self.authToken = keychain.getString(forKey: "authToken")
        if let uid = keychain.getString(forKey: "userId") { self.currentUserId = Int(uid) }
        if let tid = keychain.getString(forKey: "teamId") { self.currentTeamId = Int(tid) }
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
    
    // MARK: - Auth (uses /api/users/ prefix per production API)
    func login(username: String, password: String) async throws -> AuthResponse {
        let r = LoginRequest(username: username, password: password)
        let resp: AuthResponse = try await request(endpoint: "/api/users/login", method: "POST", body: r, responseType: AuthResponse.self)
        authToken = resp.accessToken; currentUserId = resp.user.id
        if let tid = resp.team?.id { currentTeamId = tid }
        keychain.setString(resp.accessToken, forKey: "authToken")
        keychain.setString("\(resp.user.id)", forKey: "userId")
        if let tid = resp.team?.id { keychain.setString("\(tid)", forKey: "teamId") }
        keychain.setString(resp.user.username, forKey: "username")
        return resp
    }
    func register(username: String, password: String, email: String) async throws -> AuthResponse {
        let r = RegisterRequest(username: username, password: password, email: email)
        let resp: AuthResponse = try await request(endpoint: "/api/users/register", method: "POST", body: r, responseType: AuthResponse.self)
        authToken = resp.accessToken; currentUserId = resp.user.id
        if let tid = resp.team?.id { currentTeamId = tid }
        keychain.setString(resp.accessToken, forKey: "authToken")
        keychain.setString("\(resp.user.id)", forKey: "userId")
        if let tid = resp.team?.id { keychain.setString("\(tid)", forKey: "teamId") }
        keychain.setString(resp.user.username, forKey: "username")
        return resp
    }
    func logout() {
        authToken = nil; currentUserId = nil; currentTeamId = nil
        keychain.remove("authToken"); keychain.remove("userId"); keychain.remove("teamId"); keychain.remove("username")
    }
    func refreshSession() async -> Bool {
        guard authToken != nil else { return false }
        do { _ = try await request(endpoint: "/api/users/me", responseType: User.self); return true }
        catch { logout(); return false }
    }
    
    // MARK: - Gameweeks
    func fetchGameweek() async throws -> Gameweek {
        let resp: GameweekResponse = try await request(endpoint: "/api/gameweeks/current", responseType: GameweekResponse.self)
        return resp.gameweek
    }
    func fetchGameweeks() async throws -> [Gameweek] {
        // Returns {gameweeks: [...], current_gw: {...}}
        struct GWList: Codable { let gameweeks: [Gameweek] }
        let resp: GWList = try await request(endpoint: "/api/gameweeks/", responseType: GWList.self)
        return resp.gameweeks
    }
    
    // MARK: - Leaderboard
    func fetchLeaderboard(limit: Int = 100) async throws -> [LeaderboardEntry] {
        let resp: LeaderboardResponse = try await request(endpoint: "/api/leaderboard/", responseType: LeaderboardResponse.self)
        return resp.entries
    }
    
    // MARK: - My Team / Squad
    func fetchMyTeam() async throws -> [SquadPlayer] {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        struct TeamResp: Codable { let squad: [SquadPlayer]? }
        let resp: TeamResp = try await request(endpoint: "/api/users/\(uid)/team", responseType: TeamResp.self)
        return resp.squad ?? []
    }
    func fetchSquad() async throws -> [SquadPlayer] {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        return try await request(endpoint: "/api/users/\(uid)/squad", responseType: [SquadPlayer].self)
    }
    
    // MARK: - Captain / Vice-Captain (uses squad_id not player_id)
    func setCaptain(squadId: Int) async throws {
        guard let tid = currentTeamId else { throw APIError.notAuthenticated }
        try await request(endpoint: "/api/users/\(tid)/captain/\(squadId)", method: "POST", responseType: Bool.self)
    }
    func setViceCaptain(squadId: Int) async throws {
        guard let tid = currentTeamId else { throw APIError.notAuthenticated }
        try await request(endpoint: "/api/users/\(tid)/vice-captain/\(squadId)", method: "POST", responseType: Bool.self)
    }
    
    // MARK: - Transfers (POST /api/transfers/player)
    func transferPlayer(playerInId: Int? = nil, playerOutId: Int? = nil) async throws {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        struct TransferBody: Codable {
            let user_id: Int
            let player_in_id: Int?
            let player_out_id: Int?
        }
        let body = TransferBody(user_id: uid, player_in_id: playerInId, player_out_id: playerOutId)
        try await request(endpoint: "/api/transfers/player", method: "POST", body: body, responseType: Bool.self)
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
    
    // MARK: - Chips
    func getChipStatus() async throws -> [Chip] {
        guard let tid = currentTeamId else { throw APIError.notAuthenticated }
        return try await request(endpoint: "/api/users/\(tid)/chips", responseType: [Chip].self)
    }
    func activateChip(chipType: String) async throws {
        guard let tid = currentTeamId else { throw APIError.notAuthenticated }
        try await request(endpoint: "/api/users/\(tid)/chips/activate/\(chipType)", method: "POST", responseType: Bool.self)
    }
    
    // MARK: - Stubs (endpoints not implemented yet)
    func fetchLeagues() async throws -> [League] { return [] }
    func createLeague(name: String, isPrivate: Bool = false) async throws -> League { throw APIError.invalidResponse }
    func joinLeague(code: String) async throws { throw APIError.invalidResponse }
    func fetchLeagueStandings(leagueId: Int) async throws -> [LeaderboardEntry] { return [] }
    func fetchNotifications() async throws -> [AppNotification] { return [] }
    func markAllNotificationsRead() async throws {}
    func fetchDreamTeam(gameweek: Int? = nil) async throws -> [Player] { return try await fetchTopPlayers(limit: 11) }
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
