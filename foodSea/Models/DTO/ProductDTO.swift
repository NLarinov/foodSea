import Foundation

struct ProductBriefDTO: Decodable {
    let id: String
    let name: String
    let imageUrl: String?
    let inStock: Bool
    let minPriceKopecks: Int64?
    let maxDiscountPercent: Int?
    let weight: String?
}

struct ProductDetailDTO: Decodable {
    let id: String
    let name: String
    let description: String?
    let composition: String?
    let weight: String?
    let barcode: String?
    let imageUrl: String?
    let inStock: Bool
    let category: CategoryBriefDTO
    let subcategory: CategoryBriefDTO?
    let brand: BrandBriefDTO?
    let nutrition: NutritionDTO?
    let bestOffer: BestOfferDTO?
}

struct CategoryBriefDTO: Decodable {
    let id: String
    let name: String
}

struct BrandBriefDTO: Decodable {
    let id: String
    let name: String
}

struct NutritionDTO: Decodable {
    let calories: Double
    let protein: Double
    let fat: Double
    let carbohydrates: Double
}

struct BestOfferDTO: Decodable {
    let storeName: String
    let storeSlug: String
    let priceKopecks: Int64
    let originalPriceKopecks: Int64?
    let discountPercent: Int8?
}
