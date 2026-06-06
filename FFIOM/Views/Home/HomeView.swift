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
                    GameweekSummaryView(appState: appState)
                    
                    // Quick nav links
                    HStack(spacing: 12) {
                        NavigationLink(destination: LeaderboardView(appState: appState)) {
                            NavCard(icon: "list.bullet", label: "Table", color: .blue)
                        }
                        NavigationLink(destination: FixturesView(appState: appState)) {
                            NavCard(icon: "calendar", label: "Fixtures", color: .green)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Upcoming fixtures
                    if !upcomingFixtures.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Upcoming Fixtures").font(.headline)
                                Spacer()
                                NavigationLink(destination: UpcomingFixturesView(appState: appState, gameweekId: currentGW)) {
                                    Text("See All").font(.caption).foregroundColor(.blue)
                                }
                            }
                            VStack(spacing: 8) {
                                ForEach(upcomingFixtures.prefix(3)) { fixture in
                                    FixtureRowView(fixture: fixture)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Recent results
                    if !recentResults.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent Results").font(.headline)
                                Spacer()
                                NavigationLink(destination: RecentResultsView(appState: appState)) {
                                    Text("See All").font(.caption).foregroundColor(.blue)
                                }
                            }
                            VStack(spacing: 8) {
                                ForEach(recentResults.prefix(3).sorted { $0.date ?? "" > $1.date ?? "" }) { fixture in
                                    FixtureRowView(fixture: fixture)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Top teams
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Top Teams").font(.headline)
                            Spacer()
                            NavigationLink(destination: LeaderboardView(appState: appState)) {
                                Text("Full Table").font(.caption).foregroundColor(.blue)
                            }
                        }
                        VStack(spacing: 0) {
                            ForEach(Array(appState.leaderboard.prefix(5).enumerated()), id: \.element.id) { index, entry in
                                LeaderboardRow(entry: entry, rank: index + 1).padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // My stats
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
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.green)
                        Text(String(format: "%.1fm", appState.userStats?.budget ?? 0))
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                    }
                }
            }
            .refreshable { await appState.loadAllData() }
        }
    }
}

// MARK: - Nav Card
struct NavCard: View {
    let icon: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(label).font(.caption.bold()).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(Color(UIColor.secondarySystemBackground)).cornerRadius(12)
    }
}

// MARK: - Gameweek Status Card
struct GameweekStatusCard: View {
    let gameweek: Gameweek?
    var deadlineFormatted: String {
        guard let deadline = gameweek?.deadline else { return "" }
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-ddTHH:mm:ss"
        if let date = formatter.date(from: deadline) {
            let display = DateFormatter(); display.dateFormat = "d MMM yyyy, HH:mm"
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
                        Text(gameweek!.name).font(.title2.bold())
                        if !deadlineFormatted.isEmpty {
                            Text("Deadline: \(deadlineFormatted)").font(.caption).foregroundColor(.white.opacity(0.8))
                        }
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(gameweek!.statusColor).frame(width: 8, height: 8)
                        Text(gameweek!.statusDisplay).font(.caption.bold()).foregroundColor(gameweek!.statusColor)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(
                    LinearGradient(colors: [Color(red: 0.1, green: 0.5, blue: 0.2), Color(red: 0.1, green: 0.3, blue: 0.6)], startPoint: .leading, endPoint: .trailing)))
            }
        }
    }
}

// MARK: - Fixture Row
struct FixtureRowView: View {
    let fixture: Fixture
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(fixture.homeTeam).font(.subheadline).fontWeight(.medium).lineLimit(1)
                if fixture.isFinished { Text("\(fixture.homeScore ?? 0)").font(.headline).foregroundColor(.green) }
            }
            Spacer()
            VStack(spacing: 2) {
                Text(fixture.dateFormatted).font(.caption2).foregroundColor(.secondary)
                if fixture.isFinished {
                    Text(fixture.scoreString).font(.caption.bold()).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2)).cornerRadius(4)
                } else {
                    Text(fixture.timeString).font(.caption.bold()).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15)).cornerRadius(4)
                }
            }
            Spacer()
            VStack(alignment: .leading, spacing: 2) {
                Text(fixture.awayTeam).font(.subheadline).fontWeight(.medium).lineLimit(1)
                if fixture.isFinished { Text("\(fixture.awayScore ?? 0)").font(.headline).foregroundColor(.green) }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let label: String; let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundColor(.green)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }
}

// MARK: - Gameweek Summary
struct GameweekSummaryView: View {
    @ObservedObject var appState: AppStateManager
    @State private var points: Int?
    @State private var totalPoints: Double?
    @State private var topScorer: SquadPlayer?
    @State private var captainPoints: Int?
    
