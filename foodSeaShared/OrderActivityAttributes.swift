import Foundation
#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
struct OrderActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: OrderStatus
        var statusText: String
        var updatedAt: Date
    }

    var orderId: String
    var orderNumber: String
    var totalCost: Decimal
}
#endif
