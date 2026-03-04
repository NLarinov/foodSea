import Foundation

protocol AuthServiceProtocol: Sendable {
    var isLoggedIn: Bool { get }
    func register(email: String, password: String) async throws
    func login(email: String, password: String) async throws
    func logout() async throws
}
