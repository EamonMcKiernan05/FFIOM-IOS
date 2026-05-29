import SwiftUI

struct FixtureRow: View {
    let fixture: Fixture
    var body: some View {
        HStack(spacing: 12) {
            Text(fixture.homeTeam).font(.subheadline).lineLimit(1).frame(maxWidth: .infinity, alignment: .trailing)
            Text(fixture.scoreString).font(.headline.monospacedDigit()).frame(width: 60)
                .padding(.vertical, 4).background(fixture.isFinished ? Color.green.opacity(0.2) : Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            Text(fixture.awayTeam).font(.subheadline).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }
}
