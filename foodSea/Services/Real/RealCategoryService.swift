import Foundation

final actor RealCategoryService: CategoryServiceProtocol {
    private let client: NetworkClient
    private var cachedCategories: [Category]?
    private var cachedBrands: [Brand]?

    init(client: NetworkClient) {
        self.client = client
    }

    func fetchCategoryTree() async throws -> [Category] {
        if let cachedCategories { return cachedCategories }
        let dtos: [CategoryNodeDTO] = try await client.request(.listCategories)
        let tree = dtos.map { $0.toDomain() }
        cachedCategories = tree
        return tree
    }

    func fetchBrands() async throws -> [Brand] {
        if let cachedBrands { return cachedBrands }
        let dtos: [BrandDTO] = try await client.request(.listBrands)
        let brands = dtos.map { $0.toDomain() }.sorted { $0.name < $1.name }
        cachedBrands = brands
        return brands
    }
}
