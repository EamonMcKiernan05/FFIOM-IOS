import Foundation

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let api = APIService.shared

    init() {
        let token = UserDefaults.standard.string(forKey: "authToken")
        isAuthenticated = token != nil && (token?.isEmpty ?? true) == false
    }

    func login(username: String, password: String) async -> Bool {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a username"; isLoading = false; return false
        }
        guard !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a password"; isLoading = false; return false
        }
        isLoading = true; errorMessage = nil
        do {
            let resp: AuthResponse = try await api.login(username: username, password: password)
            currentUser = User(
                id: resp.user.id,
                username: resp.user.username,
                email: resp.user.email,
                displayName: resp.user.displayName,
                emailVerified: resp.user.emailVerified,
                createdAt: resp.user.createdAt,
                totalPoints: 0,
                budget: 90.0,
                transfersRemaining: 1,
                rank: nil
            )
            isAuthenticated = true
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func register(username: String, password: String, email: String) async -> Bool {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a username"; isLoading = false; return false
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter a password"; isLoading = false; return false
        }
        isLoading = true; errorMessage = nil
        do {
            let resp: AuthResponse = try await api.register(username: username, password: password, email: email)
            currentUser = User(
                id: resp.user.id,
                username: resp.user.username,
                email: resp.user.email,
                displayName: resp.user.displayName,
                emailVerified: resp.user.emailVerified,
                createdAt: resp.user.createdAt,
                totalPoints: 0,
                budget: 90.0,
                transfersRemaining: 1,
                rank: nil
            )
            isAuthenticated = true
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func logout() {
        api.logout()
        currentUser = nil
        isAuthenticated = false
    }

    func refreshSession() async {
        let valid = await api.refreshSession(); isAuthenticated = valid
        if valid { do { currentUser = try await api.fetchMyStats() } catch {} }
    }
}
