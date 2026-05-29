import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppStateManager()
    @StateObject private var authManager = AuthManager()
    @State private var selectedTab = 0
    @State private var showNotifications = false
    
    var unreadCount: Int { appState.notifications.filter { !$0.isRead }.count }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(appState: appState).tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            TeamView(appState: appState).tabItem { Label("Team", systemImage: "person.3.fill") }.tag(1)
            TransfersView(appState: appState).tabItem { Label("Transfers", systemImage: "arrow.left.arrow.right") }.tag(2)
            PlayersView(appState: appState).tabItem { Label("Players", systemImage: "person.crop.circle.badge.plus") }.tag(3)
            FixturesView(appState: appState).tabItem { Label("Fixtures", systemImage: "calendar") }.tag(4)
            LeaderboardView(appState: appState).tabItem { Label("Table", systemImage: "list.bullet") }.tag(5)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showNotifications.toggle() } label: {
                    Image(systemName: "bell").overlay(alignment: .topTrailing) {
                        if unreadCount > 0 {
                            Text("\(unreadCount)").font(.caption2).foregroundColor(.white)
                                .padding(3).background(Color.red, in: Circle())
                        }
                    }
                }
                .sheet(isPresented: $showNotifications) { NotificationsView(appState: appState) }
                Button { authManager.logout() } label: { Image(systemName: "gearshape.fill") }
            }
        }
        .onAppear { Task { await appState.loadAllData() } }
    }
}
