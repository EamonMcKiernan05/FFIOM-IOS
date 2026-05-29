import SwiftUI

struct LeaderboardRow: View {
    let entry: LeaderboardEntry; let isMe: Bool
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(entry.rank)").font(.headline).foregroundColor(isMe ? .green : .primary).frame(width: 40, alignment: .leading)
            Circle().fill(isMe ? .green : Color.gray.opacity(0.3)).frame(width: 32, height: 32)
                .overlay(Text(String(entry.username.prefix(1)).uppercased()).font(.caption.bold()).foregroundColor(.white))
            Text(entry.username).font(.subheadline).fontWeight(isMe ? .bold : .regular).lineLimit(1)
            Spacer()
            Text(String(format: "%.0f", entry.totalPoints)).font(.headline).foregroundColor(isMe ? .green : .primary)
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(isMe ? Color.green.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
    }
}
