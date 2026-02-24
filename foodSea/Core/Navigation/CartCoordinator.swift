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
        let viewModel = CartViewModel(cartService: container.cartService)
        let cartVC = CartViewController(viewModel: viewModel)
        cartVC.onProductSelected = { [weak self] product in
            self?.showProductDetail(product)
        }
        cartVC.onGoToCatalog = { [weak self] in
            self?.switchToCatalog()
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

    private func switchToCatalog() {
        navigationController.tabBarController?.selectedIndex = 1
    }
}
