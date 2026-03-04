import Foundation

final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    private(set) var isLoggedIn = true

    func register(email: String, password: String) async throws {
        try await Task.sleep(nanoseconds: Constants.Mock.mediumDelay)
        isLoggedIn = true
    }

    func login(email: String, password: String) async throws {
        try await Task.sleep(nanoseconds: Constants.Mock.mediumDelay)
        isLoggedIn = true
    }

    func logout() async throws {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        isLoggedIn = false
    }
}
