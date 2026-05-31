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
        await withTaskGroup(of: Void.self) { group in
            group.addTask { do { let v = try await self.api.fetchGameweek(); await MainActor.run { self.gameweek = v } } catch {} }
            group.addTask { do { let v = try await self.api.fetchGameweeksList(); await MainActor.run { self.gameweeksList = v.gameweeks } } catch {} }
            group.addTask { do { let v = try await self.api.fetchLeaderboard(limit: 20); await MainActor.run { self.leaderboard = v } } catch {} }
            group.addTask { do { let v = try await self.api.fetchMyTeam(); await MainActor.run { self.myTeam = v } } catch {} }
            group.addTask { do { let v = try await self.api.fetchPlayers(); await MainActor.run { self.availablePlayers = v } } catch {} }
            group.addTask { do { let v = try await self.api.fetchFixtures(); await MainActor.run { self.fixtures = v } } catch {} }
            group.addTask { do { let v = try await self.api.fetchNotifications(); await MainActor.run { self.notifications = v } } catch {} }
            group.addTask { do { let v = try await self.api.fetchMyStats(); await MainActor.run { self.userStats = v } } catch {} }
            group.addTask { do { let v = try await self.api.getChipStatus(); await MainActor.run { self.chips = v } } catch {} }
            await group.waitForAll()
        }
    }
    func refreshGameweek() async { do { gameweek = try await api.fetchGameweek() } catch {} }
    func refreshLeaderboard() async { do { leaderboard = try await api.fetchLeaderboard(limit: 20) } catch {} }
    func refreshMyTeam() async { do { myTeam = try await api.fetchMyTeam() } catch {} }
    func refreshPlayers() async { do { availablePlayers = try await api.fetchPlayers() } catch {} }
    func refreshFixtures() async { do { fixtures = try await api.fetchFixtures() } catch {} }
    func refreshChips() async { do { chips = try await api.getChipStatus() } catch {} }
}
