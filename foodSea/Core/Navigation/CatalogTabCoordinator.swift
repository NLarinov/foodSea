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
        let browseVC = CatalogBrowseViewController(categoryService: container.categoryService)
        browseVC.title = Constants.TabBar.catalogTitle
        browseVC.onSubcategorySelected = { [weak self] subcategory in
            self?.showSubcategoryProducts(subcategory)
        }
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.viewControllers = [browseVC]
    }

    private func showSubcategoryProducts(_ subcategory: Category) {
        let viewModel = CatalogViewModel(
            productService: container.productService,
            cartService: container.cartService,
            subcategoryId: subcategory.id
        )
        let catalogVC = CatalogViewController(viewModel: viewModel)
        catalogVC.title = subcategory.name

        catalogVC.onProductSelected = { [weak self] product in
            self?.showProductDetail(product)
        }
        catalogVC.onSearchTapped = { [weak self] in
            self?.showSearch()
        }
        catalogVC.onScannerTapped = { [weak self] in
            self?.showBarcodeScanner()
        }
        catalogVC.onVoiceTapped = { [weak self] in
            self?.showVoiceInput()
        }
        navigationController.pushViewController(catalogVC, animated: true)
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
        let searchVC = SearchViewController(
            viewModel: viewModel,
            categoryService: container.categoryService
        )
        searchVC.onProductSelected = { [weak self] product in
            self?.showProductDetail(product)
        }
        navigationController.pushViewController(searchVC, animated: true)
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
