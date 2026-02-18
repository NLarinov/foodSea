import Foundation

protocol OptimizationServiceProtocol: Sendable {
    func optimize(cartItems: [CartItem]) async throws -> OptimizationResult
}
