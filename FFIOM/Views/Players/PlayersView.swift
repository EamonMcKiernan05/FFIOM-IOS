import SwiftUI

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
            List {
                ForEach(filteredPlayers) { player in
                    NavigationLink(destination: PlayerDetailView(player: player)) {
                        HStack(spacing: 12) {
                            // Jersey icon
                            JerseyIconView(teamId: player.team?.id, teamName: player.teamName, size: 40)
                                .frame(width: 44, height: 44)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name)
                                    .font(.subheadline.bold())
                                Text(player.teamName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                // Price
                                Text(String(format: "%.1fm", player.price))
                                    .font(.subheadline.bold())
                                    .foregroundColor(.green)
                                // Points
                                Text("\(Int(player.totalPoints)) pts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                // Goals/Assists
                                Text("G:\(player.goals) A:\(player.assists)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
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
                    }
                }
            }
            .refreshable { await appState.refreshPlayers() }
        }
    }
}

// MARK: - Player Detail View

struct PlayerDetailView: View {
    let player: Player
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Player header
                HStack(spacing: 16) {
                    JerseyIconView(teamId: player.team?.id, teamName: player.teamName, size: 60)
                        .frame(width: 66, height: 66)
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
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Player")
    }
}

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
