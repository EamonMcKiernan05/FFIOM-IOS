import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var appState: AppStateManager
    var body: some View {
        NavigationStack {
            List {
                if appState.leaderboard.isEmpty { EmptyState(icon: "list.bullet", title: "No Data", message: "Loading...") }
                ForEach(appState.leaderboard) { e in LeaderboardRow(entry: e, isMe: false) }
            }
            .navigationTitle("Leaderboard")
            .refreshable { await appState.refreshLeaderboard() }
        }
    }
}

struct LeaderboardDetailView: View {
    @State private var full: [LeaderboardEntry] = []
    var body: some View {
        NavigationStack {
            List { ForEach(full) { e in LeaderboardRow(entry: e, isMe: false) } }
            .navigationTitle("Full Leaderboard")
            .onAppear { Task { do { full = try await APIService.shared.fetchLeaderboard(limit: 200) } catch {} } }
        }
    }
}
