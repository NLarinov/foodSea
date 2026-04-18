import Foundation

final class MockOAuthService: OAuthServiceProtocol, @unchecked Sendable {
    func signInWithGoogle() async throws -> AuthResponseDTO {
        try await Task.sleep(nanoseconds: Constants.Mock.mediumDelay)
        return Self.makeStubResponse(email: "google.user@example.com")
    }

    func signInWithYandex() async throws -> AuthResponseDTO {
        try await Task.sleep(nanoseconds: Constants.Mock.mediumDelay)
        return Self.makeStubResponse(email: "yandex.user@example.com")
    }

    func signInWithApple() async throws -> AuthResponseDTO {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        return Self.makeStubResponse(email: "apple.user@example.com")
    }

    private static func makeStubResponse(email: String) -> AuthResponseDTO {
        AuthResponseDTO(
            user: UserDTO(id: UUID().uuidString, email: email, phone: nil, onboardingDone: false),
            accessToken: "mock_access_\(UUID().uuidString)",
            refreshToken: "mock_refresh_\(UUID().uuidString)",
            accessExpiresAt: Date().addingTimeInterval(900),
            refreshExpiresAt: Date().addingTimeInterval(2_592_000)
        )
    }
}
