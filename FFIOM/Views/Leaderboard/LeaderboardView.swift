import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var appState: AppStateManager
    
    var body: some View {
        List {
            ForEach(Array(appState.leaderboard.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(entry: entry, rank: index + 1)
            }
            if appState.leaderboard.isEmpty {
                EmptyState(
                    icon: "trophy",
                    title: "No Leaderboard Data",
                    message: "The leaderboard will appear when gameweek data is available."
                )
            }
        }
        .navigationTitle("Table")
        .refreshable { await appState.refreshLeaderboard() }
    }
}
