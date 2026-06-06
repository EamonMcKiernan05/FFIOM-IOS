import SwiftUI

// MARK: - Team View - Pitch Layout
// Half-pitch with 3-4-3 formation, chip activation bar, centered bench
// Fixed: fits on one screen, tap popup for captain/subs, sheet for chips

struct TeamView: View {
    @ObservedObject var appState: AppStateManager
    
    // Formation positions for 3-4-3 (top-down, half pitch)
    private let formationPositions: [(x: CGFloat, y: CGFloat)] = [
        // 3 Forwards (attacking end)
        (x: 0.50, y: 0.08),   // Center forward
        (x: 0.22, y: 0.16),   // Left forward
        (x: 0.78, y: 0.16),   // Right forward
        // 4 Midfielders
        (x: 0.12, y: 0.38),   // Left midfield
        (x: 0.35, y: 0.36),   // Center-left midfield
        (x: 0.65, y: 0.36),   // Center-right midfield
        (x: 0.88, y: 0.38),   // Right midfield
        // 3 Defenders
        (x: 0.20, y: 0.62),   // Left back
        (x: 0.50, y: 0.60),   // Center back
        (x: 0.80, y: 0.62),   // Right back
    ]
    
    var startingPlayers: [SquadPlayer] {
        Array(appState.myTeam.filter { $0.isStarting }.prefix(10))
    }
    
