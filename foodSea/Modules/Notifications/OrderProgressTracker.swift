import Foundation
import UserNotifications

@MainActor
final class OrderProgressTracker {
    static let shared = OrderProgressTracker()

    private var tasks: [String: Task<Void, Never>] = [:]
    private var lastStatus: [String: OrderStatus] = [:]
    private var orderService: (any OrderServiceProtocol)?

    private init() {}

    func configure(orderService: any OrderServiceProtocol) {
        self.orderService = orderService
    }

    func track(order: Order) {
        print("[OrderTracker] track order=\(order.orderNumber) status=\(order.status.rawValue)")
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.startActivity(for: order)
        }
        lastStatus[order.id] = order.status
        fireOrderCreatedNotification(order: order)
        startPolling(orderId: order.id)
    }

    func stop(orderId: String) {
        tasks[orderId]?.cancel()
        tasks.removeValue(forKey: orderId)
        lastStatus.removeValue(forKey: orderId)
    }

    private func startPolling(orderId: String) {
        tasks[orderId]?.cancel()
        guard let service = orderService else { return }
        tasks[orderId] = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Constants.OrderTracking.pollIntervalSec) * 1_000_000_000)
                if Task.isCancelled { return }
                guard let self else { return }
                do {
                    let detail = try await service.fetchOrderDetail(id: orderId)
                    await self.handleUpdate(orderId: orderId, status: detail.order.status)
                    if detail.order.status.isTerminal {
                        await self.finalize(orderId: orderId)
                        return
                    }
                } catch {
                    // Network blip — keep polling.
                }
            }
        }
    }

    private func handleUpdate(orderId: String, status: OrderStatus) async {
        guard lastStatus[orderId] != status else { return }
        lastStatus[orderId] = status
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.updateActivity(status: status)
        }
        fireLocalNotification(orderId: orderId, status: status)
        NotificationCenter.default.post(
            name: .orderStatusDidChange,
            object: nil,
            userInfo: [
                NotificationUserInfoKey.orderId: orderId,
                NotificationUserInfoKey.orderStatus: status.rawValue,
            ]
        )
    }

    private func finalize(orderId: String) async {
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.endActivity()
        }
        stop(orderId: orderId)
    }

    private func fireLocalNotification(orderId: String, status: OrderStatus) {
        let body: String
        switch status {
        case .pending:             body = Constants.Notifications.orderPendingBody
        case .confirmed:           body = Constants.Notifications.orderConfirmedBody
        case .assembling:          body = Constants.Notifications.orderAssemblingBody
        case .shipped, .inTransit: body = Constants.Notifications.orderInTransitBody
        case .delivered:           body = Constants.Notifications.orderDeliveredBody
        case .cancelled:           body = Constants.Notifications.orderCancelledBody
        }
        let content = UNMutableNotificationContent()
        content.title = Constants.Notifications.orderUpdateTitle
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Constants.Notifications.categoryIdentifier
        content.userInfo = [Constants.Notifications.orderIdKey: orderId]
        let request = UNNotificationRequest(
            identifier: "\(orderId)_\(status.rawValue)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func fireOrderCreatedNotification(order: Order) {
        let content = UNMutableNotificationContent()
        content.title = Constants.Notifications.orderCreatedTitle
        content.body = "\(Constants.Notifications.orderCreatedBody) №\(order.orderNumber)"
        content.sound = .default
        content.categoryIdentifier = Constants.Notifications.categoryIdentifier
        content.userInfo = [Constants.Notifications.orderIdKey: order.id]
        let request = UNNotificationRequest(
            identifier: "\(order.id)_created",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

private extension OrderStatus {
    var isTerminal: Bool {
        self == .delivered || self == .cancelled
    }
}
