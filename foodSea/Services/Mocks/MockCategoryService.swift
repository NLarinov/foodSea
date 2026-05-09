import Foundation

final actor MockCategoryService: CategoryServiceProtocol {
    func fetchCategoryTree() async throws -> [Category] {
        try? await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        return MockData.categoryTree
    }

    func fetchBrands() async throws -> [Brand] {
        try? await Task.sleep(nanoseconds: Constants.Mock.shortDelay)
        return MockData.brands
    }
}
