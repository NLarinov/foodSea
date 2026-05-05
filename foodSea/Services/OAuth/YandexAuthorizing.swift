import Foundation

protocol YandexAuthorizing: Sendable {
    func requestAccessToken() async throws -> String
}

final class StubYandexAuthorizer: YandexAuthorizing, @unchecked Sendable {
    func requestAccessToken() async throws -> String {
        throw OAuthError.providerNetworkFailure
    }
}
