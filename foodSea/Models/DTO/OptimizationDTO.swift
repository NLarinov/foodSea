import Foundation

struct OptimizationResultDTO: Decodable {
    let id: String
    let totalKopecks: Int64
    let deliveryKopecks: Int64
    let savingsKopecks: Int64
    let status: String
    let isApproximate: Bool
    let items: [AssignmentDTO]
    let substitutions: [SubstitutionDTO]
}

struct AssignmentDTO: Decodable {
    let productId: String
    let productName: String
    let storeId: String
    let storeName: String
    let quantity: Int
    let priceKopecks: Int64
}

struct SubstitutionDTO: Decodable {
    let originalProductId: String
    let originalProductName: String
    let analogProductId: String
    let analogProductName: String
    let priceDeltaKopecks: Int64
}

struct AnalogDTO: Decodable {
    let productId: String
    let productName: String
    let score: Double
    let minPriceKopecks: Int64
}

struct AnalogsResponseDTO: Decodable {
    let analogs: [AnalogDTO]
}
