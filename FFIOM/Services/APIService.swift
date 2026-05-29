import Foundation

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    @Published var authToken: String?
    @Published var refreshToken: String?
    @Published var currentUserId: Int?
    @Published var currentTeamId: Int?
    private let baseURL = "https://ffiom.com"
    private let ud = UserDefaults.standard
    
    private init() {
        self.authToken = ud.string(forKey: "authToken")
        self.refreshToken = ud.string(forKey: "refreshToken")
        if let uid = ud.string(forKey: "userId") { self.currentUserId = Int(uid) }
        if let tid = ud.string(forKey: "teamId") { self.currentTeamId = Int(tid) }
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
    
    // MARK: - Auth
    
    func login(username: String, password: String) async throws -> AuthResponse {
        let body = LoginBody(username: username, password: password)
        let resp: AuthResponse = try await request(endpoint: "/api/auth/login", method: "POST", body: body, responseType: AuthResponse.self)
        
        authToken = resp.accessToken
        refreshToken = resp.refreshToken
        currentUserId = resp.user.id
        
        ud.set(resp.accessToken, forKey: "authToken")
        ud.set(resp.refreshToken, forKey: "refreshToken")
        ud.set("\(resp.user.id)", forKey: "userId")
        ud.set(resp.user.username, forKey: "username")
        ud.synchronize()
        
        do {
            struct MeResp: Codable {
                let id: Int; let username: String; let email: String?; let teamId: Int?
                enum CodingKeys: String, CodingKey {
                    case id, username, email; case teamId = "team_id"
                }
            }
            let me: MeResp = try await request(endpoint: "/api/users/me", responseType: MeResp.self)
            if let tid = me.teamId {
                currentTeamId = tid
                ud.set("\(tid)", forKey: "teamId")
            }
        } catch { /* Non-fatal */ }
        
        return resp
    }
    
    func register(username: String, password: String, email: String) async throws -> AuthResponse {
        let body = RegisterBody(username: username, email: email, password: password, team_name: nil)
        let resp: AuthResponse = try await request(endpoint: "/api/auth/register", method: "POST", body: body, responseType: AuthResponse.self)
        
        authToken = resp.accessToken
        refreshToken = resp.refreshToken
        currentUserId = resp.user.id
        
        ud.set(resp.accessToken, forKey: "authToken")
        ud.set(resp.refreshToken, forKey: "refreshToken")
        ud.set("\(resp.user.id)", forKey: "userId")
        ud.set(resp.user.username, forKey: "username")
        ud.synchronize()
        
        do {
            struct MeResp: Codable {
                let id: Int; let username: String; let email: String?; let teamId: Int?
                enum CodingKeys: String, CodingKey {
                    case id, username, email; case teamId = "team_id"
                }
            }
            let me: MeResp = try await request(endpoint: "/api/users/me", responseType: MeResp.self)
            if let tid = me.teamId {
                currentTeamId = tid
                ud.set("\(tid)", forKey: "teamId")
            }
        } catch { /* Non-fatal */ }
        
        return resp
    }
    
    func logout() {
        authToken = nil; refreshToken = nil; currentUserId = nil; currentTeamId = nil
        ud.removeObject(forKey: "authToken"); ud.removeObject(forKey: "refreshToken")
        ud.removeObject(forKey: "userId"); ud.removeObject(forKey: "teamId"); ud.removeObject(forKey: "username")
        ud.synchronize()
    }
    
    func refreshSession() async -> Bool {
        guard authToken != nil else { return false }
        do { _ = try await request(endpoint: "/api/users/me", responseType: User.self); return true }
        catch { logout(); return false }
    }
    
    // MARK: - Gameweeks
    func fetchGameweek() async throws -> Gameweek {
        struct GWResp: Codable { let gameweek: Gameweek }
        let resp: GWResp = try await request(endpoint: "/api/gameweeks/current", responseType: GWResp.self)
        return resp.gameweek
    }
    func fetchGameweeks() async throws -> [Gameweek] {
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
    
    // MARK: - Captain / Vice-Captain
    func setCaptain(squadId: Int) async throws {
        guard let tid = currentTeamId else { throw APIError.notAuthenticated }
        try await request(endpoint: "/api/users/\(tid)/captain/\(squadId)", method: "POST", responseType: Bool.self)
    }
    func setViceCaptain(squadId: Int) async throws {
        guard let tid = currentTeamId else { throw APIError.notAuthenticated }
        try await request(endpoint: "/api/users/\(tid)/vice-captain/\(squadId)", method: "POST", responseType: Bool.self)
    }
    
    // MARK: - Transfers
    func transferPlayer(playerInId: Int? = nil, playerOutId: Int? = nil) async throws {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        struct TransferBody: Codable {
            let user_id: Int; let player_in_id: Int?; let player_out_id: Int?
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
    
    // MARK: - Stubs
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
