import SwiftUI

// MARK: - Transfers View
// Pitch layout with 4-5-4 formation, player overlay, transfer flow
// Fixed: PlayerTransferOverlay navigates within NavigationStack instead of double-sheet

struct TransfersView: View {
    @ObservedObject var appState: AppStateManager
    
    // 4-4-4 + GK = 13 players for transfers
    private let transferFormationPositions: [(x: CGFloat, y: CGFloat)] = [
        // Goalkeeper
        (x: 0.50, y: 0.90),
        // 4 Defenders
        (x: 0.15, y: 0.72),
        (x: 0.38, y: 0.70),
        (x: 0.62, y: 0.70),
        (x: 0.85, y: 0.72),
        // 4 Midfielders
        (x: 0.15, y: 0.48),
        (x: 0.38, y: 0.46),
        (x: 0.62, y: 0.46),
        (x: 0.85, y: 0.48),
        // 4 Forwards
        (x: 0.15, y: 0.22),
        (x: 0.38, y: 0.18),
        (x: 0.62, y: 0.18),
        (x: 0.85, y: 0.22),
    ]
    
    @State private var selectedPlayer: SquadPlayer?
    @State private var showingTransferIn = false
    @State private var pendingTransfers: [PendingTransfer] = []
    @State private var confirmError: String?
    @State private var showAlert = false
    @State private var transferOutPlayer: SquadPlayer?
    
    var allSquadPlayers: [SquadPlayer] {
        Array(appState.myTeam.prefix(13))
    }
    
    var hasPendingTransfers: Bool {
        !pendingTransfers.isEmpty
    }
    
    var canAffordAll: Bool {
        let totalCost = pendingTransfers.reduce(0.0) { $0 + $1.priceChange }
        return (appState.userStats?.budget ?? 0) >= totalCost
    }
    
    var transfersCost: Double {
        pendingTransfers.reduce(0.0) { $0 + $1.priceChange }
    }
    
    var transfersFeeDescription: String {
        let freeTransfers = appState.userStats?.transfersRemaining ?? 0
        let count = pendingTransfers.count
        
        if count <= freeTransfers {
            return "Free transfers remaining: \(freeTransfers)"
        }
        
        let extra = count - freeTransfers
        let pointsHit = extra * 4
        return "\(extra) extra transfer(s) → -\(pointsHit) pts"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if appState.myTeam.isEmpty {
                        EmptyState(
                            icon: "person.3.fill",
                            title: "No Players Yet",
                            message: "Your squad is empty. Add players below."
                        )
                        .padding(.top, 40)
                    } else {
                        // Transfers pitch
                        GeometryReader { geo in
                            TransferPitchContainer(
                                geo: geo,
                                players: allSquadPlayers,
                                positions: transferFormationPositions,
                                onSelect: { player in
                                    selectedPlayer = player
                                }
                            )
                        }
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                        
                        // Confirm transfers button
                        if hasPendingTransfers {
                            TransferConfirmSection(
                                pendingTransfers: pendingTransfers,
                                canAfford: canAffordAll,
                                transfersCost: transfersCost,
                                feeDescription: transfersFeeDescription,
                                budget: appState.userStats?.budget ?? 0,
                                onConfirm: confirmTransfers,
                                onClear: { pendingTransfers.removeAll() }
                            )
                            .padding(.horizontal, 12)
                            .padding(.top, 16)
                        }
                    }
                    
                    // Add first player option
                    if appState.myTeam.count < 13 {
                        Button {
                            transferOutPlayer = nil
                            showingTransferIn = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Add Player to Squad")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 16)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Transfers")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedPlayer) { player in
                PlayerTransferOverlay(
                    player: player,
                    appState: appState,
                    pendingTransfers: $pendingTransfers
                )
            }
            .sheet(isPresented: $showingTransferIn) {
                TransferInListView(
                    appState: appState,
                    pendingTransfers: $pendingTransfers,
                    playerOut: transferOutPlayer,
                    onTransferComplete: { showingTransferIn = false }
                )
            }
            .alert("Transfer Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(confirmError ?? "An error occurred")
            }
            .refreshable {
                await appState.loadAllData()
            }
        }
    }
    
    private func confirmTransfers() {
        guard canAffordAll else {
            confirmError = "Not enough budget for these transfers."
            showAlert = true
            return
        }
        
        guard !pendingTransfers.isEmpty else { return }
        
        // Validate each transfer has a player out
        for transfer in pendingTransfers {
            if transfer.playerOutId == nil {
                confirmError = "Each transfer requires a player to be removed first."
                showAlert = true
                return
            }
        }
        
        // Execute transfers
        Task {
            do {
                for transfer in pendingTransfers {
                    try await APIService.shared.transferPlayer(
                        playerInId: transfer.playerInId,
                        playerOutId: transfer.playerOutId
                    )
                }
                await appState.loadAllData()
                pendingTransfers.removeAll()
            } catch {
                confirmError = error.localizedDescription
                showAlert = true
            }
        }
    }
}

