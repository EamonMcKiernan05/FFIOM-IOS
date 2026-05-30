import SwiftUI

struct TransfersView: View {
    @ObservedObject var appState: AppStateManager
    @State private var selectedPlayer: Player?
    @State private var showTransferConfirm = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var transferLoading = false
    
    var myPlayerIds: Set<Int> {
        Set(appState.myTeam.map { $0.player_id })
    }
    
    var availablePlayers: [Player] {
        appState.availablePlayers.filter { !myPlayerIds.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availablePlayers.prefix(20)) { player in
                    Button {
                        selectedPlayer = player
                        showTransferConfirm = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.8))
                                    .frame(width: 40, height: 40)
                                Text("+")
                                    .font(.title3.bold())
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
                                Text("\(player.price, specifier: "%.1f")m")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.green)
                                Text("G:\(player.goals) A:\(player.assists)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Transfers")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await appState.refreshPlayers() }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .confirmationDialog(
                "Add \(selectedPlayer?.name ?? "")?",
                isPresented: $showTransferConfirm,
                titleVisibility: .visible
            ) {
                Button("Add to Squad") {
                    performTransfer()
                }
                .tint(.green)
                Button("Cancel", role: .cancel) {}
            } message: {
                if let player = selectedPlayer {
                    Text("Price: \(player.price, specifier: "%.1f")m\nGoals: \(player.goals) • Assists: \(player.assists)")
                }
            }
        }
    }
    
    private func performTransfer() {
        guard let player = selectedPlayer else { return }
        transferLoading = true
        Task {
            do {
                try await APIService.shared.transferPlayer(playerInId: player.id)
                await appState.refreshMyTeam()
                await appState.refreshPlayers()
                transferLoading = false
            } catch {
                errorMessage = error.localizedDescription
                showAlert = true
                transferLoading = false
            }
        }
    }
}