    var benchPlayers: [SquadPlayer] {
        Array(appState.myTeam.filter { !$0.isStarting }.prefix(3))
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let availableHeight = geo.size.height
                // Reserve space for: chips bar (~70), bench (~100), padding (~60) = ~230
                let pitchHeight = max(280, availableHeight - 230)
                
                VStack(spacing: 0) {
                    // Chip activation bar
                    ChipsBarView(appState: appState)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    
                    if appState.myTeam.isEmpty {
                        EmptyState(
                            icon: "person.3.fill",
                            title: "No Players Yet",
                            message: "Your squad is empty. Set up your team from the Transfers tab."
                        )
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Half pitch - fixed height, no scroll
                        GeometryReader { geo in
                            HalfPitchContainer(
                                geo: geo,
                                players: startingPlayers,
                                positions: formationPositions,
                                captainId: appState.myTeam.first(where: { $0.isCaptain })?.id,
                                viceCaptainId: appState.myTeam.first(where: { $0.isViceCaptain })?.id,
                                appState: appState
                            )
                        }
                        .frame(height: pitchHeight)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                        
                        // Bench section
                        BenchSection(players: benchPlayers)
                            .padding(.horizontal, 12)
                            .padding(.top, 12)
                    }
                }
                .padding(.bottom, 12)
            }
            .navigationTitle("My Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.green)
                        Text(String(format: "%.1fm", appState.userStats?.budget ?? 0.0))
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { Task { await appState.refreshMyTeam() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

// MARK: - Chips Bar
struct ChipsBarView: View {
    @ObservedObject var appState: AppStateManager
    @State private var showingChipSheet = false
    @State private var selectedChipType: String?
    
    var chips: [Chip] {
        appState.chips
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ChipButton(
                    name: "Triple Captain",
                    icon: "star.fill",
                    available: chipAvailable(type: "triple_captain"),
                    active: chipActive(type: "triple_captain")
                ) {
                    selectedChipType = "triple_captain"
                    showingChipSheet = true
                }
                
                ChipButton(
                    name: "Free Hit",
                    icon: "bolt.fill",
                    available: chipAvailable(type: "free_hit"),
                    active: chipActive(type: "free_hit")
                ) {
                    selectedChipType = "free_hit"
                    showingChipSheet = true
                }
                
                ChipButton(
                    name: "Bench Boost",
                    icon: "person.3.fill",
                    available: chipAvailable(type: "bench_boost"),
                    active: chipActive(type: "bench_boost")
                ) {
                    selectedChipType = "bench_boost"
                    showingChipSheet = true
                }
                
                ChipButton(
                    name: "Wildcard",
                    icon: "wand.and.stars",
                    available: chipAvailable(type: "wildcard"),
                    active: chipActive(type: "wildcard")
                ) {
                    selectedChipType = "wildcard"
                    showingChipSheet = true
                }
            }
        }
        .sheet(isPresented: $showingChipSheet) {
            if let chipType = selectedChipType {
                ChipConfirmSheet(chipType: chipType, appState: appState)
            }
        }
    }
    
    private func chipAvailable(type: String) -> Bool {
        chips.first(where: { $0.type == type })?.available ?? false
    }
    
    private func chipActive(type: String) -> Bool {
        chips.first(where: { $0.type == type })?.active ?? false
    }
}

// MARK: - Chip Confirmation Sheet
struct ChipConfirmSheet: View {
    @Environment(\.dismiss) private var dismiss
    let chipType: String
    @ObservedObject var appState: AppStateManager
    @State private var loading = false
    
    var chipName: String {
        switch chipType {
        case "triple_captain": return "Triple Captain"
        case "free_hit": return "Free Hit"
        case "bench_boost": return "Bench Boost"
        case "wildcard": return "Wildcard"
        default: return chipType.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    var chipDescription: String {
        let chip = appState.chips.first(where: { $0.type == chipType })
        return chip?.displayDescription ?? "Activate this chip for the current gameweek."
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        switch chipType {
                        case "triple_captain":
                            Image(systemName: "star.fill").font(.system(size: 40)).foregroundColor(.yellow)
                        case "free_hit":
                            Image(systemName: "bolt.fill").font(.system(size: 40)).foregroundColor(.orange)
                        case "bench_boost":
                            Image(systemName: "person.3.fill").font(.system(size: 40)).foregroundColor(.green)
                        case "wildcard":
                            Image(systemName: "wand.and.stars").font(.system(size: 40)).foregroundColor(.purple)
                        default:
                            Image(systemName: "star.fill").font(.system(size: 40)).foregroundColor(.blue)
                        }
                        Text(chipName).font(.title2.bold())
                        Text(chipDescription).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                } header: {
                    Text("Activate Chip")
                }
                
                Section {
                    Text("This chip will be activated for the current gameweek. This cannot be undone.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: activateChip) {
                        HStack {
                            Spacer()
                            if loading {
                                ProgressView()
                            } else {
                                Text("Activate \(chipName)")
                            }
                            Spacer()
                        }
                    }
                    .disabled(loading)
                    .listRowBackground(Color.green.opacity(0.1))
                    
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .navigationTitle(chipName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func activateChip() {
        loading = true
        Task {
            do {
                try await APIService.shared.activateChip(chipType: chipType)
                await appState.loadAllData()
                dismiss()
            } catch {
                print("Chip activation error: \(error.localizedDescription)")
            }
            loading = false
        }
    }
}

struct ChipButton: View {
    let name: String
    let icon: String
    let available: Bool
    let active: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(active ? .yellow : (available ? .green : .secondary))
                Text(name)
                    .font(.caption2.bold())
                    .foregroundColor(active ? .yellow : (available ? .white : .secondary))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(active ? Color.yellow.opacity(0.15) : (available ? Color.green.opacity(0.1) : Color.gray.opacity(0.1)))
                    .stroke(active ? Color.yellow : (available ? Color.green : Color.gray.opacity(0.3)), lineWidth: 1)
            )
        }
        .disabled(!available && !active)
    }
}

// MARK: - Half Pitch Container
struct HalfPitchContainer: View {
    let geo: GeometryProxy
    let players: [SquadPlayer]
    let positions: [(x: CGFloat, y: CGFloat)]
    let captainId: Int?
    let viceCaptainId: Int?
    let appState: AppStateManager
    
    var body: some View {
        let w = geo.size.width
        let h = geo.size.height
        let margin: CGFloat = 6
        let pitchW = w - margin * 2
        let pitchH = h - margin * 2
        
        ZStack {
            // Dark background
            Color(red: 0.04, green: 0.25, blue: 0.12)
            
            // Pitch surface
            pitchSurface(width: pitchW, height: pitchH)
                .frame(width: pitchW, height: pitchH)
                .clipped()
            
            // Half pitch markings (top half only)
            halfPitchMarkings(width: pitchW, height: pitchH)
                .frame(width: pitchW, height: pitchH)
            
            // Players
            if !players.isEmpty {
                playerOverlay(width: pitchW, height: pitchH)
            }
        }
        .frame(width: w, height: h)
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func pitchSurface(width: CGFloat, height: CGFloat) -> some View {
        let stripeCount = 6
        let stripeH = height / CGFloat(stripeCount)
        let baseGreen = Color(red: 0.15, green: 0.45, blue: 0.22)
        let lightGreen = Color(red: 0.17, green: 0.50, blue: 0.25)
        
        VStack(spacing: 0) {
            ForEach(0..<stripeCount, id: \.self) { i in
                (i % 2 == 0 ? baseGreen : lightGreen)
                    .frame(height: stripeH)
            }
        }
    }
    
    @ViewBuilder
    private func halfPitchMarkings(width: CGFloat, height: CGFloat) -> some View {
        let lineW: CGFloat = max(1, width / 200)
        let lineColor = Color.white.opacity(0.4)
        
        ZStack {
            // Touchline (outer border)
            RoundedRectangle(cornerRadius: 0)
                .stroke(lineColor, lineWidth: lineW * 1.5)
            
            // Halfway line (bottom edge)
            Rectangle()
                .fill(lineColor)
                .frame(width: width, height: lineW)
                .position(x: width / 2, y: height)
            
            // Center circle (half circle at bottom)
            ArcShape(startAngle: 0, endAngle: 180)
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.2, height: width * 0.2)
                .position(x: width / 2, y: height)
            
            // Center spot
            Circle()
                .fill(lineColor)
                .frame(width: lineW * 2, height: lineW * 2)
                .position(x: width / 2, y: height - lineW)
            
            // Penalty area (top)
            Rectangle()
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.5, height: height * 0.13)
                .position(x: width / 2, y: height * 0.065)
            
            // 6-yard/goal area (top)
            Rectangle()
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.25, height: height * 0.06)
                .position(x: width / 2, y: height * 0.03)
            
            // Penalty spot (top)
            Circle()
                .fill(lineColor)
                .frame(width: lineW * 1.5, height: lineW * 1.5)
                .position(x: width / 2, y: height * 0.14)
            
            // Penalty arc (top)
            ArcShape(startAngle: 180, endAngle: 360)
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.12, height: width * 0.06)
                .position(x: width / 2, y: height * 0.13)
            
            // Corner arcs top
            ArcShape(startAngle: 0, endAngle: 90)
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.04, height: width * 0.04)
                .position(x: width * 0.02, y: height * 0.02)
            
            ArcShape(startAngle: 270, endAngle: 360)
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.04, height: width * 0.04)
                .position(x: width * 0.98, y: height * 0.02)
        }
    }
    
    @ViewBuilder
    private func playerOverlay(width: CGFloat, height: CGFloat) -> some View {
        let playerMargin: CGFloat = 24
        let availW = width - playerMargin * 2
        let availH = height - playerMargin * 2
        
        ZStack(alignment: .topLeading) {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                if index < positions.count {
                    let pos = positions[index]
                    let isCaptain = player.id == captainId
                    let isViceCaptain = player.id == viceCaptainId
                    
                    PitchPlayerNode(
                        player: player,
                        positionX: pos.x,
                        positionY: pos.y,
                        containerWidth: availW,
                        containerHeight: availH,
                        offsetX: playerMargin,
                        offsetY: playerMargin,
                        isCaptain: isCaptain,
                        isViceCaptain: isViceCaptain,
                        appState: appState
                    )
                }
            }
        }
    }
}

