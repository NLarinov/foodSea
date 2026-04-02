import Foundation

struct OrderItem: Codable, Sendable {
    let product: Product
    let quantity: Int
    let pricePerUnit: Decimal
    let store: Store
}

struct Order: Codable, Identifiable, Sendable {
    let id: String
    let orderNumber: String
    let createdAt: Date
    let status: OrderStatus
    let totalCost: Decimal
    let stores: [Store]
    let items: [OrderItem]
}

struct StatusEvent: Codable, Sendable {
    let status: OrderStatus
    let timestamp: Date
    let description: String
}

struct OrderDetail: Codable, Sendable {
    let order: Order
    let timeline: [StatusEvent]
    let deliveryAddress: String?
    let estimatedDelivery: Date?
}
