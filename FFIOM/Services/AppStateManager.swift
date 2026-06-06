import Foundation

@MainActor
class AppStateManager: ObservableObject {
    @Published var gameweek: Gameweek?
    @Published var gameweeksList: [Gameweek] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var myTeam: [SquadPlayer] = []
    @Published var availablePlayers: [Player] = []
    @Published var fixtures: [Fixture] = []
    @Published var transfers: [Transfer] = []
    @Published var leagues: [League] = []
    @Published var notifications: [AppNotification] = []
    @Published var dreamTeam: [Player] = []
    @Published var userStats: User?
    @Published var chips: [Chip] = []
    private let api = APIService.shared
    
    func loadAllData() async {
        print("📊 loadAllData: starting sequential load")
        
        // Sequential loading to avoid URLSession cancellation issues
        do { gameweek = try await api.fetchGameweek(); print("✅ gameweek loaded") } catch { print("❌ gameweek: \(error)") }
        do { let v = try await api.fetchGameweeksList(); gameweeksList = v.gameweeks; print("✅ gameweeksList loaded") } catch { print("❌ gameweeksList: \(error)") }
        do { leaderboard = try await api.fetchLeaderboard(limit: 20); print("✅ leaderboard loaded") } catch { print("❌ leaderboard: \(error)") }
        do { myTeam = try await api.fetchMyTeam(); print("✅ myTeam loaded (\(myTeam.count) players)") } catch { print("❌ myTeam: \(error)") }
        do { availablePlayers = try await api.fetchPlayers(); print("✅ players loaded (\(availablePlayers.count))") } catch { print("❌ players: \(error)") }
        do { fixtures = try await api.fetchFixtures(); print("✅ fixtures loaded") } catch { print("❌ fixtures: \(error)") }
        do { notifications = try await api.fetchNotifications(); print("✅ notifications loaded") } catch { print("❌ notifications: \(error)") }
        do { userStats = try await api.fetchMyStats(); print("✅ userStats loaded (budget: \(userStats?.budget ?? 0)m)") } catch { print("❌ userStats: \(error)") }
        do { chips = try await api.getChipStatus(); print("✅ chips loaded") } catch { print("❌ chips: \(error)") }
        
        print("📊 loadAllData: complete")
    }
    
    func refreshGameweek() async { do { gameweek = try await api.fetchGameweek() } catch {} }
    func refreshLeaderboard() async { do { leaderboard = try await api.fetchLeaderboard(limit: 20) } catch {} }
    func refreshMyTeam() async { do { myTeam = try await api.fetchMyTeam() } catch {} }
    func refreshPlayers() async { do { availablePlayers = try await api.fetchPlayers() } catch {} }
    func refreshFixtures() async { do { fixtures = try await api.fetchFixtures() } catch {} }
    func refreshChips() async { do { chips = try await api.getChipStatus() } catch {} }
}