// MARK: - Transfer Pitch
struct TransferPitchContainer: View {
    let geo: GeometryProxy
    let players: [SquadPlayer]
    let positions: [(x: CGFloat, y: CGFloat)]
    let onSelect: (SquadPlayer) -> Void
    
    var body: some View {
        let w = geo.size.width
        let h = geo.size.height
        let margin: CGFloat = 6
        let pitchW = w - margin * 2
        let pitchH = h - margin * 2
        
        ZStack {
            Color(red: 0.04, green: 0.25, blue: 0.12)
            transferPitchSurface(width: pitchW, height: pitchH)
                .frame(width: pitchW, height: pitchH)
                .clipped()
            transferPitchMarkings(width: pitchW, height: pitchH)
                .frame(width: pitchW, height: pitchH)
            if !players.isEmpty {
                transferPlayerOverlay(width: pitchW, height: pitchH)
            }
        }
        .frame(width: w, height: h)
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func transferPitchSurface(width: CGFloat, height: CGFloat) -> some View {
        let stripeCount = 6
        let stripeH = height / CGFloat(stripeCount)
        let baseGreen = Color(red: 0.15, green: 0.45, blue: 0.22)
        let lightGreen = Color(red: 0.17, green: 0.50, blue: 0.25)
        VStack(spacing: 0) {
            ForEach(0..<stripeCount, id: \.self) { i in
                (i % 2 == 0 ? baseGreen : lightGreen).frame(height: stripeH)
            }
        }
    }
    
    @ViewBuilder
    private func transferPitchMarkings(width: CGFloat, height: CGFloat) -> some View {
        let lineW: CGFloat = max(1, width / 200)
        let lineColor = Color.white.opacity(0.4)
        ZStack {
            RoundedRectangle(cornerRadius: 0).stroke(lineColor, lineWidth: lineW * 1.5)
            Rectangle().fill(lineColor).frame(width: width, height: lineW).position(x: width/2, y: height)
            ArcShape(startAngle: 0, endAngle: 180).stroke(lineColor, lineWidth: lineW).frame(width: width*0.2, height: width*0.2).position(x: width/2, y: height)
            Circle().fill(lineColor).frame(width: lineW*2, height: lineW*2).position(x: width/2, y: height-lineW)
            Rectangle().stroke(lineColor, lineWidth: lineW).frame(width: width*0.5, height: height*0.13).position(x: width/2, y: height*0.065)
            Rectangle().stroke(lineColor, lineWidth: lineW).frame(width: width*0.25, height: height*0.06).position(x: width/2, y: height*0.03)
            Circle().fill(lineColor).frame(width: lineW*1.5, height: lineW*1.5).position(x: width/2, y: height*0.14)
            ArcShape(startAngle: 180, endAngle: 360).stroke(lineColor, lineWidth: lineW).frame(width: width*0.12, height: width*0.06).position(x: width/2, y: height*0.13)
            ArcShape(startAngle: 0, endAngle: 90).stroke(lineColor, lineWidth: lineW).frame(width: width*0.04, height: width*0.04).position(x: width*0.02, y: height*0.02)
            ArcShape(startAngle: 270, endAngle: 360).stroke(lineColor, lineWidth: lineW).frame(width: width*0.04, height: width*0.04).position(x: width*0.98, y: height*0.02)
        }
    }
    
    @ViewBuilder
    private func transferPlayerOverlay(width: CGFloat, height: CGFloat) -> some View {
        let playerMargin: CGFloat = 24
        let availW = width - playerMargin * 2
        let availH = height - playerMargin * 2
        ZStack(alignment: .topLeading) {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                if index < positions.count {
                    let pos = positions[index]
                    TransferPlayerNode(
                        player: player,
                        positionX: pos.x, positionY: pos.y,
                        containerWidth: availW, containerHeight: availH,
                        offsetX: playerMargin, offsetY: playerMargin,
                        onTap: { onSelect(player) }
                    )
                }
            }
        }
    }
}

