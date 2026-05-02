import Foundation

final class RealAuthService: AuthServiceProtocol, @unchecked Sendable {
    private let client: NetworkClient
    private let tokenStore: AuthTokenStore
    private let oauthService: OAuthServiceProtocol

    init(client: NetworkClient, tokenStore: AuthTokenStore, oauthService: OAuthServiceProtocol) {
        self.client = client
        self.tokenStore = tokenStore
        self.oauthService = oauthService
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

    func signInWithGoogle() async throws {
        let response = try await oauthService.signInWithGoogle()
        tokenStore.save(access: response.accessToken, refresh: response.refreshToken)
    }

    func signInWithYandex() async throws {
        let response = try await oauthService.signInWithYandex()
        tokenStore.save(access: response.accessToken, refresh: response.refreshToken)
    }

    func signInWithApple() async throws {
        let response = try await oauthService.signInWithApple()
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
