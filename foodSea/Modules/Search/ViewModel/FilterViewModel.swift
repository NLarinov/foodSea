import Foundation
import Combine

final class FilterViewModel {
    @Published var selectedCategories: Set<String> = []
    @Published var selectedBrands: Set<String> = []
    @Published var minPrice: Decimal?
    @Published var maxPrice: Decimal?

    let availableCategories: [Category]
    let availableBrands: [String]

    nonisolated init() {
        self.availableCategories = MockData.categories
        self.availableBrands = Array(Set(MockData.products.map(\.brand))).sorted()
    }

    nonisolated init(currentFilters: SearchFilters?) {
        self.availableCategories = MockData.categories
        self.availableBrands = Array(Set(MockData.products.map(\.brand))).sorted()

        if let filters = currentFilters {
            self.selectedCategories = Set(filters.categories ?? [])
            self.selectedBrands = Set(filters.brands ?? [])
            self.minPrice = filters.minPrice
            self.maxPrice = filters.maxPrice
        } else {
            self.selectedCategories = []
            self.selectedBrands = []
            self.minPrice = nil
            self.maxPrice = nil
        }
    }

    func toggleCategory(_ categoryId: String) {
        if selectedCategories.contains(categoryId) {
            selectedCategories.remove(categoryId)
        } else {
            selectedCategories.insert(categoryId)
        }
    }

    func toggleBrand(_ brand: String) {
        if selectedBrands.contains(brand) {
            selectedBrands.remove(brand)
        } else {
            selectedBrands.insert(brand)
        }
    }

    func apply() -> SearchFilters {
        SearchFilters(
            categories: selectedCategories.isEmpty ? nil : Array(selectedCategories),
            brands: selectedBrands.isEmpty ? nil : Array(selectedBrands),
            minPrice: minPrice,
            maxPrice: maxPrice
        )
    }

    func reset() {
        selectedCategories = []
        selectedBrands = []
        minPrice = nil
        maxPrice = nil
    }
}
