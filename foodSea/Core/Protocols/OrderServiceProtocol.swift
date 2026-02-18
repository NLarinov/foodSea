import Foundation

protocol OrderServiceProtocol: Sendable {
    func fetchOrders() async throws -> [Order]
    func fetchOrderDetail(id: String) async throws -> OrderDetail
    func createOrder(from optimizationResult: OptimizationResult) async throws -> Order
}
