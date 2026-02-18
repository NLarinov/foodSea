import Foundation

final class MockCartService: CartServiceProtocol, @unchecked Sendable {
    private var items: [CartItem] = []

    func getCartItems() async throws -> [CartItem] {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        return items
    }

    func addItem(productId: String, quantity: Int) async throws {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
    }

    func updateItemQuantity(itemId: String, quantity: Int) async throws {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
    }

    func removeItem(itemId: String) async throws {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        items.removeAll { $0.id == itemId }
    }

    func clearCart() async throws {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        items.removeAll()
    }
}