// MARK: - Transfer Player Node
struct TransferPlayerNode: View {
    let player: SquadPlayer
    let positionX: CGFloat
    let positionY: CGFloat
    let containerWidth: CGFloat
    let containerHeight: CGFloat
    let offsetX: CGFloat
    let offsetY: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    JerseyIconView(teamId: player.player.teamId, teamName: player.teamName, size: 40)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(2)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .offset(x: 14, y: -14)
                }
                Text(surname(player.name))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(maxWidth: 48)
            }
        }
        .buttonStyle(.plain)
        .position(x: offsetX + containerWidth * positionX, y: offsetY + containerHeight * positionY)
    }
    
    private func surname(_ name: String) -> String {
        let parts = name.split(separator: " ")
        return parts.last?.description.capitalized ?? name
    }
}

// MARK: - Confirm Section
struct TransferConfirmSection: View {
    let pendingTransfers: [PendingTransfer]
    let canAfford: Bool
    let transfersCost: Double
    let feeDescription: String
    let budget: Double
    let onConfirm: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Transfers: \(pendingTransfers.count)")
                .font(.headline)
            
            ForEach(pendingTransfers) { transfer in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(transfer.playerOut?.name ?? "Empty slot")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("↓")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(transfer.playerIn.name)
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(transfer.priceChange >= 0 ? "+\(transfer.priceChange, specifier: "%.1f")m" : "\(transfer.priceChange, specifier: "%.1f")m")
                            .font(.caption2)
                            .foregroundColor(transfer.priceChange >= 0 ? .green : .red)
                    }
                }
                .padding(.vertical, 2)
            }
            
            HStack {
                Text("Budget: \(budget, specifier: "%.1f")m → \(budget - transfersCost, specifier: "%.1f")m")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(feeDescription)
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            
            HStack(spacing: 12) {
                Button("Clear") { onClear() }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                Spacer()
                Button(canAfford ? "Confirm" : "Cannot Afford") {
                    if canAfford { onConfirm() }
                }
                .buttonStyle(.borderedProminent)
                .tint(canAfford ? .green : .gray)
                .disabled(!canAfford)
            }
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .cornerRadius(12)
    }
}

// MARK: - Player Transfer Overlay
// FIXED: Uses navigation within NavigationStack instead of double-sheet
struct PlayerTransferOverlay: View {
    @Environment(\.dismiss) private var dismiss
    let player: SquadPlayer
    @ObservedObject var appState: AppStateManager
    @Binding var pendingTransfers: [PendingTransfer]
    
    // Navigation state - pushes TransferInListView within the same sheet
    @State private var showTransferInList = false
    
    var currentGW: Int {
        appState.gameweek?.displayNumber ?? 0
    }
    
