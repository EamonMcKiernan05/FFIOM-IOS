import SwiftUI

struct MainTabView: View {
    @ObservedObject var appState: AppStateManager
    @ObservedObject var authManager: AuthManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(appState: appState)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            TeamView(appState: appState)
                .tabItem { Label("Team", systemImage: "person.3.fill") }
                .tag(1)
            TransfersView(appState: appState)
                .tabItem { Label("Transfers", systemImage: "arrow.left.arrow.right") }
                .tag(2)
            PlayersView(appState: appState)
                .tabItem { Label("Players", systemImage: "person.crop.circle.badge.plus") }
                .tag(3)
        }
        .task {
            await appState.loadAllData()
        }
        .onAppear {
            // Reload data when returning to foreground
            Task { await appState.loadAllData() }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Offline indicator
                if appState.errorMessage != nil {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .accessibilityLabel("Connection issue")
                }
                Button {
                    authManager.logout()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Sign out")
                }
            }
        }
        .overlay {
            // Show error banner
            if let error = appState.errorMessage {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.white)
                        Text(error)
                            .foregroundColor(.white)
                            .font(.caption)
                        Spacer()
                        Button("Dismiss") { appState.clearError() }
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.9))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.top, 60)
                    .accessibilityLabel("Error: \(error)")
                    Spacer()
                }
            }
        }
    }
}
