import Foundation

final class MockOrderService: OrderServiceProtocol, @unchecked Sendable {
    func fetchOrders() async throws -> [Order] {
        try await Task.sleep(nanoseconds: Constants.Mock.mediumDelay)
        return []
    }

    func fetchOrderDetail(id: String) async throws -> OrderDetail {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        throw AppError.notFound
    }

    func createOrder(from optimizationResult: OptimizationResult) async throws -> Order {
        try await Task.sleep(nanoseconds: Constants.Mock.longDelay)
        throw AppError.notFound
    }
}
