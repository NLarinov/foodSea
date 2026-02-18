import Foundation

struct Product: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String
    let brand: String
    let category: Category
    let imageURL: URL?
    let barcode: String?
    let prices: [PriceEntry]
    let isAvailable: Bool

    var lowestPrice: Decimal? {
        prices.min(by: { $0.price < $1.price })?.price
    }

    var hasPromotion: Bool {
        prices.contains(where: { $0.hasPromotion })
    }
}
