import Foundation

enum OrderStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case confirmed
    case assembling
    case shipped
    case inTransit
    case delivered
    case cancelled

    var displayName: String {
        switch self {
        case .pending: "Ожидает"
        case .confirmed: "Подтверждён"
        case .assembling: "Собирается"
        case .shipped: "Отправлен"
        case .inTransit: "В пути"
        case .delivered: "Доставлен"
        case .cancelled: "Отменён"
        }
    }
}

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
