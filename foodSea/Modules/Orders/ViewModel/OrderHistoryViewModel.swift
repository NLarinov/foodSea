import Foundation
import Combine

final class OrderHistoryViewModel {
    @Published var orders: [Order] = []
    @Published var filteredOrders: [Order] = []
    @Published var selectedFilter: OrderStatus?
    @Published var isLoading = false
    @Published var error: AppError?

    private let orderService: any OrderServiceProtocol

    nonisolated init(orderService: any OrderServiceProtocol) {
        self.orderService = orderService
    }

    func loadOrders() {
        isLoading = true
        error = nil
        Task {
            do {
                let fetched = try await orderService.fetchOrders()
                orders = fetched
                applyFilter()
            } catch {
                self.error = error as? AppError ?? .unknown(error.localizedDescription)
            }
            isLoading = false
        }
    }

    func filterByStatus(_ status: OrderStatus?) {
        selectedFilter = status
        applyFilter()
    }

    private func applyFilter() {
        if let selectedFilter {
            filteredOrders = orders.filter { $0.status == selectedFilter }
        } else {
            filteredOrders = orders
        }
    }
}
