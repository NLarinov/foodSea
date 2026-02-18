import Foundation

final class MockOptimizationService: OptimizationServiceProtocol, @unchecked Sendable {
    func optimize(cartItems: [CartItem]) async throws -> OptimizationResult {
        try await Task.sleep(nanoseconds: Constants.Mock.longDelay)
        return OptimizationResult(
            totalCost: 0,
            deliveryCost: 0,
            savings: 0,
            storeOrders: [],
            substitutions: []
        )
    }
}
