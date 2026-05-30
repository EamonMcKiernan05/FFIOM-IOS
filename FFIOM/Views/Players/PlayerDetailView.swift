import SwiftUI

struct PlayerDetailView: View {
    let player: Player
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Player header
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.15, green: 0.45, blue: 0.8))
                            .frame(width: 60, height: 60)
                        Text(player.name.prefix(1).uppercased())
                            .font(.title.bold())
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.name)
                            .font(.title2.bold())
                        Text(player.teamName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
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
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Player")
    }
}

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
