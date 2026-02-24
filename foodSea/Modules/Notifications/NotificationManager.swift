import UIKit
import UserNotifications

final class NotificationManager: NSObject, @unchecked Sendable {
    static let shared = NotificationManager()

    var onOrderTapped: ((String) -> Void)?

    private override init() {
        super.init()
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                Task { @MainActor in
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        UNUserNotificationCenter.current().delegate = self
    }

    func scheduleOrderStatusNotification(orderId: String, status: OrderStatus) {
        let content = UNMutableNotificationContent()
        content.title = Constants.Notifications.orderUpdateTitle
        content.sound = .default
        content.userInfo = [Constants.Notifications.orderIdKey: orderId]
        content.categoryIdentifier = Constants.Notifications.categoryIdentifier

        switch status {
        case .assembling:
            content.body = Constants.Notifications.orderAssemblingBody
        case .inTransit:
            content.body = Constants.Notifications.orderInTransitBody
        case .delivered:
            content.body = Constants.Notifications.orderDeliveredBody
        default:
            return
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Constants.Notifications.localNotificationDelay,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "\(orderId)_\(status)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func handleNotification(userInfo: [AnyHashable: Any]) {
        guard let orderId = userInfo[Constants.Notifications.orderIdKey] as? String else { return }
        onOrderTapped?(orderId)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            NotificationManager.shared.handleNotification(userInfo: userInfo)
        }
        completionHandler()
    }
}
