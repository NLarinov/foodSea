import Foundation

final class MockCartService: CartServiceProtocol, @unchecked Sendable {
    static let cartDidChangeNotification = Notification.Name("MockCartServiceCartDidChange")
    static let cartItemCountKey = "cartItemCount"

    private var items: [CartItem] = []
    private let storage = CartStorage()

    init() {
        items = storage.load()
    }

    func getCartItems() async throws -> [CartItem] {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        return items
    }

    func addItem(productId: String, quantity: Int) async throws {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        if let index = items.firstIndex(where: { $0.product.id == productId }) {
            items[index].quantity += quantity
        } else if let product = MockData.products.first(where: { $0.id == productId }) {
            let item = CartItem(id: UUID().uuidString, product: product, quantity: quantity)
            items.append(item)
        }
        postCartChange()
    }

    func updateItemQuantity(itemId: String, quantity: Int) async throws {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        if quantity <= 0 {
            items.removeAll { $0.id == itemId }
        } else if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].quantity = min(quantity, Constants.Cart.maxQuantity)
        }
        postCartChange()
    }

    func removeItem(itemId: String) async throws {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        items.removeAll { $0.id == itemId }
        postCartChange()
    }

    func clearCart() async throws {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        items.removeAll()
        postCartChange()
    }

    private func postCartChange() {
        let count = items.reduce(0) { $0 + $1.quantity }
        NotificationCenter.default.post(
            name: Self.cartDidChangeNotification,
            object: nil,
            userInfo: [Self.cartItemCountKey: count]
        )
    }
}
