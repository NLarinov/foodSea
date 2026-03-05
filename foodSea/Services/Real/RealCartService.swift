import Foundation

final class RealCartService: CartServiceProtocol, @unchecked Sendable {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    func getCartItems() async throws -> [CartItem] {
        let response: CartResponseDTO = try await client.request(.getCart)
        let client = self.client
        return try await withThrowingTaskGroup(of: CartItem?.self) { group in
            for item in response.items {
                group.addTask {
                    do {
                        let detail: ProductDetailDTO = try await client.request(.getProduct(id: item.productId))
                        let offers: [OfferDTO] = try await client.request(.getOffers(productId: item.productId))
                        let product = detail.toDomain(offers: offers)
                        return CartItem(id: item.productId, product: product, quantity: Int(item.quantity))
                    } catch {
                        return nil
                    }
                }
            }
            var result: [CartItem] = []
            for try await item in group {
                if let item { result.append(item) }
            }
            return result
        }
    }

    func addItem(productId: String, quantity: Int) async throws {
        try await client.requestEmpty(.addToCart(productId: productId, quantity: quantity))
        postCartChange()
    }

    func updateItemQuantity(itemId: String, quantity: Int) async throws {
        try await client.requestEmpty(.updateCartItem(productId: itemId, quantity: quantity))
        postCartChange()
    }

    func removeItem(itemId: String) async throws {
        try await client.requestEmpty(.removeCartItem(productId: itemId))
        postCartChange()
    }

    func clearCart() async throws {
        try await client.requestEmpty(.clearCart)
        postCartChange()
    }

    private func postCartChange() {
        // Posts count = -1: AppCoordinator won't update badge until next full cart fetch
        NotificationCenter.default.post(
            name: .cartDidChange,
            object: nil,
            userInfo: [Constants.Cart.itemCountKey: -1]
        )
    }
}