    var upcomingFixtures: [Fixture] {
        let upcomingGWs = appState.gameweeksList.filter { $0.id >= currentGW }
            .map { $0.id }.prefix(3)
        return appState.fixtures
            .filter { upcomingGWs.contains($0.gameweekId) }
            .filter { $0.homeTeam == player.teamName || $0.awayTeam == player.teamName }
            .prefix(3)
            .sorted { $0.date ?? "" < $1.date ?? "" }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Player header
                Section {
                    HStack(spacing: 12) {
                        JerseyIconView(teamId: player.player.teamId, teamName: player.teamName, size: 56)
                            .frame(width: 56, height: 56)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.name)
                                .font(.headline)
                            Text(player.teamName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.1fm", player.purchasePrice))
                            .font(.title3.bold())
                            .foregroundColor(.green)
                    }
                }
                
                // Recent form
                Section("Recent Form") {
                    HStack {
                        Text("GW Points")
                        Spacer()
                        Text(String(format: "%.0f", player.gwPoints ?? 0))
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    HStack {
                        Text("Total Points")
                        Spacer()
                        Text(String(format: "%.0f", player.totalPoints))
                            .fontWeight(.bold)
                    }
                }
                
                // Next fixtures
                Section("Next 3 Fixtures") {
                    if upcomingFixtures.isEmpty {
                        Text("No upcoming fixtures")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(upcomingFixtures) { fixture in
                            HStack {
                                let opponent = fixture.opponent(forTeam: player.teamName)
                                let isHome = fixture.isHome(forTeam: player.teamName)
                                Text("\(isHome ? "vs" : "@") \(opponent)")
                                    .font(.subheadline)
                                Spacer()
                                Text(fixture.dateFormatted)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Transfer button
                Section {
                    Button {
                        // Create pending transfer - use player_id (actual player ID) for backend
                        let pending = PendingTransfer(
                            playerOutId: player.player_id,
                            playerOut: Player(
                                id: player.player_id, name: player.name, team: nil,
                                price: player.purchasePrice, priceStart: player.purchasePrice,
                                apps: 0, goals: 0, assists: 0, cleanSheets: 0,
                                totalPoints: player.totalPoints, gwPoints: player.gwPoints,
                                form: 0, selectedByPercent: 0,
                                isInjured: false, injuryStatus: nil
                            ),
                            playerInId: -1,
                            playerIn: Player(
                                id: -1, name: "Select player...", team: nil,
                                price: 0, priceStart: 0,
                                apps: 0, goals: 0, assists: 0, cleanSheets: 0,
                                totalPoints: 0, gwPoints: nil, form: 0,
                                selectedByPercent: 0, isInjured: false, injuryStatus: nil
                            )
                        )
                        pendingTransfers.append(pending)
                        // Navigate to player selection WITHIN this NavigationStack
                        showTransferInList = true
                    } label: {
                        Text("Transfer Player")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            .navigationTitle("Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            // Navigate to TransferInListView within the same NavigationStack
            .navigationDestination(isPresented: $showTransferInList) {
                TransferInListView(
                    appState: appState,
                    pendingTransfers: $pendingTransfers,
                    playerOut: player,
                    onTransferComplete: { dismiss() }
                )
            }
        }
    }
}

// MARK: - Transfer In List
struct TransferInListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppStateManager
    @Binding var pendingTransfers: [PendingTransfer]
    let playerOut: SquadPlayer?
    let onTransferComplete: (() -> Void)?
    
    @State private var sortBy: SortOption = .points
    @State private var selectedClub: String?
    @State private var affordableOnly = false
    
    enum SortOption: String, CaseIterable {
        case points = "Points"
        case price = "Price"
        case selected = "% Selected"
    }
    
    var myPlayerIds: Set<Int> {
        Set(appState.myTeam.map { $0.player_id })
    }
    
    var budget: Double {
        appState.userStats?.budget ?? 0
    }
    
    var activeTransfer: PendingTransfer? {
        pendingTransfers.first { $0.playerInId == -1 }
    }
    
    var availablePlayers: [Player] {
        var players = appState.availablePlayers.filter { !myPlayerIds.contains($0.id) }
        
        if affordableOnly, let transfer = activeTransfer {
            let outPrice = transfer.playerOut?.price ?? 0
            let maxPrice = budget + outPrice
            players = players.filter { $0.price <= maxPrice }
        }
        
        if let club = selectedClub {
            players = players.filter { $0.teamName == club }
        }
        
        switch sortBy {
        case .points: players.sort { ($0.totalPoints) > ($1.totalPoints) }
        case .price: players.sort { $0.price < $1.price }
        case .selected: players.sort { $0.selectedByPercent > $1.selectedByPercent }
        }
        
        return players
    }
    
    var allClubs: [String] {
        Array(Set(appState.availablePlayers.map { $0.teamName })).sorted()
    }
    
    var body: some View {
        List {
            Section("Sort By") {
                ForEach(SortOption.allCases, id: \.self) { option in
                    HStack {
                        Text(option.rawValue)
                        Spacer()
                        if sortBy == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { sortBy = option }
                }
            }
            
            Section("Filters") {
                HStack {
                    Button("All Clubs") { selectedClub = nil }
                        .buttonStyle(.bordered)
                        .tint(selectedClub == nil ? .green : .secondary)
                    Spacer()
                    Picker("Club", selection: $selectedClub) {
                        Text("All").tag(nil as String?)
                        ForEach(allClubs, id: \.self) { club in
                            Text(club).tag(club as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Toggle("Affordable Players Only", isOn: $affordableOnly)
            }
            
            Section("Available Players") {
                ForEach(availablePlayers.prefix(50)) { player in
                    Button {
                        transferIn(player: player)
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.green.opacity(0.8))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("+").font(.title3.bold()).foregroundColor(.white)
                                )
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
                                Text("Pts: \(Int(player.totalPoints)) • \(player.selectedByPercent, specifier: "%.1f")%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                
                if availablePlayers.isEmpty {
                    EmptyState(icon: "person.crop.circle", title: "No Players Available", message: "Try adjusting your filters.")
                }
            }
        }
        .navigationTitle("Transfer In")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .refreshable {
            await appState.refreshPlayers()
        }
    }
    
    private func transferIn(player: Player) {
        guard let transfer = activeTransfer else { return }
        if let index = pendingTransfers.firstIndex(where: { $0.id == transfer.id }) {
            pendingTransfers[index].playerInId = player.id
            pendingTransfers[index].playerIn = player
        }
        dismiss()
        // After selecting a player to transfer in, go back to the main transfers page
        onTransferComplete?()
    }
}
