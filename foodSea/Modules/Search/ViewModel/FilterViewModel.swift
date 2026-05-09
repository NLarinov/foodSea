import Foundation
import Combine

final class FilterViewModel {
    @Published var selectedCategoryId: String?
    @Published var selectedBrandId: String?
    @Published var minPrice: Decimal?
    @Published var maxPrice: Decimal?

    @Published private(set) var availableCategories: [Category] = []
    @Published private(set) var availableBrands: [Brand] = []
    @Published private(set) var isLoading = true

    private let categoryService: any CategoryServiceProtocol

    nonisolated init(categoryService: any CategoryServiceProtocol, currentFilters: SearchFilters? = nil) {
        self.categoryService = categoryService
        if let filters = currentFilters {
            self.selectedCategoryId = filters.categoryId
            self.selectedBrandId = filters.brandId
            self.minPrice = filters.minPrice
            self.maxPrice = filters.maxPrice
        }
        Task { await self.loadOptions() }
    }

    @MainActor
    private func loadOptions() async {
        async let cats = (try? categoryService.fetchCategoryTree()) ?? []
        async let brnds = (try? categoryService.fetchBrands()) ?? []
        let (c, b) = await (cats, brnds)
        availableCategories = c
        availableBrands = b
        isLoading = false
    }

    func selectCategory(_ id: String?) {
        selectedCategoryId = (selectedCategoryId == id) ? nil : id
    }

    func selectBrand(_ id: String?) {
        selectedBrandId = (selectedBrandId == id) ? nil : id
    }

    func apply() -> SearchFilters {
        SearchFilters(
            categoryId: selectedCategoryId,
            brandId: selectedBrandId,
            minPrice: minPrice,
            maxPrice: maxPrice,
            inStock: nil,
            hasDiscount: nil
        )
    }

    func reset() {
        selectedCategoryId = nil
        selectedBrandId = nil
        minPrice = nil
        maxPrice = nil
    }
}
