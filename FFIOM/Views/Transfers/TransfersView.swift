import SwiftUI

struct TransfersView: View {
    @ObservedObject var appState: AppStateManager
    @State private var searchQuery = ""
    @State private var transferMsg = ""
    @State private var showAlert = false
    
    var filtered: [Player] {
        if searchQuery.isEmpty { return appState.availablePlayers }
        return appState.availablePlayers.filter { $0.name.lowercased().contains(searchQuery.lowercased()) || $0.teamName.lowercased().contains(searchQuery.lowercased()) }
    }
    func isInTeam(_ p: Player) -> Bool { appState.myTeam.contains { $0.player_id == p.id } }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Available Players") {
                    TextField("Search players...", text: $searchQuery).textFieldStyle(RoundedBorderTextFieldStyle())
                    ForEach(filtered) { p in
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
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(p.formattedPrice).font(.subheadline.bold()).foregroundColor(.green)
                                Text("G:\(p.goals) A:\(p.assists)").font(.caption2).foregroundColor(.secondary)
                            }
                            Button { transfer(p) } label: {
                                Image(systemName: isInTeam(p) ? "minus.circle.fill" : "plus.circle.fill")
                                    .foregroundColor(isInTeam(p) ? .red : .green).font(.title3)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Transfers")
            .alert(transferMsg, isPresented: $showAlert) { Button("OK") {} }
        }
    }
    
    func transfer(_ p: Player) {
        Task {
            do {
                if isInTeam(p) { try await APIService.shared.transferPlayer(playerOutId: p.id) }
                else { try await APIService.shared.transferPlayer(playerInId: p.id) }
                transferMsg = isInTeam(p) ? "Removed \(p.name)" : "Added \(p.name)"
                showAlert = true; await appState.refreshMyTeam(); await appState.refreshPlayers()
            } catch { transferMsg = error.localizedDescription; showAlert = true }
        }
    }
}
