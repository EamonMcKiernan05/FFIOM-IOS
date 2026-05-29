import SwiftUI

struct GameweekBanner: View {
    let gameweek: Gameweek?
    var body: some View {
        if let gw = gameweek {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(gw.name).font(.headline).foregroundColor(.white)
                    if let dl = gw.deadline { Text(dl).font(.caption).foregroundColor(.white.opacity(0.8)) }
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(gw.statusColor).frame(width: 8, height: 8)
                    Text(gw.statusDisplay).font(.caption.bold()).foregroundColor(.white)
                }
            }
            .padding()
            .background(LinearGradient(colors: [Color.green.opacity(0.8), Color.blue.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(12)
        } else { ProgressView().padding() }
    }
}
