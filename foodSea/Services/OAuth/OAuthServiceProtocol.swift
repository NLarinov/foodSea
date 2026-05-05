import Foundation

protocol OAuthServiceProtocol: Sendable {
    func signInWithGoogle() async throws -> AuthResponseDTO
    func signInWithYandex() async throws -> AuthResponseDTO
    func signInWithApple() async throws -> AuthResponseDTO
}
