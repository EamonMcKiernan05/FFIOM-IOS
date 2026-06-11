import Foundation

/// Authentication manager — handles login, register, logout, and session refresh.
/// Uses KeychainService for secure token storage.
@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared
    private let keychain = KeychainService()

    init() {
        // Check for existing auth token on init
        if let _ = keychain.getString(forKey: "authToken") {
            isAuthenticated = true
        }
    }

    // MARK: - Login

    func login(username: String, password: String) async -> Bool {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a username"
            isLoading = false
            return false
        }
        guard !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a password"
            isLoading = false
            return false
        }
        isLoading = true
        errorMessage = nil

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

    // MARK: - Register

    func register(username: String, password: String, email: String) async -> Bool {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a username"
            isLoading = false
            return false
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter a password"
            isLoading = false
            return false
        }
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a valid email"
            isLoading = false
            return false
        }
        isLoading = true
        errorMessage = nil

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

    // MARK: - Logout

    func logout() {
        api.logout()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Session

    func refreshSession() async -> Bool {
        let valid = await api.refreshSession()
        isAuthenticated = valid
        if valid {
            do {
                currentUser = try await api.fetchMyStats()
            } catch {
                // Non-fatal — user stats will be loaded by AppStateManager
            }
        }
        return valid
    }
}