// MARK: - Player on Pitch
struct PitchPlayerNode: View {
    let player: SquadPlayer
    let positionX: CGFloat
    let positionY: CGFloat
    let containerWidth: CGFloat
    let containerHeight: CGFloat
    let offsetX: CGFloat
    let offsetY: CGFloat
    let isCaptain: Bool
    let isViceCaptain: Bool
    @ObservedObject var appState: AppStateManager
    
    @State private var showingPlayerMenu = false
    
    var benchPlayers: [SquadPlayer] {
        appState.myTeam.filter { !$0.isStarting }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Jersey icon (larger)
            ZStack(alignment: .topTrailing) {
                JerseyIconView(teamId: player.player.teamId, teamName: player.teamName, size: 40)
                    .frame(width: 44, height: 44)
                
                if isCaptain {
                    Text("C")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .padding(2.5)
                        .background(Color.yellow)
                        .clipShape(Circle())
                } else if isViceCaptain {
                    Text("VC")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.black)
                        .padding(2.5)
                        .background(Color.gray)
                        .clipShape(Capsule())
                }
            }
            
            // Surname only
            Text(surname(from: player.name))
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(maxWidth: 48)
        }
        .position(
            x: offsetX + containerWidth * positionX,
            y: offsetY + containerHeight * positionY
        )
        .onTapGesture {
            showingPlayerMenu = true
        }
        .sheet(isPresented: $showingPlayerMenu) {
            PlayerActionSheet(
                player: player,
                benchPlayers: benchPlayers,
                isCaptain: isCaptain,
                isViceCaptain: isViceCaptain,
                appState: appState
            )
        }
    }
    
    private func surname(from fullName: String) -> String {
        let parts = fullName.split(separator: " ")
        return parts.last?.description.capitalized ?? fullName
    }
}

