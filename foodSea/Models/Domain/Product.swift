import Foundation

nonisolated struct Product: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String
    let brand: String
    let category: Category
    let imageURL: URL?
    let barcode: String?
    let prices: [PriceEntry]
    let isAvailable: Bool
    let maxDiscountPercent: Int?

    init(
        id: String,
        name: String,
        description: String,
        brand: String,
        category: Category,
        imageURL: URL?,
        barcode: String?,
        prices: [PriceEntry],
        isAvailable: Bool,
        maxDiscountPercent: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.brand = brand
        self.category = category
        self.imageURL = imageURL
        self.barcode = barcode
        self.prices = prices
        self.isAvailable = isAvailable
        self.maxDiscountPercent = maxDiscountPercent
    }

    var lowestPrice: Decimal? {
        prices.min(by: { $0.price < $1.price })?.price
    }

    var hasPromotion: Bool {
        if let pct = maxDiscountPercent, pct > 0 { return true }
        return prices.contains(where: { $0.hasPromotion })
    }
}
