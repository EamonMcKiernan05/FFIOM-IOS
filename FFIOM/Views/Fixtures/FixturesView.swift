import SwiftUI

struct FixturesView: View {
    @ObservedObject var appState: AppStateManager
    
    var currentGW: Int {
        appState.gameweek?.displayNumber ?? (appState.gameweeksList.first?.id ?? 0)
    }
    
    var body: some View {
        List {
            // Group fixtures by gameweek
            ForEach(gameweekGroups, id: \.gwId) { group in
                Section(group.title) {
                    ForEach(group.fixtures) { fixture in
                        GWFixtureRowView(fixture: fixture)
                    }
                }
            }
        }
        .navigationTitle("Fixtures")
        .refreshable { await appState.refreshFixtures() }
    }
    
    private var gameweekGroups: [(gwId: Int, title: String, fixtures: [Fixture])] {
        let gwFixtures = Dictionary(grouping: appState.fixtures) { $0.gameweekId }
        var groups: [(Int, String, [Fixture])] = []
        
        for gwId in gwFixtures.keys.sorted() {
            let fixtures = gwFixtures[gwId] ?? []
            let finishedCount = fixtures.filter { $0.isFinished }.count
            let totalCount = fixtures.count
            let status = finishedCount == totalCount ? "✓" : finishedCount > 0 ? "◐" : "○"
            groups.append((gwId, "GW \(gwId) \(status)", fixtures.sorted { $0.date ?? "" < $1.date ?? "" }))
        }
        
        return groups
    }
}

struct GWFixtureRowView: View {
    let fixture: Fixture
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(fixture.homeTeam)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if fixture.isFinished {
                    Text("\(fixture.homeScore ?? 0)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                if fixture.isFinished {
                    Text(fixture.scoreString)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                } else {
                    Text(fixture.timeString)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(4)
                }
                Text(fixture.dateFormatted)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(fixture.awayTeam)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if fixture.isFinished {
                    Text("\(fixture.awayScore ?? 0)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
