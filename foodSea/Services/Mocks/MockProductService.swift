import Foundation

final class MockProductService: ProductServiceProtocol, @unchecked Sendable {
    func fetchProducts(page: Int, perPage: Int) async throws -> [Product] {
        try await Task.sleep(nanoseconds: Constants.Mock.mediumDelay)
        return []
    }

    func fetchProduct(id: String) async throws -> Product {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        throw AppError.notFound
    }

    func searchProducts(query: String, filters: SearchFilters?) async throws -> [Product] {
        try await Task.sleep(nanoseconds: Constants.Mock.mediumDelay)
        return []
    }

    func fetchSimilarProducts(productId: String) async throws -> [Product] {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        return []
    }

    func findByBarcode(_ barcode: String) async throws -> Product? {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        return nil
    }
}
