import Foundation
import Combine

final class OrderDetailViewModel {
    @Published var orderDetail: OrderDetail?
    @Published var isLoading = false
    @Published var error: AppError?

    private let orderId: String
    private let orderService: any OrderServiceProtocol

    nonisolated init(orderId: String, orderService: any OrderServiceProtocol) {
        self.orderId = orderId
        self.orderService = orderService
    }

    func loadDetail() {
        isLoading = true
        error = nil
        Task {
            do {
                let detail = try await orderService.fetchOrderDetail(id: orderId)
                orderDetail = detail
            } catch {
                self.error = error as? AppError ?? .unknown(error.localizedDescription)
            }
            isLoading = false
        }
    }
}
