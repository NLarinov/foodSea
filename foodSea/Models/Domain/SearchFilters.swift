import Foundation

struct SearchFilters: Codable, Sendable {
    var categories: [String]?
    var brands: [String]?
    var minPrice: Decimal?
    var maxPrice: Decimal?

    var isEmpty: Bool {
        (categories?.isEmpty ?? true) &&
        (brands?.isEmpty ?? true) &&
        minPrice == nil &&
        maxPrice == nil
    }
}
