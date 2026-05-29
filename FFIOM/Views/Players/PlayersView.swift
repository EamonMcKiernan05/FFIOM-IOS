import SwiftUI

enum PlayerSort: String, CaseIterable {
    case points = "points"; case goals = "goals"; case assists = "assists"; case form = "form"; case price = "price"
    var displayName: String {
        switch self { case .points: return "Points"; case .goals: return "Goals"; case .assists: return "Assists"
        case .form: return "Form"; case .price: return "Price" }
    }
}

enum PlayerPosition: String, CaseIterable {
    case all = ""; case goalkeeper = "goalkeeper"; case defender = "defender"; case midfielder = "midfielder"; case forward = "forward"
    var displayName: String {
        switch self { case .all: return "All"; case .goalkeeper: return "GK"; case .defender: return "DE"
        case .midfielder: return "MF"; case .forward: return "FW" }
    }
}

struct PlayersView: View {
    @ObservedObject var appState: AppStateManager
    @State private var sort: PlayerSort = .points
    @State private var position: PlayerPosition = .all
    @State private var search = ""
    
    var filtered: [Player] {
        var p = appState.availablePlayers
        if !search.isEmpty { p = p.filter { $0.name.lowercased().contains(search.lowercased()) || $0.team.lowercased().contains(search.lowercased()) } }
        if position != .all { p = p.filter { $0.position.lowercased() == position.rawValue } }
        switch sort {
        case .points: return p.sorted { $0.totalPoints > $1.totalPoints }
        case .goals: return p.sorted { $0.goals > $1.goals }
        case .assists: return p.sorted { $0.assists > $1.assists }
        case .form: return p.sorted { $0.form > $1.form }
        case .price: return p.sorted { $0.price > $1.price }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Search") { TextField("Search by name or team...", text: $search).textFieldStyle(RoundedBorderTextFieldStyle()) }
                Section("Position") { ForEach(PlayerPosition.allCases, id: \.self) { pos in Button(pos.displayName) { withAnimation { position = pos } }
                    .foregroundStyle(position == pos ? .green : .primary).fontWeight(position == pos ? .bold : .regular) } }
                Section("Sort By") { ForEach(PlayerSort.allCases, id: \.self) { s in Button(s.displayName) { withAnimation { sort = s } }
                    .foregroundStyle(sort == s ? .green : .primary).fontWeight(sort == s ? .bold : .regular) } }
                Section("Players") {
                    if appState.availablePlayers.isEmpty { EmptyState(icon: "person.3", title: "No Players", message: "Loading...") }
                    ForEach(filtered) { p in
                        HStack(spacing: 12) {
                            PlayerCard(player: p, showPoints: true, showPrice: true)
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("G:\(p.goals)").font(.caption2); Text("A:\(p.assists)").font(.caption2)
                                Text("F:\(p.form, specifier: "%.1f")").font(.caption2)
                            }.foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Players")
            .onAppear { Task { await appState.refreshPlayers() } }
            .refreshable { await appState.refreshPlayers() }
        }
    }
}
