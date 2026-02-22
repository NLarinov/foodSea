import UIKit

final class HomeCoordinator: Coordinator {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    let container: DIContainer

    init(container: DIContainer) {
        self.container = container
        self.navigationController = UINavigationController()
        navigationController.tabBarItem = UITabBarItem(
            title: Constants.TabBar.homeTitle,
            image: UIImage(systemName: Constants.TabBar.homeIcon),
            tag: 0
        )
    }

    func start() {
        let viewModel = CatalogViewModel(
            productService: container.productService,
            cartService: container.cartService
        )
        let catalogVC = CatalogViewController(viewModel: viewModel)
        catalogVC.title = Constants.TabBar.homeTitle
        catalogVC.onProductSelected = { [weak self] product in
            self?.showProductDetail(product)
        }
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.viewControllers = [catalogVC]
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
}
