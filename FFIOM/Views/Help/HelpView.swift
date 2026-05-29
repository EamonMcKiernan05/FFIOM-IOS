import SwiftUI

struct HelpView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ruleSection(title: "Squad Rules", items: ["£90 million budget cap", "13 players: 10 starters + 3 bench", "No position restrictions", "Max 3 from any club"])
                    ruleSection(title: "Points Scoring", items: ["Playing up to 60 min: +1", "Playing 60+ min: +2", "Goal: +4", "Clean sheet: +4", "Yellow card: -1", "Red card: -3", "Own goal: -1"])
                    ruleSection(title: "Chips", items: ["Wildcard: Unlimited transfers (1x/season)", "Free Hit: One-off squad change", "Bench Boost: All 13 count (1x/half)", "Triple Captain: 3x captain points (1x/half)"])
                    ruleSection(title: "Transfers", items: ["1 free per gameweek", "Rollover max 4", "Extra cost -4 points"])
                    ruleSection(title: "Bonus Points", items: ["Top 3 per match: 3/2/1 BPS"])
                    ruleSection(title: "Captain", items: ["Captain: 2x points", "Vice-captain: replaces if captain doesn't play"])
                }
                .padding()
            }
            .navigationTitle("Rules & Scoring")
        }
    }
    func ruleSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title3.bold())
            ForEach(items, id: \.self) { i in HStack(spacing: 8) { Text("\u{2022}"); Text(i).font(.subheadline) } }
        }
    }
}
