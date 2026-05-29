import SwiftUI

struct TeamView: View {
    @ObservedObject var appState: AppStateManager
    
    var startingXI: [SquadPlayer] { appState.myTeam.filter { $0.isStarting } }
    var bench: [SquadPlayer] { appState.myTeam.filter { !$0.isStarting } }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Starting XI") {
                    if startingXI.isEmpty && !appState.myTeam.isEmpty { Text("No starting XI set").foregroundColor(.secondary) }
                    ForEach(startingXI) { p in
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
                Section("Bench") {
                    ForEach(bench) { p in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(p.positionColor).frame(width: 40, height: 40)
                                Text(p.positionBadge).font(.caption.bold()).foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name).font(.subheadline.bold()).lineLimit(1)
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
            }
            .navigationTitle("My Team")
            .refreshable { await appState.refreshMyTeam() }
        }
    }
}
