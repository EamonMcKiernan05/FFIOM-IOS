import Foundation

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let api = APIService.shared
    private let keychain = KeychainService()
    
    init() { self.isAuthenticated = keychain.getString(forKey: "authToken") != nil }
    
    func login(username: String, password: String) async -> Bool {
        isLoading = true; errorMessage = nil
        do {
            let resp = try await api.login(username: username, password: password)
            currentUser = resp.user; isAuthenticated = true; isLoading = false; return true
        } catch { errorMessage = error.localizedDescription; isLoading = false; return false }
    }
    func register(username: String, password: String, email: String? = nil) async -> Bool {
        isLoading = true; errorMessage = nil
        do {
            let resp = try await api.register(username: username, password: password, email: email)
            currentUser = resp.user; isAuthenticated = true; isLoading = false; return true
        } catch { errorMessage = error.localizedDescription; isLoading = false; return false }
    }
    func logout() { api.logout(); currentUser = nil; isAuthenticated = false }
    func refreshSession() async {
        let valid = await api.refreshSession(); isAuthenticated = valid
        if valid { do { currentUser = try await api.fetchMyStats() } catch {} }
    }
}
