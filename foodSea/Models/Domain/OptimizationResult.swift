import Foundation

struct OptimizationResult: Codable, Sendable {
    let id: String
    let totalCost: Decimal
    let deliveryCost: Decimal
    let savings: Decimal
    let storeOrders: [StoreOrder]
    var substitutions: [Substitution]
}

struct StoreOrder: Codable, Identifiable, Sendable {
    let id: String
    let store: Store
    let items: [OptimizedItem]
    let subtotal: Decimal
    let deliveryFee: Decimal
}

struct OptimizedItem: Codable, Sendable {
    let product: Product
    let quantity: Int
    let price: Decimal
}

struct Substitution: Codable, Identifiable, Sendable {
    let id: String
    let original: Product
    let alternative: Product
    let priceDifference: Decimal
    var isAccepted: Bool
}
