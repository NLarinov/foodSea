import Foundation

struct SearchFilters: Codable, Sendable, Equatable {
    var categoryId: String?
    var brandId: String?
    var minPrice: Decimal?
    var maxPrice: Decimal?
    var inStock: Bool?
    var hasDiscount: Bool?

    var isEmpty: Bool {
        categoryId == nil &&
        brandId == nil &&
        minPrice == nil &&
        maxPrice == nil &&
        inStock == nil &&
        hasDiscount == nil
    }
}
