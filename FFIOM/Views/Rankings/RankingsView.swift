import SwiftUI

struct RankingsView: View {
    @State private var players: [Player] = []
    @State private var sortBy: SortOption = .points
    
    enum SortOption: String, CaseIterable {
        case points = "Points"
        case goals = "Goals"
        case assists = "Assists"
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Sort By") {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) { sortBy = option; load() }
                            .foregroundStyle(sortBy == option ? .green : .primary)
                    }
                }
                Section("Rankings") {
                    ForEach(players) { player in
                        NavigationLink(destination: PlayerDetailView(player: player)) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.15, green: 0.45, blue: 0.8))
                                        .frame(width: 40, height: 40)
                                    Text(player.name.prefix(1).uppercased())
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.name)
                                        .font(.subheadline.bold())
                                    Text(player.teamName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(Int(player.totalPoints)) pts")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.green)
                                    Text("G:\(player.goals) A:\(player.assists)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Rankings")
            .onAppear { load() }
        }
    }
    
    func load() {
        Task {
            do {
                players = try await APIService.shared.fetchRankings(sortBy: sortBy.rawValue)
            } catch {}
        }
    }
}
