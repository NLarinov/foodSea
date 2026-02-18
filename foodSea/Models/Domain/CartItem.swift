import Foundation

struct CartItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let product: Product
    var quantity: Int

    var subtotal: Decimal? {
        product.lowestPrice.map { $0 * Decimal(quantity) }
    }
}
