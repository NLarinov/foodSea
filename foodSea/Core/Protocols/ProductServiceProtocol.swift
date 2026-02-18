import Foundation

protocol ProductServiceProtocol: Sendable {
    func fetchProducts(page: Int, perPage: Int) async throws -> [Product]
    func fetchProduct(id: String) async throws -> Product
    func searchProducts(query: String, filters: SearchFilters?) async throws -> [Product]
    func fetchSimilarProducts(productId: String) async throws -> [Product]
    func findByBarcode(_ barcode: String) async throws -> Product?
}
