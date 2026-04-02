import Foundation

enum OrderStatus: String, Codable, CaseIterable, Sendable, Hashable {
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
