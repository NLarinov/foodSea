import Foundation

extension Notification.Name {
    static let cartDidChange = Notification.Name("foodsea.cartDidChange")
    static let sessionExpired = Notification.Name("foodsea.sessionExpired")
    static let orderDidCreate = Notification.Name("foodsea.orderDidCreate")
    static let orderStatusDidChange = Notification.Name("foodsea.orderStatusDidChange")
    static let apnsTokenDidUpdate = Notification.Name("foodsea.apnsTokenDidUpdate")
}

enum NotificationUserInfoKey {
    static let orderId = "orderId"
    static let orderStatus = "orderStatus"
    static let apnsToken = "apnsToken"
}
