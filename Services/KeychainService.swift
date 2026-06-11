import Foundation
import Security

/// Secure credential storage using iOS Keychain.
/// Falls back to UserDefaults in the simulator where Keychain API is unreliable.
///
/// Keys managed:
/// - `authToken` — JWT access token
/// - `refreshToken` — JWT refresh token
/// - `userId` — Current user ID
/// - `teamId` — Current team ID
/// - `username` — Current username
class KeychainService {
    static let shared = KeychainService()

    private let service = "com.ffiom.app"

    private init() {}

    // MARK: - String operations

    func setString(_ value: String, forKey key: String) {
        #if targetEnvironment(simulator)
        // Keychain API unreliable in simulator — use UserDefaults
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
        #else
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        #endif
    }

    func getString(forKey key: String) -> String? {
        #if targetEnvironment(simulator)
        return UserDefaults.standard.string(forKey: key)
        #else
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
        #endif
    }

    // MARK: - Integer operations

    func setInt(_ value: Int, forKey key: String) {
        setString("\(value)", forKey: key)
    }

    func getInt(forKey key: String) -> Int? {
        guard let str = getString(forKey: key) else { return nil }
        return Int(str)
    }

    // MARK: - Removal

    func remove(_ key: String) {
        #if targetEnvironment(simulator)
        UserDefaults.standard.removeObject(forKey: key)
        #else
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        #endif
    }

    /// Remove all FFIOM credentials from Keychain.
    func removeAll() {
        remove("authToken")
        remove("refreshToken")
        remove("userId")
        remove("teamId")
        remove("username")
    }
}
