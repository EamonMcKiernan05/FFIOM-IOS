import SwiftUI

struct MainTabView: View {
    @ObservedObject var appState: AppStateManager
    @ObservedObject var authManager: AuthManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(appState: appState).tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            TeamView(appState: appState).tabItem { Label("Team", systemImage: "person.3.fill") }.tag(1)
            TransfersView(appState: appState).tabItem { Label("Transfers", systemImage: "arrow.left.arrow.right") }.tag(2)
            PlayersView(appState: appState).tabItem { Label("Players", systemImage: "person.crop.circle.badge.plus") }.tag(3)
            MoreView(appState: appState).tabItem { Label("More", systemImage: "ellipsis") }.tag(4)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    authManager.logout()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            Task {
                await appState.loadAllData()
            }
        }
    }
}

// More tab (catch-all for extra features)
struct MoreView: View {
    @ObservedObject var appState: AppStateManager
    @State private var showFixtures = false
    @State private var showLeaderboard = false
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: LeaderboardView(appState: appState)) {
                    Label("Table", systemImage: "list.bullet")
                }
                NavigationLink(destination: FixturesView(appState: appState)) {
                    Label("Fixtures", systemImage: "calendar")
                }
            }
            .navigationTitle("More")
        }
    }
}
