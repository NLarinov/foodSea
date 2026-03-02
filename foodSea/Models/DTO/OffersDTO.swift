import Foundation

struct OfferDTO: Decodable {
    let store: StoreBriefDTO
    let priceKopecks: Int64
    let originalPriceKopecks: Int64?
    let discountPercent: Int8?
    let inStock: Bool
}

struct StoreBriefDTO: Decodable {
    let id: String
    let name: String
    let logoUrl: String?
}
