import Foundation

final class MockProductService: ProductServiceProtocol, @unchecked Sendable {
    func fetchProducts(page: Int, perPage: Int) async throws -> [Product] {
        try await Task.sleep(nanoseconds: Constants.Mock.mediumDelay)
        let start = page * perPage
        guard start < MockData.products.count else { return [] }
        let end = min(start + perPage, MockData.products.count)
        return Array(MockData.products[start..<end])
    }

    func fetchProduct(id: String) async throws -> Product {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        guard let product = MockData.products.first(where: { $0.id == id }) else {
            throw AppError.notFound
        }
        return product
    }

    func searchProducts(query: String, filters: SearchFilters?) async throws -> [Product] {
        try await Task.sleep(nanoseconds: Constants.Mock.mediumDelay)
        var results = MockData.products

        if !query.isEmpty {
            let lowered = query.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(lowered) ||
                $0.brand.lowercased().contains(lowered) ||
                $0.category.name.lowercased().contains(lowered)
            }
        }

        if let filters {
            if let categories = filters.categories, !categories.isEmpty {
                results = results.filter { categories.contains($0.category.id) }
            }
            if let brands = filters.brands, !brands.isEmpty {
                results = results.filter { brands.contains($0.brand) }
            }
            if let minPrice = filters.minPrice {
                results = results.filter { ($0.lowestPrice ?? 0) >= minPrice }
            }
            if let maxPrice = filters.maxPrice {
                results = results.filter { ($0.lowestPrice ?? .greatestFiniteMagnitude) <= maxPrice }
            }
        }

        return results
    }

    func fetchSimilarProducts(productId: String) async throws -> [Product] {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        guard let product = MockData.products.first(where: { $0.id == productId }) else {
            return []
        }
        return MockData.products
            .filter { $0.category.id == product.category.id && $0.id != productId }
            .prefix(4)
            .map { $0 }
    }

    func findByBarcode(_ barcode: String) async throws -> Product? {
        try await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        return MockData.products.first(where: { $0.barcode == barcode })
    }

    func searchByPhoto(imageJPEG: Data, ocrText: String, topK: Int) async throws -> Product? {
        try await Task.sleep(nanoseconds: Constants.Mock.longDelay)
        return MockData.products.first
    }
}
