import SwiftUI

struct FixturesView: View {
    @ObservedObject var appState: AppStateManager
    var byGW: [[Fixture]] {
        var g: [Int: [Fixture]] = [:]
        for f in appState.fixtures { g[f.gameweek, default: []].append(f) }
        return g.sorted { $0.key < $1.key }.map { $0.value }
    }
    var body: some View {
        NavigationStack {
            List {
                if byGW.isEmpty { EmptyState(icon: "calendar", title: "No Fixtures", message: "Fixtures will appear here when available.") }
                ForEach(byGW, id: \.self) { wf in
                    let gw = wf.first?.gameweek ?? 0
                    Section("Gameweek \(gw)") { ForEach(wf) { f in FixtureRow(fixture: f) } }
                }
            }
            .navigationTitle("Fixtures")
            .refreshable { await appState.refreshFixtures() }
        }
    }
}
