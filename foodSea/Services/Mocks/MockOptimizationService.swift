import Foundation

final class MockOptimizationService: OptimizationServiceProtocol, @unchecked Sendable {
    func optimize(cartItems: [CartItem]) async throws -> OptimizationResult {
        try await Task.sleep(nanoseconds: Constants.Mock.longDelay)

        let stores = Array(MockData.stores.prefix(3))
        var storeOrders: [StoreOrder] = []
        var totalItemsCost: Decimal = 0

        for (index, store) in stores.enumerated() {
            let storeItems = cartItems.enumerated()
                .filter { $0.offset % stores.count == index }
                .map { $0.element }

            guard !storeItems.isEmpty else { continue }

            let optimizedItems = storeItems.map { cartItem -> OptimizedItem in
                let price = cartItem.product.prices
                    .first(where: { $0.store.id == store.id })?.price
                    ?? cartItem.product.lowestPrice
                    ?? 0
                return OptimizedItem(product: cartItem.product, quantity: cartItem.quantity, price: price)
            }

            let subtotal = optimizedItems.reduce(Decimal(0)) { $0 + $1.price * Decimal($1.quantity) }
            let deliveryFee: Decimal = subtotal > 1500 ? 0 : 99
            totalItemsCost += subtotal

            storeOrders.append(StoreOrder(
                id: UUID().uuidString,
                store: store,
                items: optimizedItems,
                subtotal: subtotal,
                deliveryFee: deliveryFee
            ))
        }

        let totalDelivery = storeOrders.reduce(Decimal(0)) { $0 + $1.deliveryFee }
        let baselineCost = cartItems.reduce(Decimal(0)) { $0 + ($1.subtotal ?? 0) }
        let savings = max(0, baselineCost - totalItemsCost)

        var substitutions: [Substitution] = []
        if let firstItem = cartItems.first {
            let similar = MockData.products.first(where: {
                $0.category.id == firstItem.product.category.id &&
                $0.id != firstItem.product.id &&
                ($0.lowestPrice ?? .greatestFiniteMagnitude) < (firstItem.product.lowestPrice ?? 0)
            })
            if let similar {
                substitutions.append(Substitution(
                    id: UUID().uuidString,
                    original: firstItem.product,
                    alternative: similar,
                    priceDifference: (firstItem.product.lowestPrice ?? 0) - (similar.lowestPrice ?? 0),
                    isAccepted: false
                ))
            }
        }

        return OptimizationResult(
            id: UUID().uuidString,
            totalCost: totalItemsCost,
            deliveryCost: totalDelivery,
            savings: savings,
            storeOrders: storeOrders,
            substitutions: substitutions
        )
    }
}
