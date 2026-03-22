import Foundation
import Combine

final class HomeViewModel {
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var cartQuantities: [String: Int] = [:]
    @Published var selectedCategory: String?

    let categories = MockData.categories
    let banners = MockData.promoBanners

    private let productService: any ProductServiceProtocol
    private let cartService: any CartServiceProtocol
    private var currentPage = 1
    private var hasMorePages = true

    nonisolated init(productService: any ProductServiceProtocol, cartService: any CartServiceProtocol) {
        self.productService = productService
        self.cartService = cartService
    }

    func loadProducts() {
        currentPage = 1
        hasMorePages = true
        products = []
        applyFilter()
        fetchPage()
        refreshCartQuantities()
    }

    func loadNextPage() {
        guard !isLoading, hasMorePages else { return }
        fetchPage()
    }

    private func fetchPage() {
        isLoading = true
        Task {
            do {
                let fetched = try await productService.fetchProducts(
                    page: currentPage,
                    perPage: Constants.API.itemsPerPage
                )
                if fetched.count < Constants.API.itemsPerPage {
                    hasMorePages = false
                }
                let existingIds = Set(products.map(\.id))
                let newItems = fetched.filter { !existingIds.contains($0.id) }
                if newItems.isEmpty {
                    hasMorePages = false
                } else {
                    products.append(contentsOf: newItems)
                    applyFilter()
                }
                currentPage += 1
            } catch {
                self.error = error as? AppError ?? .unknown(error.localizedDescription)
            }
            isLoading = false
        }
    }

    func selectCategory(_ categoryId: String?) {
        selectedCategory = categoryId
        applyFilter()
    }

    func addToCart(product: Product) {
        Task {
            do {
                try await cartService.addItem(productId: product.id, quantity: Constants.Cart.minQuantity)
                refreshCartQuantities()
            } catch {}
        }
    }

    func updateCartQuantity(productId: String, quantity: Int) {
        Task {
            do {
                let items = try await cartService.getCartItems()
                if let item = items.first(where: { $0.product.id == productId }) {
                    if quantity <= 0 {
                        try await cartService.removeItem(itemId: item.id)
                    } else {
                        try await cartService.updateItemQuantity(itemId: item.id, quantity: quantity)
                    }
                }
                refreshCartQuantities()
            } catch {}
        }
    }

    func refreshCartQuantities() {
        Task {
            do {
                let items = try await cartService.getCartItems()
                var quantities: [String: Int] = [:]
                for item in items {
                    quantities[item.product.id] = item.quantity
                }
                cartQuantities = quantities
            } catch {}
        }
    }

    func quantity(for productId: String) -> Int {
        cartQuantities[productId] ?? 0
    }

    func product(for bannerId: String) -> Product? {
        MockData.products.first { $0.id == bannerId }
    }

    private func applyFilter() {
        if let categoryId = selectedCategory {
            filteredProducts = products.filter { $0.category.id == categoryId }
        } else {
            filteredProducts = products
        }
    }
}
