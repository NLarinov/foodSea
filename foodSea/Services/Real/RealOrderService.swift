import Foundation

final class RealOrderService: OrderServiceProtocol, @unchecked Sendable {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    func fetchOrders() async throws -> [Order] {
        let dtos: [OrderBriefDTO] = try await client.request(.listOrders)
        return dtos.map { $0.toDomain() }
    }

    func fetchOrderDetail(id: String) async throws -> OrderDetail {
        let dto: OrderDetailDTO = try await client.request(.getOrder(id: id))
        return dto.toDomain()
    }

    func createOrder(from optimizationResult: OptimizationResult) async throws -> Order {
        let placeResponse: PlaceOrderResponseDTO = try await client.request(
            .placeOrder(optimizationResultId: optimizationResult.id)
        )
        let detail: OrderDetailDTO = try await client.request(.getOrder(id: placeResponse.orderId))
        return detail.toDomain().order
    }
}
