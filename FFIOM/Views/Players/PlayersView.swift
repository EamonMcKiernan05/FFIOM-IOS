import SwiftUI

/// Players list view with search and sort.
struct PlayersView: View {
    @ObservedObject var appState: AppStateManager
    @State private var searchQuery = ""
    @State private var sortBy: SortOption = .goals
    
    enum SortOption: String, CaseIterable {
        case points = "Points"
        case goals = "Goals"
        case assists = "Assists"
    }
    
    var filteredPlayers: [Player] {
        let sorted = appState.availablePlayers.sorted {
            switch sortBy {
            case .points: return $0.totalPoints > $1.totalPoints
            case .goals: return $0.goals > $1.goals
            case .assists: return $0.assists > $1.assists
            }
        }
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return sorted
        }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if appState.isLoadingPlayers {
                    ProgressView("Loading players...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel("Loading players")
                } else {
                    List {
                        ForEach(filteredPlayers) { player in
                            NavigationLink(destination: PlayerDetailView(player: player)) {
                                HStack(spacing: 12) {
                                    JerseyIconView(teamId: player.team?.id, teamName: player.teamName, size: 40)
                                        .frame(width: 44, height: 44)
                                        .accessibilityHidden(true)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(player.name)
                                            .font(.subheadline.bold())
                                        Text(player.teamName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(String(format: "%.1fm", player.price))
                                            .font(.subheadline.bold())
                                            .foregroundColor(.green)
                                        Text("\(Int(player.totalPoints)) pts")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("G:\(player.goals) A:\(player.assists)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                .accessibilityLabel("\(player.name), \(player.teamName), \(String(format: "%.1f", player.price)) million, \(Int(player.totalPoints)) points, \(player.goals) goals, \(player.assists) assists")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Players")
            .searchable(text: $searchQuery, prompt: "Search players...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortBy = option
                            } label: {
                                Label(option.rawValue, systemImage: sortBy == option ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .accessibilityLabel("Sort players")
                    }
                }
            }
            .refreshable { await appState.refreshPlayers() }
        }
    }
}

/// Detailed player stats view with JerseyIconView rendering.
struct PlayerDetailView: View {
    let player: Player
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Player header
                HStack(spacing: 16) {
                    JerseyIconView(teamId: player.team?.id, teamName: player.teamName, size: 60)
                        .frame(width: 66, height: 66)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.name)
                            .font(.title2.bold())
                        Text(player.teamName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1fm", player.price))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
                
                // Season stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Season Stats")
                        .font(.headline)
                    StatsGrid(
                        stats: [
                            ("Total Points", String(Int(player.totalPoints))),
                            ("Goals", "\(player.goals)"),
                            ("Assists", "\(player.assists)"),
                            ("Appearances", "\(player.apps)"),
                            ("Clean Sheets", "\(player.cleanSheets)"),
                            ("Form", String(format: "%.1f", player.form)),
                        ]
                    )
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Price info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Value")
                        .font(.headline)
                    StatsGrid(
                        stats: [
                            ("Current Price", String(format: "%.1fm", player.price)),
                            ("Start Price", String(format: "%.1fm", player.priceStart)),
                            ("Selected By", String(format: "%.1f%%", player.selectedByPercent)),
                        ]
                    )
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Injuries
                if player.isInjured {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Injury Status")
                            .font(.headline)
                        Text(player.injuryStatus ?? "Injured")
                            .foregroundColor(.red)
                            .accessibilityLabel("Injured: \(player.injuryStatus ?? "Unknown injury")")
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(player.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Reusable stat grid for player detail and other views.
struct StatsGrid: View {
    let stats: [(String, String)]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(stats, id: \.0) { label, value in
                HStack {
                    Text(label)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(value)
                        .font(.subheadline.bold())
                }
            }
        }
    }
}
