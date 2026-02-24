import Foundation
import Combine

final class SearchViewModel {
    @Published var query: String = ""
    @Published var searchResults: [Product] = []
    @Published var isSearching = false
    @Published var filters: SearchFilters?
    @Published var error: AppError?

    private let productService: any ProductServiceProtocol
    private let debouncer = Debouncer()

    nonisolated init(productService: any ProductServiceProtocol) {
        self.productService = productService
    }

    func search(query: String) {
        self.query = query
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        debouncer.debounce { [weak self] in
            self?.performSearch()
        }
    }

    func applyFilters(_ filters: SearchFilters) {
        self.filters = filters
        performSearch()
    }

    func clearFilters() {
        filters = nil
        performSearch()
    }

    func clearSearch() {
        query = ""
        filters = nil
        searchResults = []
        isSearching = false
        debouncer.cancel()
    }

    private func performSearch() {
        isSearching = true
        error = nil
        Task {
            do {
                let results = try await productService.searchProducts(query: query, filters: filters)
                searchResults = results
            } catch {
                self.error = error as? AppError ?? .unknown(error.localizedDescription)
            }
            isSearching = false
        }
    }
}
