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
                AuthView(authManager: authManager, onLoginSuccess: {
                    showAuth = false
                })
            } else {
                MainTabView(appState: appState, authManager: authManager)
            }
        }
        .task {
            // Check for existing auth token in Keychain
            let keychain = KeychainService()
            if let token = keychain.getString(forKey: "authToken"), !token.isEmpty {
                apiService.authToken = token
                apiService.refreshToken = keychain.getString(forKey: "refreshToken")
                apiService.currentUserId = keychain.getInt(forKey: "userId")
                apiService.currentTeamId = keychain.getInt(forKey: "teamId")

                let isValid = await authManager.refreshSession()
                if isValid {
                    showAuth = false
                } else {
                    apiService.logout()
                }
            }
            #if DEBUG
            // DEBUG: Auto-login for simulator testing when no valid token
            if showAuth {
                let testOk = await authManager.login(username: "ffiom_test_hermes", password: "HermesTest123!")
                if testOk {
                    showAuth = false
                }
            }
            #endif
        }
    }
}
