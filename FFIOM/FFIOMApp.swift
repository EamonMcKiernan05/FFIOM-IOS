import SwiftUI

@main
struct FFIOMApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .onAppear {
                        Task {
                            await authManager.refreshSession()
                        }
                    }
            } else {
                AuthView()
            }
        }
    }
}
