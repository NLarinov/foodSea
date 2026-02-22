import Foundation
import Combine

final class CatalogViewModel {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var addedToCartMessage: String?

    private let productService: any ProductServiceProtocol
    private let cartService: any CartServiceProtocol
    private var currentPage = 0
    private var hasMorePages = true

    nonisolated init(productService: any ProductServiceProtocol, cartService: any CartServiceProtocol) {
        self.productService = productService
        self.cartService = cartService
    }

    func loadProducts() {
        currentPage = 0
        hasMorePages = true
        products = []
        fetchPage()
    }

    func loadNextPage() {
        guard !isLoading, hasMorePages else { return }
        fetchPage()
    }

    func refresh() {
        loadProducts()
    }

    func addToCart(product: Product) {
        Task {
            do {
                try await cartService.addItem(productId: product.id, quantity: Constants.Cart.minQuantity)
                addedToCartMessage = Constants.Strings.addedToCart
            } catch {
                self.error = error as? AppError ?? .unknown(error.localizedDescription)
            }
        }
    }

    private func fetchPage() {
        isLoading = true
        error = nil
        Task {
            do {
                let fetched = try await productService.fetchProducts(
                    page: currentPage,
                    perPage: Constants.API.itemsPerPage
                )
                if fetched.count < Constants.API.itemsPerPage {
                    hasMorePages = false
                }
                products.append(contentsOf: fetched)
                currentPage += 1
            } catch {
                self.error = error as? AppError ?? .unknown(error.localizedDescription)
            }
            isLoading = false
        }
    }
}
