import SwiftUI

struct TeamView: View {
    @ObservedObject var appState: AppStateManager
    
    var startingXI: [SquadPlayer] { appState.myTeam.filter { $0.isStarting } }
    var bench: [SquadPlayer] { appState.myTeam.filter { !$0.isStarting } }
    
    var body: some View {
        NavigationStack {
            List {
                if appState.myTeam.isEmpty {
                    Section {
                        EmptyState(
                            icon: "person.3.fill",
                            title: "No Players Yet",
                            message: "Your squad is empty. Set up your team from the Transfers tab."
                        )
                    }
                } else {
                    Section("Starting XI") {
                        if startingXI.isEmpty { Text("No starting XI set").foregroundColor(.secondary) }
                        ForEach(startingXI) { p in
                            TeamPlayerRow(player: p)
                        }
                    }
                    Section("Bench") {
                        if bench.isEmpty { Text("No bench players").foregroundColor(.secondary) }
                        ForEach(bench) { p in
                            TeamPlayerRow(player: p)
                        }
                    }
                }
            }
            .navigationTitle("My Team")
            .refreshable { await appState.refreshMyTeam() }
        }
    }
}

struct TeamPlayerRow: View {
    let p: SquadPlayer
    let showCaptain: Bool
    
    init(player: SquadPlayer) {
        self.p = player
        self.showCaptain = true
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(p.positionColor).frame(width: 40, height: 40)
                Text(p.positionBadge).font(.caption.bold()).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(p.name).font(.subheadline.bold()).lineLimit(1)
                    if p.isCaptain { Image(systemName: "c.circle.fill").foregroundColor(.yellow).font(.caption) }
                    if p.isViceCaptain { Image(systemName: "v.circle.fill").foregroundColor(.gray).font(.caption) }
                }
                Text(p.teamName).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if let gp = p.gwPoints {
                Text(String(format: "%.0f", gp)).font(.title3.bold()).foregroundColor(gp > 0 ? .green : .gray)
            }
        }
        .padding(.vertical, 4)
    }
}
