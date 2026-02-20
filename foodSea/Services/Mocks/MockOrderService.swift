import Foundation

final class MockOrderService: OrderServiceProtocol, @unchecked Sendable {
    func fetchOrders() async throws -> [Order] {
        try await Task.sleep(nanoseconds: Constants.Mock.mediumDelay)
        return MockData.orders
    }

    func fetchOrderDetail(id: String) async throws -> OrderDetail {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        guard let detail = MockData.orderDetails[id] else {
            throw AppError.notFound
        }
        return detail
    }

    func createOrder(from optimizationResult: OptimizationResult) async throws -> Order {
        try await Task.sleep(nanoseconds: Constants.Mock.longDelay)
        let order = Order(
            id: UUID().uuidString,
            orderNumber: "FS-\(Self.dateFormatter.string(from: Date()))-\(Int.random(in: 100...999))",
            createdAt: Date(),
            status: .pending,
            totalCost: optimizationResult.totalCost + optimizationResult.deliveryCost,
            stores: optimizationResult.storeOrders.map(\.store),
            items: optimizationResult.storeOrders.flatMap { storeOrder in
                storeOrder.items.map { item in
                    OrderItem(
                        product: item.product,
                        quantity: item.quantity,
                        pricePerUnit: item.price,
                        store: storeOrder.store
                    )
                }
            }
        )
        return order
    }

    nonisolated private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}