    var currentGW: Int { appState.gameweek?.displayNumber ?? 0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Game Week Summary").font(.headline).foregroundColor(.white)
                    Text("GW \(currentGW)").font(.caption).foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                if let pts = points { Text("\(pts)").font(.title.bold()).foregroundColor(.green) }
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 12)
            
            if appState.myTeam.isEmpty {
                HStack {
                    StatCell(label: "GW Points", value: "-")
                    Spacer()
                    StatCell(label: "Total", value: "-")
                    Spacer()
                    StatCell(label: "Captain", value: "-")
                }
                .padding(.horizontal, 16).padding(.bottom, 12)
            } else {
                HStack {
                    StatCell(label: "GW Points", value: points.map { String($0) } ?? "-")
                    Spacer()
                    StatCell(label: "Total", value: totalPoints.map { String(Int($0)) } ?? "-")
                    Spacer()
                    StatCell(label: "Captain", value: captainPoints.map { "\($0)×2" } ?? "-")
                }
                .padding(.horizontal, 16).padding(.bottom, 8)
                
                if let top = topScorer {
                    HStack(spacing: 8) {
                        JerseyIconView(teamId: top.player.teamId, teamName: top.teamName, size: 24).frame(width: 24, height: 24)
                        Text(top.name.surname).font(.subheadline).foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.0f pts", top.gwPoints ?? 0)).font(.subheadline.bold()).foregroundColor(.green)
                    }
                    .padding(.horizontal, 16).padding(.bottom, 12)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(
            LinearGradient(colors: [Color(red: 0.05, green: 0.3, blue: 0.15), Color(red: 0.05, green: 0.2, blue: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .onAppear { calculateSummary() }
        .onReceive(appState.$myTeam) { _ in calculateSummary() }
    }
    
    private func calculateSummary() {
        let players = appState.myTeam
        guard !players.isEmpty else {
            points = nil; totalPoints = nil; topScorer = nil; captainPoints = nil; return
        }
        self.points = Int(players.reduce(0.0) { $0 + ($1.gwPoints ?? 0) })
        self.totalPoints = players.reduce(0.0) { $0 + $1.totalPoints }
        self.topScorer = players.sorted { ($0.gwPoints ?? 0) > ($1.gwPoints ?? 0) }.first
        if let captain = players.first(where: { $0.isCaptain }) {
            self.captainPoints = Int(captain.gwPoints ?? 0)
        } else { self.captainPoints = nil }
    }
}

struct StatCell: View {
    let label: String; let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold()).foregroundColor(.white)
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Upcoming Fixtures View
struct UpcomingFixturesView: View {
    @ObservedObject var appState: AppStateManager
    let gameweekId: Int
    var fixtures: [Fixture] {
        appState.fixtures.filter { $0.gameweekId == gameweekId && !$0.isFinished }
            .sorted { $0.date ?? "" < $1.date ?? "" }
    }
    var body: some View {
        List {
            if fixtures.isEmpty {
                EmptyState(icon: "calendar", title: "No Upcoming Fixtures", message: "All fixtures for this gameweek have been played.")
            } else {
                ForEach(fixtures) { fixture in GWFixtureRowView(fixture: fixture) }
            }
        }
        .navigationTitle("GW \(gameweekId) Fixtures")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await appState.refreshFixtures() }
    }
}

// MARK: - Recent Results View
struct RecentResultsView: View {
    @ObservedObject var appState: AppStateManager
    var currentGW: Int { appState.gameweek?.displayNumber ?? 0 }
    var recentResults: [Fixture] {
        let previousGWs = appState.gameweeksList.filter { $0.id < currentGW }.map { $0.id }
        return appState.fixtures.filter { previousGWs.contains($0.gameweekId) && $0.isFinished }
            .sorted { $0.date ?? "" > $1.date ?? "" }
    }
    var body: some View {
        List {
            if recentResults.isEmpty {
                EmptyState(icon: "chart.bar", title: "No Results Yet", message: "Results will appear after gameweeks are played.")
            } else {
                ForEach(recentResults.prefix(20)) { fixture in
                    HStack(spacing: 12) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(fixture.homeTeam).font(.subheadline).fontWeight(.medium).lineLimit(1)
                            Text("\(fixture.homeScore ?? 0)").font(.headline).foregroundColor(.green)
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text("GW \(fixture.gameweekId)").font(.caption2).foregroundColor(.secondary)
                            Text(fixture.scoreString).font(.caption.bold()).padding(.horizontal, 8).padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2)).cornerRadius(4)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fixture.awayTeam).font(.subheadline).fontWeight(.medium).lineLimit(1)
                            Text("\(fixture.awayScore ?? 0)").font(.headline).foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Recent Results")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await appState.refreshFixtures() }
    }
}
