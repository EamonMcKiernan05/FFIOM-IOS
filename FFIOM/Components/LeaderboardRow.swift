import SwiftUI

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.8))
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.subheadline.bold())
                if let teamName = entry.teamName {
                    Text(teamName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text("\(Int(entry.totalPoints))")
                .font(.title3.bold())
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
    
    private var rankColor: Color {
        if rank == 1 { return Color(red: 0.9, green: 0.7, blue: 0.1) }
        if rank == 2 { return Color(red: 0.5, green: 0.55, blue: 0.65) }
        if rank == 3 { return Color(red: 0.75, green: 0.5, blue: 0.25) }
        return Color.gray
    }
}
