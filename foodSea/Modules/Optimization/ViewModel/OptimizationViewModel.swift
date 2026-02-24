import Foundation
import Combine

final class OptimizationViewModel {
    @Published var result: OptimizationResult?
    @Published var isLoading = false
    @Published var error: AppError?

    private let optimizationService: any OptimizationServiceProtocol
    private let cartService: any CartServiceProtocol
    private var cartItems: [CartItem]

    nonisolated init(
        cartItems: [CartItem],
        optimizationService: any OptimizationServiceProtocol,
        cartService: any CartServiceProtocol
    ) {
        self.cartItems = cartItems
        self.optimizationService = optimizationService
        self.cartService = cartService
    }

    func optimize() {
        isLoading = true
        error = nil
        Task {
            do {
                let optimized = try await optimizationService.optimize(cartItems: cartItems)
                result = optimized
            } catch {
                self.error = error as? AppError ?? .unknown(error.localizedDescription)
            }
            isLoading = false
        }
    }

    func acceptSubstitution(id: String) {
        guard var current = result,
              let index = current.substitutions.firstIndex(where: { $0.id == id }) else { return }
        current.substitutions[index].isAccepted = true
        result = current
    }

    func rejectSubstitution(id: String) {
        guard var current = result,
              let index = current.substitutions.firstIndex(where: { $0.id == id }) else { return }
        current.substitutions[index].isAccepted = false
        result = current
    }

    var grandTotal: Decimal {
        guard let result else { return 0 }
        return result.totalCost + result.deliveryCost
    }
}
