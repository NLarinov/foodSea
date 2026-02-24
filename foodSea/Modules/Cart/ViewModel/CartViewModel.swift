import Foundation
import Combine

final class CartViewModel {
    @Published var cartItems: [CartItem] = []
    @Published var totalCost: Decimal = 0
    @Published var isEmpty: Bool = true
    @Published var isLoading = false

    var canOptimize: Bool { !cartItems.isEmpty }

    private let cartService: any CartServiceProtocol
    private let cartStorage = CartStorage()

    nonisolated init(cartService: any CartServiceProtocol) {
        self.cartService = cartService
    }

    func loadCart() {
        isLoading = true
        Task {
            do {
                let items = try await cartService.getCartItems()
                cartItems = items
                recalculate()
                persist()
            } catch {
                let stored = cartStorage.load()
                cartItems = stored
                recalculate()
            }
            isLoading = false
        }
    }

    func updateQuantity(itemId: String, quantity: Int) {
        if quantity <= 0 {
            removeItem(itemId: itemId)
            return
        }
        let clampedQuantity = min(quantity, Constants.Cart.maxQuantity)
        Task {
            do {
                try await cartService.updateItemQuantity(itemId: itemId, quantity: clampedQuantity)
                if let index = cartItems.firstIndex(where: { $0.id == itemId }) {
                    cartItems[index].quantity = clampedQuantity
                    recalculate()
                    persist()
                }
            } catch {}
        }
    }

    func removeItem(itemId: String) {
        Task {
            do {
                try await cartService.removeItem(itemId: itemId)
                cartItems.removeAll { $0.id == itemId }
                recalculate()
                persist()
            } catch {}
        }
    }

    func clearCart() {
        Task {
            do {
                try await cartService.clearCart()
                cartItems = []
                recalculate()
                cartStorage.clear()
            } catch {}
        }
    }

    private func recalculate() {
        totalCost = cartItems.reduce(Decimal.zero) { $0 + ($1.subtotal ?? .zero) }
        isEmpty = cartItems.isEmpty
    }

    private func persist() {
        cartStorage.save(cartItems)
    }
}
