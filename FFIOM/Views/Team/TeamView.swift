import SwiftUI

// MARK: - Team View - Pitch Layout
// Green football pitch with players in 3-4-3 formation (no goalkeeper)
// 10 outfield players on pitch + bench players underneath

struct TeamView: View {
    @ObservedObject var appState: AppStateManager
    
    // 3-4-3 formation positions (percentage from top/left)
    // Y=0 is attacking end (top), Y=100 is defensive end (bottom)
    private let formationPositions: [(x: Double, y: Double)] = [
        // 3 Forwards
        (x: 50, y: 6),   // Center forward
        (x: 25, y: 14),  // Left forward
        (x: 75, y: 14),  // Right forward
        // 4 Midfielders
        (x: 15, y: 34),  // Left midfield
        (x: 36, y: 32),  // Center-left midfield
        (x: 64, y: 32),  // Center-right midfield
        (x: 85, y: 34),  // Right midfield
        // 3 Defenders
        (x: 20, y: 56),  // Left back
        (x: 50, y: 54),  // Center back
        (x: 80, y: 56),  // Right back
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
                        PitchContainer(
                            players: startingPlayers,
                            positions: formationPositions,
                            captainId: appState.myTeam.first(where: { $0.isCaptain })?.id,
                            viceCaptainId: appState.myTeam.first(where: { $0.isViceCaptain })?.id
                        )
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
    let players: [SquadPlayer]
    let positions: [(x: Double, y: Double)]
    let captainId: Int?
    let viceCaptainId: Int?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Green pitch with mowing stripes
            PitchBackground()
            
            // Players positioned on pitch
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                if index < positions.count {
                    let pos = positions[index]
                    let isCaptain = player.id == captainId
                    let isViceCaptain = player.id == viceCaptainId
                    
                    PitchPlayerNode(
                        player: player,
                        positionX: pos.x,
                        positionY: pos.y,
                        isCaptain: isCaptain,
                        isViceCaptain: isViceCaptain
                    )
                }
            }
        }
    }
}

// MARK: - Pitch Background

struct PitchBackground: View {
    var body: some View {
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
                .frame(width: 80, height: 80)
                .position(x: UIScreen.main.bounds.width / 2 - 6, y: 200)
            
            // Center line
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1.5)
                .padding(.horizontal, 12)
                .offset(y: 200)
            
            // Penalty box top
            Rectangle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                .frame(width: UIScreen.main.bounds.width * 0.55, height: 60)
                .offset(y: -170)
            
            // Penalty box bottom
            Rectangle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                .frame(width: UIScreen.main.bounds.width * 0.55, height: 60)
                .offset(y: 170)
        }
        .aspectRatio(3 / 4, contentMode: .fit)
    }
}

// MARK: - Player on Pitch

struct PitchPlayerNode: View {
    let player: SquadPlayer
    let positionX: Double
    let positionY: Double
    let isCaptain: Bool
    let isViceCaptain: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            // Jersey icon with captain badge
            ZStack(alignment: .topTrailing) {
                JerseyIconView(teamId: player.player.teamId, teamName: player.teamName, size: 36)
                    .frame(width: 42, height: 42)
                    .background(Color.black.opacity(0.2))
                    .clipShape(Circle())
                
                if isCaptain {
                    Text("C")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .padding(3)
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
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(maxWidth: 60)
            
            // Club name
            Text(player.teamName)
                .font(.system(size: 7))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(maxWidth: 50)
            
            // Points + Price
            HStack(spacing: 4) {
                Text(String(format: "%.0f", player.gwPoints ?? 0))
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.green)
                
                Text(String(format: "%.1fm", player.purchasePrice))
                    .font(.system(size: 7))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .position(
            x: UIScreen.main.bounds.width * (positionX / 100),
            y: 400 * (positionY / 100)
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
            
            JerseyIconView(teamId: player.player.teamId, teamName: player.teamName, size: 28)
                .frame(width: 34, height: 34)
            
            Text(player.name)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: 55)
            
            Text(player.teamName)
                .font(.system(size: 7))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 45)
            
            HStack(spacing: 3) {
                Text(String(format: "%.0f", player.gwPoints ?? 0))
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.green)
                
                Text(String(format: "%.1fm", player.purchasePrice))
                    .font(.system(size: 7))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 65)
        .padding(.vertical, 6)
        .background(Color(red: 0.12, green: 0.12, blue: 0.18))
        .cornerRadius(8)
    }
}
