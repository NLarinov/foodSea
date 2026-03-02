import Foundation

struct CartResponseDTO: Decodable {
    let items: [CartItemDTO]
}

struct CartItemDTO: Decodable {
    let productId: String
    let productName: String
    let quantity: Int16
    let addedAt: Date
}

struct AddItemRequestDTO: Encodable {
    let productId: String
    let quantity: Int16
}

struct UpdateItemRequestDTO: Encodable {
    let quantity: Int16
}
