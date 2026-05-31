import SwiftUI

// MARK: - Team View - Pitch Layout
// Green football pitch with players in 3-4-3 formation (no goalkeeper)
// 10 outfield players on pitch + bench players underneath
// Pitch markings match web UI: center circle, penalty areas, 6-yard boxes, corner arcs

struct TeamView: View {
    @ObservedObject var appState: AppStateManager
    
    // Formation positions centered on the pitch (3-4-3, top-down view)
    // x: horizontal (0=left, 1=right), y: vertical (0=attacking end, 1=defending end)
    private let formationPositions: [(x: CGFloat, y: CGFloat)] = [
        // 3 Forwards (top of pitch = attacking end)
        (x: 0.50, y: 0.06),   // Center forward
        (x: 0.22, y: 0.14),  // Left forward
        (x: 0.78, y: 0.14),  // Right forward
        // 4 Midfielders
        (x: 0.12, y: 0.34),  // Left midfield
        (x: 0.35, y: 0.32),  // Center-left midfield
        (x: 0.65, y: 0.32),  // Center-right midfield
        (x: 0.88, y: 0.34),  // Right midfield
        // 3 Defenders
        (x: 0.18, y: 0.58),  // Left back
        (x: 0.50, y: 0.56),  // Center back
        (x: 0.82, y: 0.58),  // Right back
    ]
    
    var startingPlayers: [SquadPlayer] {
        Array(appState.myTeam.filter { $0.isStarting }.prefix(10))
    }
    
    var benchPlayers: [SquadPlayer] {
        appState.myTeam.filter { !$0.isStarting }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if appState.myTeam.isEmpty {
                        EmptyState(
                            icon: "person.3.fill",
                            title: "No Players Yet",
                            message: "Your squad is empty. Set up your team from the Transfers tab."
                        )
                        .padding(.top, 40)
                    } else {
                        GeometryReader { geo in
                            PitchContainer(
                                geo: geo,
                                players: startingPlayers,
                                positions: formationPositions,
                                captainId: appState.myTeam.first(where: { $0.isCaptain })?.id,
                                viceCaptainId: appState.myTeam.first(where: { $0.isViceCaptain })?.id
                            )
                        }
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        
                        BenchSection(players: benchPlayers)
                            .padding(.horizontal, 12)
                            .padding(.top, 16)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("My Team")
            .refreshable { await appState.refreshMyTeam() }
        }
    }
}

// MARK: - Pitch Container with full markings

struct PitchContainer: View {
    let geo: GeometryProxy
    let players: [SquadPlayer]
    let positions: [(x: CGFloat, y: CGFloat)]
    let captainId: Int?
    let viceCaptainId: Int?
    
    var body: some View {
        let w = geo.size.width
        let h = geo.size.height
        
        // Inset for touchline border
        let margin: CGFloat = 6
        let pitchW = w - margin * 2
        let pitchH = h - margin * 2
        
        ZStack {
            // Dark background behind touchline
            Color(red: 0.04, green: 0.25, blue: 0.12)
            
            // Pitch surface with mowing stripes
            pitchSurface(width: pitchW, height: pitchH)
                .frame(width: pitchW, height: pitchH)
                .clipped()
            
            // Pitch markings
            pitchMarkings(width: pitchW, height: pitchH)
                .frame(width: pitchW, height: pitchH)
            
            // Players positioned within the pitch area
            if !players.isEmpty {
                playerOverlay(width: pitchW, height: pitchH)
            }
        }
        .frame(width: w, height: h)
        .cornerRadius(8)
    }
    
    // MARK: - Pitch surface with mowing stripes
    
    @ViewBuilder
    private func pitchSurface(width: CGFloat, height: CGFloat) -> some View {
        let stripeCount = 12
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
    
    // MARK: - Pitch markings (complete: touchline, center circle, penalty areas, 6-yard boxes, corner arcs, penalty spots)
    
    @ViewBuilder
    private func pitchMarkings(width: CGFloat, height: CGFloat) -> some View {
        let lineW: CGFloat = max(1, width / 200) // Scales with pitch size
        let lineColor = Color.white.opacity(0.4)
        
        ZStack {
            // Touchline (outer border)
            RoundedRectangle(cornerRadius: 0)
                .stroke(lineColor, lineWidth: lineW * 1.5)
            
            // Halfway line
            Rectangle()
                .fill(lineColor)
                .frame(width: width, height: lineW)
                .position(x: width / 2, y: height / 2)
            
            // Center circle
            Circle()
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.2, height: width * 0.2)
                .position(x: width / 2, y: height / 2)
            
            // Center spot
            Circle()
                .fill(lineColor)
                .frame(width: lineW * 2, height: lineW * 2)
                .position(x: width / 2, y: height / 2)
            
            // --- TOP HALF (attacking end) ---
            
            // Penalty area top
            GeometryReader { _ in
                Rectangle()
                    .stroke(lineColor, lineWidth: lineW)
                    .frame(width: width * 0.5, height: height * 0.13)
                    .position(x: width / 2, y: height * 0.065)
            }
            
            // 6-yard/goal area top
            GeometryReader { _ in
                Rectangle()
                    .stroke(lineColor, lineWidth: lineW)
                    .frame(width: width * 0.25, height: height * 0.06)
                    .position(x: width / 2, y: height * 0.03)
            }
            
            // Penalty spot top
            Circle()
                .fill(lineColor)
                .frame(width: lineW * 1.5, height: lineW * 1.5)
                .position(x: width / 2, y: height * 0.14)
            
            // Penalty arc top (outside of penalty area)
            ArcShape(startAngle: 180, endAngle: 360)
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.12, height: width * 0.06)
                .position(x: width / 2, y: height * 0.13)
            
            // Corner arcs top-left
            ArcShape(startAngle: 0, endAngle: 90)
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.04, height: width * 0.04)
                .position(x: width * 0.02, y: height * 0.02)
            
