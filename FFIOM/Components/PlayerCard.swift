import SwiftUI

struct PlayerCard: View {
    let player: Player
    var showPoints: Bool = true
    var showPrice: Bool = false
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(player.positionColor).frame(width: 40, height: 40)
                Text(player.positionBadge).font(.caption.bold()).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(player.name).font(.subheadline.bold()).lineLimit(1)
                    if player.isCaptain { Image(systemName: "c.circle.fill").foregroundColor(.yellow).font(.caption) }
                    else if player.isViceCaptain { Image(systemName: "v.circle.fill").foregroundColor(.gray).font(.caption) }
                }
                Text(player.teamName).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if showPoints {
                VStack(alignment: .trailing, spacing: 2) {
                    if let gp = player.gwPoints {
                        Text(String(format: "%.0f", gp)).font(.title3.bold())
                            .foregroundColor(gp > 0 ? .green : .gray)
                    }
                    Text(String(format: "%.0f total", player.totalPoints)).font(.caption2).foregroundColor(.secondary)
                }
            } else if showPrice {
                Text(player.formattedPrice).font(.subheadline.bold()).foregroundColor(.green)
            }
        }
        .padding(12).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onTapGesture { onTap?() }
    }
}
