import Foundation

struct OrderBriefDTO: Decodable {
    let id: String
    let status: String
    let totalKopecks: Int64
    let deliveryKopecks: Int64
    let createdAt: Date
}

struct OrderDetailDTO: Decodable {
    let id: String
    let userId: String
    let optimizationResultId: String?
    let status: String
    let totalKopecks: Int64
    let deliveryKopecks: Int64
    let items: [OrderItemDTO]
    let history: [StatusChangeDTO]
    let createdAt: Date
    let updatedAt: Date
}

struct OrderItemDTO: Decodable {
    let id: String
    let productId: String
    let productName: String
    let storeId: String
    let storeName: String
    let quantity: Int16
    let priceKopecks: Int64
}

struct StatusChangeDTO: Decodable {
    let status: String
    let comment: String?
    let changedAt: Date
}

struct PlaceOrderRequestDTO: Encodable {
    let optimizationResultId: String
}

struct PlaceOrderResponseDTO: Decodable {
    let orderId: String
    let status: String
}
