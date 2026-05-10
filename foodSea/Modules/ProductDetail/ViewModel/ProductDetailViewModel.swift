import Foundation
import Combine

final class ProductDetailViewModel {
    @Published var product: Product?
    @Published var similarProducts: [Product] = []
    @Published var quantity: Int = 1
    @Published var isLoading = false
    @Published var addedToCart = false
    @Published var error: AppError?

    let productId: String
    private let productService: any ProductServiceProtocol
    private let cartService: any CartServiceProtocol

    nonisolated init(
        productId: String,
        productService: any ProductServiceProtocol,
        cartService: any CartServiceProtocol,
        initialProduct: Product? = nil
    ) {
        self.productId = productId
        self.productService = productService
        self.cartService = cartService
        self.product = initialProduct
    }

    func loadProduct() {
        if product == nil { isLoading = true }
        error = nil
        Task {
            do {
                product = try await productService.fetchProduct(id: productId)
            } catch {
                self.error = error as? AppError ?? .unknown(error.localizedDescription)
            }
            isLoading = false
        }
    }

    func loadSimilarProducts() {
        Task {
            do {
                similarProducts = try await productService.fetchSimilarProducts(productId: productId)
            } catch {
                self.error = error as? AppError ?? .unknown(error.localizedDescription)
            }
        }
    }

    func addToCart() {
        guard let product, product.isAvailable else { return }
        Task {
            do {
                try await cartService.addItem(productId: product.id, quantity: quantity)
                addedToCart = true
            } catch {
                self.error = error as? AppError ?? .unknown(error.localizedDescription)
            }
        }
    }

    func incrementQuantity() {
        guard quantity < Constants.Cart.maxQuantity else { return }
        quantity += 1
    }

    func decrementQuantity() {
        guard quantity > Constants.Cart.minQuantity else { return }
        quantity -= 1
    }
}
