import Foundation

protocol CartServiceProtocol: Sendable {
    func getCartItems() async throws -> [CartItem]
    func addItem(productId: String, quantity: Int) async throws
    func updateItemQuantity(itemId: String, quantity: Int) async throws
    func removeItem(itemId: String) async throws
    func clearCart() async throws
}
