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
    @State private var showAuth = true
    
    var body: some View {
        Group {
            if showAuth {
                AuthView(authManager: authManager)
            } else {
                MainTabView(appState: appState, authManager: authManager)
            }
        }
        .task {
            // Restore saved token if present
            if let token = UserDefaults.standard.string(forKey: "authToken"), !token.isEmpty {
                apiService.authToken = token
                if let uid = UserDefaults.standard.string(forKey: "userId") {
                    apiService.currentUserId = Int(uid)
                }
                if let tid = UserDefaults.standard.string(forKey: "teamId") {
                    apiService.currentTeamId = Int(tid)
                }
                
                // Validate token is still alive before skipping login
                let isValid = await apiService.refreshSession()
                if isValid {
                    authManager.isAuthenticated = true
                    showAuth = false
                }
                // If expired, showAuth stays true → shows login screen
            }
        }
        .onChange(of: authManager.isAuthenticated) { newValue in
            if newValue {
                showAuth = false
            }
        }
    }
}
