import SwiftUI

struct RankingsView: View {
    @State private var players: [Player] = []
    @State private var sort: PlayerSort = .points
    @State private var position: PlayerPosition = .all
    var body: some View {
        NavigationStack {
            List {
                Section("Sort By") { ForEach(PlayerSort.allCases, id: \.self) { s in Button(s.displayName) { sort = s; load() }.foregroundStyle(sort == s ? .green : .primary) } }
                Section("Position") { ForEach(PlayerPosition.allCases, id: \.self) { p in Button(p.displayName) { position = p; load() }.foregroundStyle(position == p ? .green : .primary) } }
                Section("Rankings") { ForEach(players) { p in PlayerCard(player: p, showPoints: true, showPrice: true) } }
            }
            .navigationTitle("Rankings")
            .onAppear { load() }
        }
    }
    func load() { Task { do { players = try await APIService.shared.fetchRankings(sortBy: sort.rawValue, position: position.rawValue.isEmpty ? nil : position.rawValue) } catch {} } }
}
