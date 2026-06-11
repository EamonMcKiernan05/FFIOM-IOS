import SwiftUI

/// Detailed player stats view with JerseyIconView rendering.
struct PlayerDetailView: View {
    let player: Player
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Player header
                HStack(spacing: 16) {
                    JerseyIconView(teamId: player.team?.id, teamName: player.teamName, size: 60)
                        .frame(width: 66, height: 66)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.name)
                            .font(.title2.bold())
                        Text(player.teamName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1fm", player.price))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
                
                // Season stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Season Stats")
                        .font(.headline)
                    StatsGrid(
                        stats: [
                            ("Total Points", String(Int(player.totalPoints))),
                            ("Goals", "\(player.goals)"),
                            ("Assists", "\(player.assists)"),
                            ("Appearances", "\(player.apps)"),
                            ("Clean Sheets", "\(player.cleanSheets)"),
                            ("Form", String(format: "%.1f", player.form)),
                        ]
                    )
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Price info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Value")
                        .font(.headline)
                    StatsGrid(
                        stats: [
                            ("Current Price", String(format: "%.1fm", player.price)),
                            ("Start Price", String(format: "%.1fm", player.priceStart)),
                            ("Selected By", String(format: "%.1f%%", player.selectedByPercent)),
                        ]
                    )
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Injuries
                if player.isInjured {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Injury Status")
                            .font(.headline)
                        Text(player.injuryStatus ?? "Injured")
                            .foregroundColor(.red)
                            .accessibilityLabel("Injured: \(player.injuryStatus ?? "Unknown injury")")
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(player.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Reusable stat grid for player detail and other views.
struct StatsGrid: View {
    let stats: [(String, String)]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(stats, id: \.0) { label, value in
                HStack {
                    Text(label)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(value)
                        .font(.subheadline.bold())
                }
            }
        }
    }
}
