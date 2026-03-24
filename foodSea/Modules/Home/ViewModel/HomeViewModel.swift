import Foundation
import Combine

struct PromoBanner: Hashable {
    let product: Product
    let title: String
    let subtitle: String
    let color: String
}

final class HomeViewModel {
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var banners: [PromoBanner] = []
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var cartQuantities: [String: Int] = [:]
    @Published var selectedCategory: String?

    let categories = MockData.categories
    private let bannerColors = ["systemOrange", "systemBlue", "systemPurple", "systemRed", "systemGreen"]
    private let bannerLimit = 5

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
                    updateBanners()
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

    private func updateBanners() {
        let discounted = products
            .filter { ($0.maxDiscountPercent ?? 0) > 0 && $0.isAvailable }
            .sorted { ($0.maxDiscountPercent ?? 0) > ($1.maxDiscountPercent ?? 0) }
            .prefix(bannerLimit)
        banners = discounted.enumerated().map { idx, product in
            PromoBanner(
                product: product,
                title: product.name,
                subtitle: "Скидка \(product.maxDiscountPercent ?? 0)%",
                color: bannerColors[idx % bannerColors.count]
            )
        }
    }

    private func applyFilter() {
        if let categoryId = selectedCategory {
            filteredProducts = products.filter { $0.category.id == categoryId }
        } else {
            filteredProducts = products
        }
    }
}
