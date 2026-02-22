import Foundation

nonisolated struct PriceEntry: Codable, Hashable, Sendable {
    let store: Store
    let price: Decimal
    let originalPrice: Decimal?
    let hasPromotion: Bool
    let deliveryFee: Decimal
    let freeDeliveryThreshold: Decimal?
}
