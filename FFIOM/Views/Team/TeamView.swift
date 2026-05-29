import SwiftUI

struct TeamView: View {
    @ObservedObject var appState: AppStateManager
    
    var startingXI: [Player] { appState.myTeam.filter { $0.isInStartingXI } }
    var bench: [Player] { appState.myTeam.filter { !$0.isInStartingXI } }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Starting XI") {
                    if startingXI.isEmpty && !appState.myTeam.isEmpty { Text("No starting XI set").foregroundColor(.secondary) }
                    ForEach(startingXI) { p in PlayerCard(player: p, showPoints: true) }
                }
                Section("Bench") {
                    if bench.isEmpty { Text("No bench players").foregroundColor(.secondary) }
                    ForEach(bench) { p in PlayerCard(player: p, showPoints: true) }
                }
                if let captain = appState.myTeam.first(where: { $0.isCaptain }) {
                    Section("Captain") {
                        HStack { Image(systemName: "c.circle.fill").foregroundColor(.yellow); Text(captain.name).fontWeight(.bold) }
                    }
                }
            }
            .navigationTitle("My Team")
            .refreshable { await appState.refreshMyTeam() }
        }
    }
}
