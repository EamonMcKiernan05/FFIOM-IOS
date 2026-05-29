import SwiftUI

struct TransfersView: View {
    @ObservedObject var appState: AppStateManager
    @State private var searchQuery = ""
    @State private var showHistory = false
    @State private var transferring = false
    @State private var transferMsg = ""
    @State private var showAlert = false
    
    var filtered: [Player] {
        if searchQuery.isEmpty { return appState.availablePlayers }
        return appState.availablePlayers.filter { $0.name.lowercased().contains(searchQuery.lowercased()) || $0.team.lowercased().contains(searchQuery.lowercased()) }
    }
    func owned(_ p: Player) -> Bool { appState.myTeam.contains { $0.id == p.id } }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Available Players") {
                    TextField("Search players...", text: $searchQuery).textFieldStyle(RoundedBorderTextFieldStyle())
                    ForEach(filtered) { p in
                        HStack {
                            PlayerCard(player: p, showPoints: true, showPrice: true)
                            Button { transfer(p) } label: {
                                Image(systemName: owned(p) ? "minus.circle.fill" : "plus.circle.fill")
                                    .foregroundColor(owned(p) ? .red : .green).font(.title3)
                            }
                        }
                    }
                }
                Section("Transfer History") {
                    Button { showHistory = true } label: { HStack { Image(systemName: "clock.arrow.circlepath"); Text("View Transfer History") } }
                }
            }
            .navigationTitle("Transfers")
            .sheet(isPresented: $showHistory) { TransferHistoryView() }
            .alert(transferMsg, isPresented: $showAlert) { Button("OK") {} }
            .overlay { if transferring { ProgressView("Processing...") } }
        }
    }
    
    func transfer(_ p: Player) {
        transferring = true
        Task {
            do {
                if owned(p) { try await APIService.shared.removePlayer(playerId: p.id); transferMsg = "Removed \(p.name)" }
                else { try await APIService.shared.addPlayer(playerId: p.id); transferMsg = "Added \(p.name)" }
                showAlert = true; await appState.refreshMyTeam(); await appState.refreshPlayers()
            } catch { transferMsg = error.localizedDescription; showAlert = true }
            transferring = false
        }
    }
}

struct TransferHistoryView: View {
    @State private var history: [Transfer] = []
    var body: some View {
        NavigationStack {
            List {
                if history.isEmpty { EmptyState(icon: "arrow.left.arrow.right", title: "No Transfers", message: "Transfer history will appear here.") }
                else { ForEach(history) { t in VStack(alignment: .leading, spacing: 4) {
                    if let pi = t.playerIn { Text("+ \(pi.name)").foregroundColor(.green) }
                    if let po = t.playerOut { Text("- \(po.name)").foregroundColor(.red) }
                    if let h = t.pointsHit { Text("Points hit: \(h)").font(.caption).foregroundColor(.secondary) }
                }}
                }
            }
            .navigationTitle("Transfer History")
            .onAppear { Task { do { history = try await APIService.shared.fetchTransferHistory() } catch {} } }
        }
    }
}
