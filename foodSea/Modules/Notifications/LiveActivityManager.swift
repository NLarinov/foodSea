import Foundation
#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
final class LiveActivityManager: @unchecked Sendable {
    static let shared = LiveActivityManager()

    private var current: Activity<OrderActivityAttributes>?
    private var pushTokenTask: Task<Void, Never>?
    private var notifications: NotificationsService?
    private let queue = DispatchQueue(label: "foodsea.liveActivity")

    private init() {}

    func configure(notifications: NotificationsService?) {
        queue.async { self.notifications = notifications }
    }

    func startActivity(for order: Order) {
        queue.async {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                print("[LiveActivity] disabled by user/system")
                return
            }
            if let existing = self.current {
                Task { await existing.end(nil, dismissalPolicy: .immediate) }
            }
            self.pushTokenTask?.cancel()
            self.pushTokenTask = nil

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
            let pushType: PushType? = (self.notifications != nil) ? .token : nil
            do {
                let content = ActivityContent(state: state, staleDate: nil)
                let activity = try Activity<OrderActivityAttributes>.request(
                    attributes: attributes,
                    content: content,
                    pushType: pushType
                )
                self.current = activity
                print("[LiveActivity] started \(activity.id) for order \(order.orderNumber) pushType=\(pushType == .token ? "token" : "none")")
                if let notifications = self.notifications {
                    let orderId = order.id
                    self.pushTokenTask = Task {
                        for await tokenData in activity.pushTokenUpdates {
                            let hex = tokenData.map { String(format: "%02x", $0) }.joined()
                            do {
                                try await notifications.registerLiveActivity(orderId: orderId, pushToken: hex)
                                print("[LiveActivity] registered push token for order \(orderId)")
                            } catch {
                                print("[LiveActivity] failed to register push token: \(error)")
                            }
                        }
                    }
                }
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
            self.pushTokenTask?.cancel()
            self.pushTokenTask = nil
            guard let activity = self.current else { return }
            let orderId = activity.attributes.orderId
            let notifications = self.notifications
            Task {
                await activity.end(nil, dismissalPolicy: .default)
                if let notifications {
                    try? await notifications.removeLiveActivity(orderId: orderId)
                }
            }
            self.current = nil
        }
    }
}
#endif