            // Corner arcs top-right
            ArcShape(startAngle: 270, endAngle: 360)
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.04, height: width * 0.04)
                .position(x: width * 0.98, y: height * 0.02)
            
            // --- BOTTOM HALF (defending end) ---
            
            // Penalty area bottom
            GeometryReader { _ in
                Rectangle()
                    .stroke(lineColor, lineWidth: lineW)
                    .frame(width: width * 0.5, height: height * 0.13)
                    .position(x: width / 2, y: height * 0.935)
            }
            
            // 6-yard/goal area bottom
            GeometryReader { _ in
                Rectangle()
                    .stroke(lineColor, lineWidth: lineW)
                    .frame(width: width * 0.25, height: height * 0.06)
                    .position(x: width / 2, y: height * 0.97)
            }
            
            // Penalty spot bottom
            Circle()
                .fill(lineColor)
                .frame(width: lineW * 1.5, height: lineW * 1.5)
                .position(x: width / 2, y: height * 0.86)
            
            // Penalty arc bottom (inside of penalty area)
            ArcShape(startAngle: 0, endAngle: 180)
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.12, height: width * 0.06)
                .position(x: width / 2, y: height * 0.87)
            
            // Corner arcs bottom-left
            ArcShape(startAngle: 90, endAngle: 180)
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.04, height: width * 0.04)
                .position(x: width * 0.02, y: height * 0.98)
            
            // Corner arcs bottom-right
            ArcShape(startAngle: 180, endAngle: 270)
                .stroke(lineColor, lineWidth: lineW)
                .frame(width: width * 0.04, height: width * 0.04)
                .position(x: width * 0.98, y: height * 0.98)
        }
    }
    
    // MARK: - Player overlay
    
    @ViewBuilder
    private func playerOverlay(width: CGFloat, height: CGFloat) -> some View {
        // Offset players to sit within the pitch area (inside touchlines)
        let playerMargin: CGFloat = 20
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
                        isViceCaptain: isViceCaptain
                    )
                }
            }
        }
    }
}

// MARK: - Arc Shape for corner arcs and penalty arcs

private struct ArcShape: Shape {
    let startAngle: Double
    let endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
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
    
    var body: some View {
        VStack(spacing: 1) {
            // Jersey icon with captain badge
            ZStack(alignment: .topTrailing) {
                JerseyIconView(teamId: player.player.teamId, teamName: player.teamName, size: 32)
                    .frame(width: 36, height: 36)
                
                if isCaptain {
                    Text("C")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black)
                        .padding(2)
                        .background(Color.yellow)
                        .clipShape(Circle())
                } else if isViceCaptain {
                    Text("VC")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.black)
                        .padding(2)
                        .background(Color.gray)
                        .clipShape(Capsule())
                }
            }
            
            // Player name
            Text(player.name)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(maxWidth: 52)
            
            // Club name
            Text(player.teamName)
                .font(.system(size: 6))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(maxWidth: 42)
            
            // Points + Price
            HStack(spacing: 3) {
                Text(String(format: "%.0f", player.gwPoints ?? 0))
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.green)
                
                Text(String(format: "%.1fm", player.purchasePrice))
                    .font(.system(size: 6))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .position(
            x: offsetX + containerWidth * positionX,
            y: offsetY + containerHeight * positionY
        )
    }
}

// MARK: - Bench Section

struct BenchSection: View {
    let players: [SquadPlayer]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BENCH")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if players.isEmpty {
                        Text("No bench players")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    ForEach(players) { player in
                        BenchPlayerCard(player: player)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .cornerRadius(12)
    }
}

struct BenchPlayerCard: View {
    let player: SquadPlayer
    
    var body: some View {
        VStack(spacing: 4) {
            Text("SUB")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary)
            
            JerseyIconView(teamId: player.player.teamId, teamName: player.teamName, size: 24)
                .frame(width: 28, height: 28)
            
            Text(player.name)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: 50)
            
            Text(player.teamName)
                .font(.system(size: 6))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 40)
            
            HStack(spacing: 3) {
                Text(String(format: "%.0f", player.gwPoints ?? 0))
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.green)
                
                Text(String(format: "%.1fm", player.purchasePrice))
                    .font(.system(size: 6))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 58)
        .padding(.vertical, 6)
        .background(Color(red: 0.12, green: 0.12, blue: 0.18))
        .cornerRadius(8)
    }
}
