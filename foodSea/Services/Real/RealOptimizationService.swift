import Foundation

final class RealOptimizationService: OptimizationServiceProtocol, @unchecked Sendable {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    // cartItems parameter is ignored: backend reads cart from JWT
    func optimize(cartItems: [CartItem]) async throws -> OptimizationResult {
        let dto: OptimizationResultDTO = try await client.request(.runOptimization)
        return dto.toDomain()
    }
}
