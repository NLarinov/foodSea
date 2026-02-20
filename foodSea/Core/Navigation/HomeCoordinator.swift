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
        let placeholder = makePlaceholder(title: Constants.TabBar.homeTitle)
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
