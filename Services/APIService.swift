import Foundation

/// MARK: - Shared response types

struct MeTeamData: Codable { let id: Int }
struct MeResponse: Codable { let user: User; let team: MeTeamData? }

/// Central HTTP client for all FFIOM API requests.
/// Uses KeychainService for secure token storage and APIConfig for base URL.
/// Thread-safe via @MainActor isolation.
@MainActor
class APIService: ObservableObject {
    static let shared = APIService()

    @Published var authToken: String?
    @Published var refreshToken: String?
    @Published var currentUserId: Int?
    @Published var currentTeamId: Int?

    private let keychain = KeychainService.shared

    private init() {
        // Restore credentials from Keychain
        self.authToken = keychain.getString(forKey: "authToken")
        self.refreshToken = keychain.getString(forKey: "refreshToken")
        self.currentUserId = keychain.getInt(forKey: "userId")
        self.currentTeamId = keychain.getInt(forKey: "teamId")
    }

    // MARK: - HTTP Client

    private func headers() -> [String: String] {
        var h: [String: String] = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        if let t = authToken {
            h["Authorization"] = "Bearer \(t)"
        }
        return h
    }

    /// Make an API request with authentication.
    /// - Parameters:
    ///   - endpoint: API path (e.g. "/api/users/me")
    ///   - method: HTTP method (default "GET")
    ///   - body: Optional request body
    ///   - responseType: Expected response type
    func request<T: Codable>(endpoint: String, method: String = "GET",
                             body: Encodable? = nil, responseType: T.Type) async throws -> T {
        guard let uc = URLComponents(string: "\(APIConfig.baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: uc.url!)
        req.httpMethod = method
        req.allHTTPHeaderFields = headers()
        req.timeoutInterval = APIConfig.requestTimeout
        if let body = body {
            req.httpBody = try? JSONEncoder().encode(body)
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let hr = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(hr.statusCode) else {
            if hr.statusCode == 401 {
                logout()
            }
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(hr.statusCode, msg)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodeError(error.localizedDescription)
        }
    }

    // MARK: - Auth

    func login(username: String, password: String) async throws -> AuthResponse {
        let body = LoginBody(username: username, password: password)
        let resp: AuthResponse = try await request(
            endpoint: "/api/auth/login", method: "POST", body: body, responseType: AuthResponse.self
        )

        // Store credentials securely in Keychain
        authToken = resp.accessToken
        refreshToken = resp.refreshToken
        currentUserId = resp.user.id

        keychain.setString(resp.accessToken, forKey: "authToken")
        keychain.setString(resp.refreshToken, forKey: "refreshToken")
        keychain.setInt(resp.user.id, forKey: "userId")
        keychain.setString(resp.user.username, forKey: "username")

        // Fetch team ID
        do {
            let me: MeResponse = try await request(
                endpoint: "/api/users/me", responseType: MeResponse.self
            )
            if let tid = me.team?.id {
                currentTeamId = tid
                keychain.setInt(tid, forKey: "teamId")
            }
        } catch {
            // Non-fatal — team ID will be fetched lazily
        }

        return resp
    }

    func register(username: String, password: String, email: String) async throws -> AuthResponse {
        let body = RegisterBody(username: username, email: email, password: password, team_name: nil)
        let resp: AuthResponse = try await request(
            endpoint: "/api/auth/register", method: "POST", body: body, responseType: AuthResponse.self
        )

        // Store credentials securely in Keychain
        authToken = resp.accessToken
        refreshToken = resp.refreshToken
        currentUserId = resp.user.id

        keychain.setString(resp.accessToken, forKey: "authToken")
        keychain.setString(resp.refreshToken, forKey: "refreshToken")
        keychain.setInt(resp.user.id, forKey: "userId")
        keychain.setString(resp.user.username, forKey: "username")

        if let tid = resp.team?.id {
            currentTeamId = tid
            keychain.setInt(tid, forKey: "teamId")
        }

        return resp
    }

    /// Clear all credentials and reset state.
    func logout() {
        authToken = nil
        refreshToken = nil
        currentUserId = nil
        currentTeamId = nil
        keychain.removeAll()
    }

    /// Validate current session by fetching /api/users/me.
    func refreshSession() async -> Bool {
        guard authToken != nil else { return false }
        do {
            let me: MeResponse = try await request(
                endpoint: "/api/users/me", responseType: MeResponse.self
            )
            if let tid = me.team?.id {
                currentTeamId = tid
                keychain.setInt(tid, forKey: "teamId")
            }
            return true
        } catch {
            logout()
            return false
        }
    }

    /// Lazily fetch team ID if not already cached.
    func refreshTeamId() async {
        guard authToken != nil else { return }
        do {
            let me: MeResponse = try await request(
                endpoint: "/api/users/me", responseType: MeResponse.self
            )
            if let tid = me.team?.id, currentTeamId != tid {
                currentTeamId = tid
                keychain.setInt(tid, forKey: "teamId")
            }
        } catch {
            // Non-fatal
        }
    }

    // MARK: - Gameweeks

    func fetchGameweek() async throws -> Gameweek {
        struct GWResp: Codable { let gameweek: Gameweek }
        let resp: GWResp = try await request(
            endpoint: "/api/gameweeks/current", responseType: GWResp.self
        )
        return resp.gameweek
    }

    func fetchGameweeksList() async throws -> GameweeksList {
        try await request(endpoint: "/api/gameweeks/", responseType: GameweeksList.self)
    }

    // MARK: - Leaderboard

    func fetchLeaderboard(limit: Int = 100) async throws -> [LeaderboardEntry] {
        let resp: LeaderboardResponse = try await request(
            endpoint: "/api/leaderboard/", responseType: LeaderboardResponse.self
        )
        return resp.entries
    }

    // MARK: - My Team / Squad

    func fetchMyTeam() async throws -> [SquadPlayer] {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        struct TeamResp: Codable { let squad: [SquadPlayer]? }
        let resp: TeamResp = try await request(
            endpoint: "/api/users/\(uid)/team", responseType: TeamResp.self
        )
        return resp.squad ?? []
    }

    func fetchSquad() async throws -> [SquadPlayer] {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        return try await request(
            endpoint: "/api/users/\(uid)/squad", responseType: [SquadPlayer].self
        )
    }

    // MARK: - Captain / Vice-Captain

    func setCaptain(squadId: Int) async throws {
        guard let tid = resolveTeamId() else { throw APIError.notAuthenticated }
        struct CaptResp: Codable { let status: String; let captain_id: Int }
        _ = try await request(
            endpoint: "/api/users/\(tid)/captain/\(squadId)",
            method: "POST", responseType: CaptResp.self
        )
    }

    func setViceCaptain(squadId: Int) async throws {
        guard let tid = resolveTeamId() else { throw APIError.notAuthenticated }
        struct VCRResp: Codable { let status: String; let vice_captain_id: Int }
        _ = try await request(
            endpoint: "/api/users/\(tid)/vice-captain/\(squadId)",
            method: "POST", responseType: VCRResp.self
        )
    }

    // MARK: - Swap Players (bench)

    func swapPlayers(startingId: Int, benchId: Int) async throws {
        guard let tid = resolveTeamId() else { throw APIError.notAuthenticated }
        struct SwapResp: Codable { let status: String }
        _ = try await request(
            endpoint: "/api/users/\(tid)/squad/\(startingId)/bench",
            method: "POST", responseType: SwapResp.self
        )
    }

    // MARK: - Transfers

    func transferPlayer(playerInId: Int? = nil, playerOutId: Int? = nil) async throws {
        guard let uid = currentUserId else { throw APIError.notAuthenticated }
        struct TransferBody: Codable {
            let user_id: Int
            let player_in_id: Int?
            let player_out_id: Int?
        }
        let body = TransferBody(user_id: uid, player_in_id: playerInId, player_out_id: playerOutId)
        _ = try await request(
            endpoint: "/api/transfers/player", method: "POST",
            body: body, responseType: Bool.self
        )
    }

    // MARK: - Players

    func fetchPlayers(sortBy: String = "goals", search: String? = nil) async throws -> [Player] {
        var endpoint = "/api/players/?order_by=\(sortBy)"
        if let s = search {
            endpoint += "&search=\(s)"
        }
        return try await request(endpoint: endpoint, responseType: [Player].self)
    }

    func fetchRankings(sortBy: String = "points") async throws -> [Player] {
        let ep = "/api/players/rankings?sort_by=\(sortBy)"
        return try await request(endpoint: ep, responseType: [Player].self)
    }

    func fetchTopPlayers(gameweek: Int? = nil, limit: Int = 20) async throws -> [Player] {
        var endpoint = "/api/players/top?limit=\(limit)"
        if let gw = gameweek {
            endpoint += "&gameweek_id=\(gw)"
        }
        return try await request(endpoint: endpoint, responseType: [Player].self)
    }

    // MARK: - Fixtures

    func fetchFixtures() async throws -> [Fixture] {
        let resp: FixturesResponse = try await request(
            endpoint: "/api/fixtures/", responseType: FixturesResponse.self
        )
        return resp.fixtures
    }

    func fetchFixturesForGameweek(gameweekId: Int) async throws -> [Fixture] {
        let resp: FixturesResponse = try await request(
            endpoint: "/api/fixtures/?gameweek_id=\(gameweekId)", responseType: FixturesResponse.self
        )
        return resp.fixtures
    }

    // MARK: - User

    func fetchCurrentUser() async throws -> User {
        try await request(endpoint: "/api/users/me", responseType: User.self)
    }

    func fetchMyStats() async throws -> User {
        let me: MeResponse = try await request(
            endpoint: "/api/users/me", responseType: MeResponse.self
        )
        if let tid = me.team?.id, currentTeamId != tid {
            currentTeamId = tid
            keychain.setInt(tid, forKey: "teamId")
        }
        return me.user
    }

    // MARK: - Chips

    func getChipStatus() async throws -> [Chip] {
        guard let tid = resolveTeamId() else { throw APIError.notAuthenticated }
        return try await request(
            endpoint: "/api/users/\(tid)/chips", responseType: [Chip].self
        )
    }

    func activateChip(chipType: String) async throws {
        guard let tid = resolveTeamId() else { throw APIError.notAuthenticated }
        _ = try await request(
            endpoint: "/api/users/\(tid)/chips/activate/\(chipType)",
            method: "POST", responseType: Bool.self
        )
    }

    // MARK: - Stubs (unimplemented endpoints)

    func fetchLeagues() async throws -> [League] { return [] }
    func createLeague(name: String, isPrivate: Bool = false) async throws -> League {
        throw APIError.invalidResponse
    }
    func joinLeague(code: String) async throws { throw APIError.invalidResponse }
    func fetchLeagueStandings(leagueId: Int) async throws -> [LeaderboardEntry] { return [] }
    func fetchNotifications() async throws -> [AppNotification] { return [] }
    func markAllNotificationsRead() async throws {}
    func fetchDreamTeam(gameweek: Int? = nil) async throws -> [Player] {
        try await fetchTopPlayers(limit: 11)
    }

    // MARK: - Helpers

    /// Resolve team ID, fetching lazily if needed.
    private func resolveTeamId() -> Int? {
        if let tid = currentTeamId {
            return tid
        }
        // If nil, it will be fetched by the calling method's refreshTeamId()
        return nil
    }
}

// MARK: - API Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case decodeError(String)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decodeError(let message):
            return "Parse error: \(message)"
        case .notAuthenticated:
            return "Not authenticated"
        }
    }
}
