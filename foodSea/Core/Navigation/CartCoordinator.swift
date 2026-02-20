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
        let placeholder = makePlaceholder(title: Constants.TabBar.cartTitle)
        navigationController.viewControllers = [placeholder]
    }

    private func makePlaceholder(title: String) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.App.background
        vc.title = title
        vc.navigationItem.largeTitleDisplayMode = .always
        navigationController.navigationBar.prefersLargeTitles = true
        return vc
    }
}
