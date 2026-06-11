import SwiftUI

/// Settings view — account info, navigation shortcuts, and sign out.
/// Receives AuthManager as @ObservedObject (not a separate instance).
struct SettingsView: View {
    @ObservedObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let u = authManager.currentUser {
                        LabeledContent("Username", value: u.username)
                            .accessibilityLabel("Username: \(u.username)")
                        LabeledContent("Points", value: String(Int(u.totalPoints)))
                            .accessibilityLabel("Total points: \(Int(u.totalPoints))")
                        if let e = u.email {
                            LabeledContent("Email", value: e)
                                .accessibilityLabel("Email: \(e)")
                        }
                    } else {
                        Text("Not logged in")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("App") {
                    NavigationLink("Dream Team") {
                        DreamTeamView()
                    }
                    .accessibilityLabel("Navigate to Dream Team")
                    NavigationLink("Rankings") {
                        RankingsView()
                    }
                    .accessibilityLabel("Navigate to Rankings")
                    NavigationLink("Leagues") {
                        LeaguesView(appState: AppStateManager())
                    }
                    .accessibilityLabel("Navigate to Leagues")
                    NavigationLink("Help & Rules") {
                        HelpView()
                    }
                    .accessibilityLabel("Navigate to Help and Rules")
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        authManager.logout()
                    }
                    .accessibilityLabel("Sign out of your account")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
