import Foundation

struct CategoryNodeDTO: Decodable, Sendable {
    let id: String
    let name: String
    let slug: String
    let sortOrder: Int
    let children: [CategoryNodeDTO]?
}

struct BrandDTO: Decodable, Sendable {
    let id: String
    let name: String
}
