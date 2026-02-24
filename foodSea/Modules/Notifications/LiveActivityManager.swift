import Foundation

final class LiveActivityManager: @unchecked Sendable {
    static let shared = LiveActivityManager()

    private init() {}

    func startActivity(for order: Order) {
        print("[LiveActivity] Started for order \(order.orderNumber)")
    }

    func updateActivity(status: OrderStatus) {
        print("[LiveActivity] Updated status to \(status)")
    }

    func endActivity() {
        print("[LiveActivity] Ended")
    }
}
