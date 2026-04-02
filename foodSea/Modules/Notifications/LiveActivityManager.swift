import Foundation
#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
final class LiveActivityManager: @unchecked Sendable {
    static let shared = LiveActivityManager()

    private var current: Activity<OrderActivityAttributes>?
    private let queue = DispatchQueue(label: "foodsea.liveActivity")

    private init() {}

    func startActivity(for order: Order) {
        queue.async {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                print("[LiveActivity] disabled by user/system")
                return
            }
            if let existing = self.current {
                Task { await existing.end(nil, dismissalPolicy: .immediate) }
            }
            let attributes = OrderActivityAttributes(
                orderId: order.id,
                orderNumber: order.orderNumber,
                totalCost: order.totalCost
            )
            let state = OrderActivityAttributes.ContentState(
                status: order.status,
                statusText: order.status.displayName,
                updatedAt: Date()
            )
            do {
                let content = ActivityContent(state: state, staleDate: nil)
                let activity = try Activity<OrderActivityAttributes>.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
                self.current = activity
                print("[LiveActivity] started \(activity.id) for order \(order.orderNumber)")
            } catch {
                print("[LiveActivity] failed to start: \(error)")
            }
        }
    }

    func updateActivity(status: OrderStatus) {
        queue.async {
            guard let activity = self.current else { return }
            let state = OrderActivityAttributes.ContentState(
                status: status,
                statusText: status.displayName,
                updatedAt: Date()
            )
            Task {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        }
    }

    func endActivity() {
        queue.async {
            guard let activity = self.current else { return }
            Task {
                await activity.end(nil, dismissalPolicy: .default)
            }
            self.current = nil
        }
    }
}
#endif
