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
                    print("🔄 AppRouter: onLoginSuccess callback, setting showAuth=false")
                    showAuth = false
                })
            } else {
                MainTabView(appState: appState, authManager: authManager)
            }
        }
        .task {
            print("🔄 AppRouter.task: starting")
            
            
            if let token = UserDefaults.standard.string(forKey: "authToken"), !token.isEmpty {
                print("🔄 AppRouter.task: found saved token, validating...")
                apiService.authToken = token
                apiService.refreshToken = UserDefaults.standard.string(forKey: "refreshToken")
                if let uid = UserDefaults.standard.string(forKey: "userId") {
                    apiService.currentUserId = Int(uid)
                }
                if let tid = UserDefaults.standard.string(forKey: "teamId") {
                    apiService.currentTeamId = Int(tid)
                }
                
                let isValid = await authManager.refreshSession()
                print("🔄 AppRouter.task: refreshSession result = \(isValid)")
                if isValid {
                    showAuth = false
                } else {
                    print("🔄 AppRouter.task: token expired, clearing and showing login")
                    apiService.logout()
                    UserDefaults.standard.removeObject(forKey: "authToken")
                    UserDefaults.standard.removeObject(forKey: "refreshToken")
                    UserDefaults.standard.removeObject(forKey: "userId")
                    UserDefaults.standard.removeObject(forKey: "teamId")
                    UserDefaults.standard.removeObject(forKey: "username")
                    UserDefaults.standard.synchronize()
                }
            } else {
                print("🔄 AppRouter.task: no saved token, showing login")
            }
        }
    }
}
