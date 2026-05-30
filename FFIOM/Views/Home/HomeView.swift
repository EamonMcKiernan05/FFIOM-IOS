import SwiftUI

struct HomeView: View {
    @ObservedObject var appState: AppStateManager
    
    var currentGW: Int {
        appState.gameweek?.displayNumber ?? (appState.gameweeksList.first?.id ?? 0)
    }
    
    var upcomingFixtures: [Fixture] {
        appState.fixtures.filter { $0.gameweekId == currentGW && !$0.isFinished }
    }
    
    var recentResults: [Fixture] {
        let previousGWs = appState.gameweeksList.filter { $0.id < currentGW }.map { $0.id }
        return appState.fixtures.filter { previousGWs.contains($0.gameweekId) && $0.isFinished }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GameweekStatusCard(gameweek: appState.gameweek)
                    
                    if !upcomingFixtures.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upcoming Fixtures").font(.headline)
                            VStack(spacing: 8) {
                                ForEach(upcomingFixtures.prefix(5)) { fixture in
                                    FixtureRowView(fixture: fixture)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    
                    if !recentResults.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Results").font(.headline)
                            VStack(spacing: 8) {
                                ForEach(recentResults.prefix(5).sorted { $0.date ?? "" > $1.date ?? "" }) { fixture in
                                    FixtureRowView(fixture: fixture)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Teams").font(.headline)
                        VStack(spacing: 0) {
                            ForEach(Array(appState.leaderboard.prefix(5).enumerated()), id: \.element.id) { index, entry in
                                LeaderboardRow(entry: entry, rank: index + 1)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        if !appState.leaderboard.isEmpty {
                            NavigationLink(destination: LeaderboardView(appState: appState)) {
                                Text("View Full Table")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
                    
                    if let stats = appState.userStats {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Stats").font(.headline)
                            HStack(spacing: 20) {
                                StatItem(label: "Points", value: String(Int(stats.totalPoints)))
                                StatItem(label: "Rank", value: stats.rank.map { "#\($0)" } ?? "N/A")
                                StatItem(label: "Budget", value: String(format: "%.1fm", stats.budget))
                                StatItem(label: "Transfers", value: "\(stats.transfersRemaining)")
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Home")
            .refreshable {
                await appState.loadAllData()
            }
        }
    }
}

// MARK: - Subviews

struct GameweekStatusCard: View {
    let gameweek: Gameweek?
    
    var deadlineFormatted: String {
        guard let deadline = gameweek?.deadline else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-ddTHH:mm:ss"
        if let date = formatter.date(from: deadline) {
            let display = DateFormatter()
            display.dateFormat = "d MMM yyyy, HH:mm"
            return display.string(from: date)
        }
        return deadline
    }
    
    var body: some View {
        Group {
            if gameweek == nil {
                EmptyState(icon: "exclamationmark.triangle", title: "No Gameweek Data", message: "Could not load gameweek information")
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(gameweek!.name)
                            .font(.title2.bold())
                        if !deadlineFormatted.isEmpty {
                            Text("Deadline: \(deadlineFormatted)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(gameweek!.statusColor)
                                .frame(width: 8, height: 8)
                            Text(gameweek!.statusDisplay)
                                .font(.caption.bold())
                                .foregroundColor(gameweek!.statusColor)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.1, green: 0.5, blue: 0.2), Color(red: 0.1, green: 0.3, blue: 0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
    }
}

struct FixtureRowView: View {
    let fixture: Fixture
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(fixture.homeTeam)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if fixture.isFinished {
                    Text("\(fixture.homeScore ?? 0)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(fixture.dateFormatted)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if fixture.isFinished {
                    Text(fixture.scoreString)
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                } else {
                    Text(fixture.timeString)
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(fixture.awayTeam)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if fixture.isFinished {
                    Text("\(fixture.awayScore ?? 0)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.green)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
