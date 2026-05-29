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
    @State private var showAuth = true
    @State private var checkedInitial = false
    
    var body: some View {
        Group {
            if showAuth {
                AuthView()
            } else {
                MainTabView()
            }
        }
        .task {
            // Check initial auth state
            let token = UserDefaults.standard.string(forKey: "authToken")
            if let t = token, !t.isEmpty, !checkedInitial {
                apiService.authToken = t
                if let uid = UserDefaults.standard.string(forKey: "userId") {
                    apiService.currentUserId = Int(uid)
                }
                if let tid = UserDefaults.standard.string(forKey: "teamId") {
                    apiService.currentTeamId = Int(tid)
                }
                showAuth = false
            }
            checkedInitial = true
        }
        .onChange(of: apiService.authToken) { newValue in
            if let t = newValue, !t.isEmpty {
                showAuth = false
            } else if checkedInitial {
                showAuth = true
            }
        }
    }
}
