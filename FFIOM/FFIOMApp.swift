import SwiftUI

@main
struct FFIOMApp: App {
    var body: some Scene {
        WindowGroup {
            AppRouter()
        }
    }
}

struct AppRouter: View {
    @StateObject private var apiService = APIService.shared
    @StateObject private var appState = AppStateManager()
    @StateObject private var authManager = AuthManager()
    @State private var showAuth = false
    @State private var checkedInitial = false
    
    var body: some View {
        Group {
            if showAuth {
                AuthView()
            } else {
                MainTabView(appState: appState, authManager: authManager)
            }
        }
        .task {
            // Check initial auth state
            let token = UserDefaults.standard.string(forKey: "authToken")
            if let t = token, !t.isEmpty {
                apiService.authToken = t
                if let uid = UserDefaults.standard.string(forKey: "userId") {
                    apiService.currentUserId = Int(uid)
                }
                if let tid = UserDefaults.standard.string(forKey: "teamId") {
                    apiService.currentTeamId = Int(tid)
                }
                authManager.isAuthenticated = true
                showAuth = false
            } else {
                showAuth = true
            }
            checkedInitial = true
        }
        .onChange(of: authManager.isAuthenticated) { newValue in
            if newValue {
                showAuth = false
            } else if checkedInitial {
                showAuth = true
            }
        }
    }
}
