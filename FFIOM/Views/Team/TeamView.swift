import SwiftUI

// MARK: - Team View - Pitch Layout
// Green football pitch with players in 3-4-3 formation (no goalkeeper)
// 10 outfield players on pitch + bench players underneath

struct TeamView: View {
    @ObservedObject var appState: AppStateManager
    
    private let formationPositions: [(x: CGFloat, y: CGFloat)] = [
        // 3 Forwards (top of pitch = attacking end)
        (x: 0.50, y: 0.06),   // Center forward
        (x: 0.25, y: 0.14),  // Left forward
        (x: 0.75, y: 0.14),  // Right forward
        // 4 Midfielders
        (x: 0.15, y: 0.34),  // Left midfield
        (x: 0.36, y: 0.32),  // Center-left midfield
        (x: 0.64, y: 0.32),  // Center-right midfield
        (x: 0.85, y: 0.34),  // Right midfield
        // 3 Defenders
        (x: 0.20, y: 0.58),  // Left back
        (x: 0.50, y: 0.56),  // Center back
        (x: 0.80, y: 0.58),  // Right back
    ]
    
    var startingPlayers: [SquadPlayer] {
        appState.myTeam.filter { $0.isStarting }.prefix(10).map { $0 }
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
                        .padding(.horizontal, 12)
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

// MARK: - Pitch Container

struct PitchContainer: View {
    let geo: GeometryProxy
    let players: [SquadPlayer]
    let positions: [(x: CGFloat, y: CGFloat)]
    let captainId: Int?
    let viceCaptainId: Int?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            pitchBackground(in: geo)
            
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                if index < positions.count {
                    let pos = positions[index]
                    let isCaptain = player.id == captainId
                    let isViceCaptain = player.id == viceCaptainId
                    
                    PitchPlayerNode(
                        player: player,
                        positionX: pos.x,
                        positionY: pos.y,
                        containerWidth: geo.size.width,
                        containerHeight: geo.size.height,
                        isCaptain: isCaptain,
                        isViceCaptain: isViceCaptain
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func pitchBackground(in geo: GeometryProxy) -> some View {
        let w = geo.size.width
        let h = geo.size.height
        ZStack {
            // Base green with mowing stripe pattern
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.40, blue: 0.19),
                    Color(red: 0.11, green: 0.46, blue: 0.22),
                    Color(red: 0.08, green: 0.38, blue: 0.17),
                    Color(red: 0.11, green: 0.46, blue: 0.22),
                    Color(red: 0.09, green: 0.40, blue: 0.19),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Center circle
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                .frame(width: w * 0.22, height: w * 0.22)
            
            // Center line
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: w, height: 1.5)
                .position(x: w / 2, y: h / 2)
            
            // Penalty box top
            Rectangle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                .frame(width: w * 0.5, height: h * 0.12)
                .position(x: w / 2, y: h * 0.06)
            
            // Goal area top
            Rectangle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                .frame(width: w * 0.25, height: h * 0.06)
                .position(x: w / 2, y: h * 0.03)
            
            // Penalty box bottom
            Rectangle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                .frame(width: w * 0.5, height: h * 0.12)
                .position(x: w / 2, y: h * 0.94)
            
            // Goal area bottom
            Rectangle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                .frame(width: w * 0.25, height: h * 0.06)
                .position(x: w / 2, y: h * 0.97)
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
            x: containerWidth * positionX,
            y: containerHeight * positionY
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
