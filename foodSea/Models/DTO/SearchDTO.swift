import Foundation

struct SearchResultItemDTO: Decodable {
    let id: String
    let name: String
    let imageUrl: String?
    let barcode: String?
    let inStock: Bool
    let categoryId: String
    let subcategoryId: String?
    let brandId: String?
    let minPriceKopecks: Int64
    let maxDiscountPercent: Int8?
    let score: Double
    let offersCount: Int16
}
