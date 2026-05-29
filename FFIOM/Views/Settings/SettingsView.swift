import SwiftUI

struct SettingsView: View {
    @StateObject private var authManager = AuthManager()
    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let u = authManager.currentUser {
                        LabeledContent("Username", value: u.username)
                        LabeledContent("Points", value: String(format: "%.0f", u.totalPoints))
                        if let e = u.email { LabeledContent("Email", value: e) }
                    }
                }
                Section("App") {
                    NavigationLink("Dream Team") { DreamTeamView() }
                    NavigationLink("Rankings") { RankingsView() }
                    NavigationLink("Leagues") { LeaguesView(appState: AppStateManager()) }
                    NavigationLink("Help & Rules") { HelpView() }
                }
                Section { Button("Sign Out", role: .destructive) { authManager.logout() } }
            }
            .navigationTitle("Settings")
        }
    }
}
