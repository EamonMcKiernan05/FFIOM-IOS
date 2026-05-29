import SwiftUI

struct DreamTeamView: View {
    @State private var players: [Player] = []
    var body: some View {
        NavigationStack {
            List { Section("Dream Team") { ForEach(players) { p in PlayerCard(player: p, showPoints: true, showPrice: true) } } }
            .navigationTitle("Dream Team")
            .onAppear { Task { do { players = try await APIService.shared.fetchDreamTeam() } catch {} } }
        }
    }
}