// MARK: - Player Action Sheet (popup menu on tap)
struct PlayerActionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let player: SquadPlayer
    let benchPlayers: [SquadPlayer]
    let isCaptain: Bool
    let isViceCaptain: Bool
    @ObservedObject var appState: AppStateManager
    @State private var actionLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(player.name)) {
                    HStack(spacing: 12) {
                        JerseyIconView(teamId: player.player.teamId, teamName: player.teamName, size: 44)
                            .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.teamName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack(spacing: 8) {
                                if isCaptain {
                                    Label("Captain", systemImage: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                                if isViceCaptain {
                                    Label("Vice-Captain", systemImage: "star")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.0f", player.gwPoints ?? 0))
                                .font(.headline)
                                .foregroundColor(.green)
                            Text("GW Points")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Captaincy") {
                    if !isCaptain {
                        Button(action: makeCaptain) {
                            HStack {
                                Label("Make Captain", systemImage: "star.fill")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .listRowBackground(Color.yellow.opacity(0.1))
                    } else {
                        HStack {
                            Label("Current Captain", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.yellow)
                            Spacer()
                        }
                    }
                    
                    if !isViceCaptain {
                        Button(action: makeViceCaptain) {
                            HStack {
                                Label("Make Vice-Captain", systemImage: "star")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.1))
                    } else {
                        HStack {
                            Label("Current Vice-Captain", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
                
                Section("Swap with Bench") {
                    if benchPlayers.isEmpty {
                        HStack {
                            Text("No bench players available")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    ForEach(benchPlayers) { bp in
                        Button(action: { swapWith(bp) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(surname(from: bp.name))
                                        .font(.subheadline)
                                    Text("Bench")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(String(format: "%.0f", bp.gwPoints ?? 0))
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Image(systemName: "arrow.left.arrow.right")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Player Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func makeCaptain() {
        actionLoading = true
        Task {
            do {
                try await APIService.shared.setCaptain(squadId: player.id)
                await appState.refreshMyTeam()
                dismiss()
            } catch {
                print("Set captain error: \(error.localizedDescription)")
            }
            actionLoading = false
        }
    }
    
    private func makeViceCaptain() {
        actionLoading = true
        Task {
            do {
                try await APIService.shared.setViceCaptain(squadId: player.id)
                await appState.refreshMyTeam()
                dismiss()
            } catch {
                print("Set vice-captain error: \(error.localizedDescription)")
            }
            actionLoading = false
        }
    }
    
    private func swapWith(_ benchPlayer: SquadPlayer) {
        print("Swap \(player.name) with \(benchPlayer.name)")
        actionLoading = true
        dismiss()
        Task {
            do {
                try await APIService.shared.swapPlayers(startingId: player.id, benchId: benchPlayer.id)
                await appState.refreshMyTeam()
            } catch {
                print("Swap error: \(error.localizedDescription)")
            }
            actionLoading = false
        }
    }
    
    private func surname(from fullName: String) -> String {
        let parts = fullName.split(separator: " ")
        return parts.last?.description.capitalized ?? fullName
    }
}

// MARK: - Bench Section (centered, 3 players, same size as field)
struct BenchSection: View {
    let players: [SquadPlayer]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BENCH")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 4)
            
            HStack(spacing: 16) {
                if players.isEmpty {
                    Text("No bench players")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                ForEach(players) { player in
                    BenchPlayerCard(player: player)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .cornerRadius(12)
    }
}

struct BenchPlayerCard: View {
    let player: SquadPlayer
    
    var body: some View {
        VStack(spacing: 3) {
            Text("SUB")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(.secondary)
            
            JerseyIconView(teamId: player.player.teamId, teamName: player.teamName, size: 40)
                .frame(width: 44, height: 44)
            
            Text(surname(from: player.name))
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: 48)
            
            HStack(spacing: 3) {
                Text(String(format: "%.0f", player.gwPoints ?? 0))
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.green)
                
                Text(String(format: "%.1fm", player.purchasePrice))
                    .font(.system(size: 7))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 60)
        .padding(.vertical, 8)
        .background(Color(red: 0.12, green: 0.12, blue: 0.18))
        .cornerRadius(10)
    }
    
    private func surname(from fullName: String) -> String {
        let parts = fullName.split(separator: " ")
        return parts.last?.description.capitalized ?? fullName
    }
}

// MARK: - Arc Shape
struct ArcShape: Shape {
    let startAngle: Double
    let endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        guard radius > 0, radius.isFinite else { return path }
        path.addArc(
            center: center,
            radius: radius,
            startAngle: Angle(degrees: startAngle),
            endAngle: Angle(degrees: endAngle),
            clockwise: false
        )
        return path
    }
}
