import Foundation

protocol CategoryServiceProtocol: Sendable {
    func fetchCategoryTree() async throws -> [Category]
    func fetchBrands() async throws -> [Brand]
}
