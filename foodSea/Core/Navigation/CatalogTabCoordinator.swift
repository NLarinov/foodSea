import UIKit

final class CatalogTabCoordinator: Coordinator {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    let container: DIContainer

    init(container: DIContainer) {
        self.container = container
        self.navigationController = UINavigationController()
        navigationController.tabBarItem = UITabBarItem(
            title: Constants.TabBar.catalogTitle,
            image: UIImage(systemName: Constants.TabBar.catalogIcon),
            tag: 1
        )
    }

    func start() {
        let viewModel = CatalogViewModel(
            productService: container.productService,
            cartService: container.cartService
        )
        let catalogVC = CatalogViewController(viewModel: viewModel)
        catalogVC.onProductSelected = { [weak self] product in
            self?.showProductDetail(product)
        }
        catalogVC.onSearchTapped = { [weak self] in
            self?.showSearch()
        }
        catalogVC.onScannerTapped = { [weak self] in
            self?.showBarcodeScanner()
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

    private func showSearch() {
        let viewModel = SearchViewModel(productService: container.productService)
        let searchVC = SearchViewController(viewModel: viewModel)
        searchVC.onProductSelected = { [weak self] product in
            self?.showProductDetail(product)
        }
        navigationController.pushViewController(searchVC, animated: true)
    }

    private func showBarcodeScanner() {
        let viewModel = BarcodeScannerViewModel(productService: container.productService)
        let scannerVC = BarcodeScannerViewController(viewModel: viewModel)
        scannerVC.modalPresentationStyle = .fullScreen
        scannerVC.onProductFound = { [weak self] product in
            scannerVC.dismiss(animated: true) {
                self?.showProductDetail(product)
            }
        }
        scannerVC.onClose = {
            scannerVC.dismiss(animated: true)
        }
        navigationController.present(scannerVC, animated: true)
    }
}
