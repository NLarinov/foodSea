import Foundation

final class RealAuthService: AuthServiceProtocol, @unchecked Sendable {
    private let client: NetworkClient
    private let tokenStore: AuthTokenStore

    init(client: NetworkClient, tokenStore: AuthTokenStore) {
        self.client = client
        self.tokenStore = tokenStore
    }

    var isLoggedIn: Bool { tokenStore.hasToken }

    func register(email: String, password: String) async throws {
        let response: AuthResponseDTO = try await client.request(.register(email: email, password: password))
        tokenStore.save(access: response.accessToken, refresh: response.refreshToken)
    }

    func login(email: String, password: String) async throws {
        let response: AuthResponseDTO = try await client.request(.login(email: email, password: password))
        tokenStore.save(access: response.accessToken, refresh: response.refreshToken)
    }

    func logout() async throws {
        try? await client.requestEmpty(.logout)
        tokenStore.clear()
        await MainActor.run {
            NotificationCenter.default.post(name: .sessionExpired, object: nil)
        }
    }
}
