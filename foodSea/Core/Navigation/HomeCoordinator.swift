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
        let viewModel = HomeViewModel(
            productService: container.productService,
            cartService: container.cartService,
            categoryService: container.categoryService
        )
        let homeVC = HomeViewController(viewModel: viewModel)
        homeVC.onProductSelected = { [weak self] product in
            self?.showProductDetail(product)
        }
        homeVC.onSearchTapped = { [weak self] in
            self?.showSearch()
        }
        homeVC.onScannerTapped = { [weak self] in
            self?.showBarcodeScanner()
        }
        homeVC.onVoiceTapped = { [weak self] in
            self?.showVoiceInput()
        }
        homeVC.onPhotoSearchTapped = { [weak self] in
            self?.showPhotoSearch()
        }
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.viewControllers = [homeVC]
    }

    private func showProductDetail(_ product: Product) {
        let viewModel = ProductDetailViewModel(
            productId: product.id,
            productService: container.productService,
            cartService: container.cartService,
            initialProduct: product
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
        voiceVC.onAddedToCart = { [weak self, weak navVC] in
            navVC?.dismiss(animated: true) {
                self?.navigationController.tabBarController?.selectedIndex = 2
            }
        }
        voiceVC.onClose = { [weak navVC] in
            navVC?.dismiss(animated: true)
        }
        navigationController.present(navVC, animated: true)
    }

    private func showPhotoSearch() {
        let viewModel = PhotoSearchViewModel(productService: container.productService)
        let photoVC = PhotoSearchViewController(viewModel: viewModel)
        photoVC.modalPresentationStyle = .fullScreen
        photoVC.onProductFound = { [weak self] product in
            photoVC.dismiss(animated: true) {
                self?.showProductDetail(product)
            }
        }
        photoVC.onClose = {
            photoVC.dismiss(animated: true)
        }
        navigationController.present(photoVC, animated: true)
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
