import Foundation
import Combine

final class OrderCheckoutViewModel {
    @Published var isSubmitting = false
    @Published var createdOrder: Order?
    @Published var error: AppError?

    let optimizationResult: OptimizationResult
    private let orderService: any OrderServiceProtocol

    nonisolated init(optimizationResult: OptimizationResult, orderService: any OrderServiceProtocol) {
        self.optimizationResult = optimizationResult
        self.orderService = orderService
    }

    var grandTotal: Decimal {
        optimizationResult.totalCost + optimizationResult.deliveryCost
    }

    func submitOrder() {
        isSubmitting = true
        error = nil
        Task {
            do {
                let order = try await orderService.createOrder(from: optimizationResult)
                createdOrder = order
                await MainActor.run {
                    OrderProgressTracker.shared.track(order: order)
                    NotificationCenter.default.post(
                        name: .orderDidCreate,
                        object: nil,
                        userInfo: [NotificationUserInfoKey.orderId: order.id]
                    )
                }
            } catch {
                self.error = error as? AppError ?? .unknown(error.localizedDescription)
            }
            isSubmitting = false
        }
    }
}
