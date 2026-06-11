import Foundation

/// Central application state manager with loading indicators and error tracking.
/// Uses sequential loading to avoid URLSession cancellation issues on simulator.
@MainActor
class AppStateManager: ObservableObject {
    // MARK: - Data

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

    // MARK: - Loading & Error State

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoadingGameweek = false
    @Published var isLoadingTeam = false
    @Published var isLoadingPlayers = false
    @Published var isLoadingFixtures = false
    @Published var isLoadingChips = false

    private let api = APIService.shared

    // MARK: - Data Loading

    /// Load all data sequentially to avoid connection pool issues on simulator.
    func loadAllData() async {
        isLoading = true
        errorMessage = nil

        do {
            isLoadingGameweek = true
            gameweek = try await api.fetchGameweek()
        } catch {
            errorMessage = "Failed to load gameweek: \(error.localizedDescription)"
        }
        isLoadingGameweek = false

        do {
            let v = try await api.fetchGameweeksList()
            gameweeksList = v.gameweeks
        } catch {
            // Non-critical
        }

        do {
            leaderboard = try await api.fetchLeaderboard(limit: 20)
        } catch {
            // Non-critical
        }

        do {
            isLoadingTeam = true
            myTeam = try await api.fetchMyTeam()
        } catch {
            errorMessage = "Failed to load team: \(error.localizedDescription)"
        }
        isLoadingTeam = false

        do {
            isLoadingPlayers = true
            availablePlayers = try await api.fetchPlayers()
        } catch {
            errorMessage = "Failed to load players: \(error.localizedDescription)"
        }
        isLoadingPlayers = false

        do {
            isLoadingFixtures = true
            fixtures = try await api.fetchFixtures()
        } catch {
            errorMessage = "Failed to load fixtures: \(error.localizedDescription)"
        }
        isLoadingFixtures = false

        do {
            userStats = try await api.fetchMyStats()
        } catch {
            // Non-critical — userStats may load later
        }

        do {
            isLoadingChips = true
            chips = try await api.getChipStatus()
        } catch {
            // Non-critical
        }
        isLoadingChips = false

        // Notifications stub
        _ = try? await api.fetchNotifications()

        isLoading = false
    }

    // MARK: - Individual Refresh Methods

    func refreshGameweek() async {
        do { gameweek = try await api.fetchGameweek() } catch {}
    }

    func refreshLeaderboard() async {
        do { leaderboard = try await api.fetchLeaderboard(limit: 20) } catch {}
    }

    func refreshMyTeam() async {
        isLoadingTeam = true
        do { myTeam = try await api.fetchMyTeam() } catch {}
        isLoadingTeam = false
    }

    func refreshPlayers() async {
        isLoadingPlayers = true
        do { availablePlayers = try await api.fetchPlayers() } catch {}
        isLoadingPlayers = false
    }

    func refreshFixtures() async {
        isLoadingFixtures = true
        do { fixtures = try await api.fetchFixtures() } catch {}
        isLoadingFixtures = false
    }

    func refreshChips() async {
        isLoadingChips = true
        do { chips = try await api.getChipStatus() } catch {}
        isLoadingChips = false
    }

    /// Clear error message.
    func clearError() {
        errorMessage = nil
    }
}
