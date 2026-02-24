import UIKit

final class CartCoordinator: Coordinator {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    let container: DIContainer

    init(container: DIContainer) {
        self.container = container
        self.navigationController = UINavigationController()
        navigationController.tabBarItem = UITabBarItem(
            title: Constants.TabBar.cartTitle,
            image: UIImage(systemName: Constants.TabBar.cartIcon),
            tag: 2
        )
    }

    func start() {
        let viewModel = CartViewModel(cartService: container.cartService, productService: container.productService)
        let cartVC = CartViewController(viewModel: viewModel)
        cartVC.onProductSelected = { [weak self] product in
            self?.showProductDetail(product)
        }
        cartVC.onGoToCatalog = { [weak self] in
            self?.switchToCatalog()
        }
        cartVC.onOptimize = { [weak self] in
            self?.showOptimization(cartItems: viewModel.cartItems)
        }
        cartVC.onVoiceInput = { [weak self] in
            self?.showVoiceInput()
        }
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.viewControllers = [cartVC]
    }

    private func showProductDetail(_ product: Product) {
        let viewModel = ProductDetailViewModel(
            productId: product.id,
            productService: container.productService,
            cartService: container.cartService
        )
        let detailVC = ProductDetailViewController(viewModel: viewModel)
        detailVC.onSimilarProductSelected = { [weak self] product in
            self?.showProductDetail(product)
        }
        navigationController.pushViewController(detailVC, animated: true)
    }

    private func showOptimization(cartItems: [CartItem]) {
        let viewModel = OptimizationViewModel(
            cartItems: cartItems,
            optimizationService: container.optimizationService,
            cartService: container.cartService
        )
        let optimizationVC = OptimizationResultsViewController(viewModel: viewModel)
        optimizationVC.onApply = { [weak self] result in
            self?.showCheckout(result: result)
        }
        optimizationVC.onBackToCart = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(optimizationVC, animated: true)
    }

    private func showCheckout(result: OptimizationResult) {
        let viewModel = OrderCheckoutViewModel(
            optimizationResult: result,
            orderService: container.orderService
        )
        let checkoutVC = OrderCheckoutViewController(viewModel: viewModel)
        checkoutVC.onOrderCreated = { [weak self] order in
            self?.showConfirmation(order: order)
        }
        navigationController.pushViewController(checkoutVC, animated: true)
    }

    private func showConfirmation(order: Order) {
        clearCartAfterOrder()

        let confirmVC = OrderConfirmationViewController(order: order)
        confirmVC.onGoToOrders = { [weak self] in
            self?.navigationController.popToRootViewController(animated: false)
            self?.navigationController.tabBarController?.selectedIndex = 3
        }
        confirmVC.onGoToCatalog = { [weak self] in
            self?.navigationController.popToRootViewController(animated: false)
            self?.switchToCatalog()
        }
        navigationController.pushViewController(confirmVC, animated: true)
    }

    private func clearCartAfterOrder() {
        Task {
            try? await container.cartService.clearCart()
        }
        CartStorage().clear()
    }

    private func showVoiceInput() {
        let viewModel = VoiceInputViewModel(
            voiceService: container.voiceService,
            cartService: container.cartService
        )
        let voiceVC = VoiceInputViewController(viewModel: viewModel)
        let navVC = UINavigationController(rootViewController: voiceVC)
        voiceVC.onAddedToCart = { [weak navVC] in
            navVC?.dismiss(animated: true)
        }
        voiceVC.onClose = { [weak navVC] in
            navVC?.dismiss(animated: true)
        }
        navigationController.present(navVC, animated: true)
    }

    private func switchToCatalog() {
        navigationController.tabBarController?.selectedIndex = 1
    }
}
