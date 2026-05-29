import SwiftUI

struct HomeView: View {
    @ObservedObject var appState: AppStateManager
    @State private var showingFullLeaderboard = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GameweekBanner(gameweek: appState.gameweek).padding(.horizontal)
                    if let stats = appState.userStats {
                        HStack(spacing: 20) {
                            StatCard(icon: "star.fill", label: "Rank", value: stats.rank.map { "#\($0)" } ?? "N/A", color: .yellow)
                            StatCard(icon: "chart.bar.fill", label: "Points", value: String(format: "%.0f", stats.totalPoints), color: .green)
                            StatCard(icon: "dollarsign.circle.fill", label: "Budget", value: String(format: "%.1fm", stats.budget), color: .blue)
                            StatCard(icon: "arrow.left.arrow.right", label: "Transfers", value: "\(stats.transfersRemaining)", color: .purple)
                        }
                        .padding(.horizontal)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { Text("Top Teams").font(.title3.bold()); Spacer()
                            Button("View All") { showingFullLeaderboard = true }.font(.caption).foregroundStyle(.blue) }
                        if appState.leaderboard.isEmpty { LoadingView(message: "Loading leaderboard...") }
                        else {
                            VStack(spacing: 4) { ForEach(Array(appState.leaderboard.prefix(5)), id: \.id) { e in LeaderboardRow(entry: e, isMe: false) } }
                            .padding(8).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                        }
                    }
                    if !appState.fixtures.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fixtures").font(.title3.bold()).padding(.horizontal)
                            VStack(spacing: 4) { ForEach(Array(appState.fixtures.prefix(5)), id: \.id) { f in FixtureRow(fixture: f) } }
                            .padding(8).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showingFullLeaderboard) { LeaderboardDetailView() }
            .refreshable { await appState.refreshGameweek(); await appState.refreshLeaderboard() }
        }
    }
}

struct StatCard: View {
    let icon: String; let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color).font(.title3)
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
