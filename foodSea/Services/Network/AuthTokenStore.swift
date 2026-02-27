import Foundation
import Security

final class AuthTokenStore: Sendable {
    private let accessKey = "foodsea.access_token"
    private let refreshKey = "foodsea.refresh_token"

    var accessToken: String? { read(key: accessKey) }
    var refreshToken: String? { read(key: refreshKey) }
    var hasToken: Bool { accessToken != nil }

    func save(access: String, refresh: String) {
        write(key: accessKey, value: access)
        write(key: refreshKey, value: refresh)
    }

    func clear() {
        delete(key: accessKey)
        delete(key: refreshKey)
    }

    private func read(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func write(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
