import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let data: T?
    let error: String?
}

struct APIMeta: Decodable {
    let page: Int
    let pageSize: Int
    let totalCount: Int
    let totalPages: Int
}
