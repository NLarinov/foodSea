import Foundation

struct RecognizedProduct: Sendable {
    let product: Product
    let confidence: Double
    var quantity: Int
    let unit: String
    let rawQuery: String
}
