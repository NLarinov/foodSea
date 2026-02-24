import UIKit

final class OrdersCoordinator: Coordinator {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    let container: DIContainer

    init(container: DIContainer) {
        self.container = container
        self.navigationController = UINavigationController()
        navigationController.tabBarItem = UITabBarItem(
            title: Constants.TabBar.ordersTitle,
            image: UIImage(systemName: Constants.TabBar.ordersIcon),
            tag: 3
        )
    }

    func start() {
        let viewModel = OrderHistoryViewModel(orderService: container.orderService)
        let historyVC = OrderHistoryViewController(viewModel: viewModel)
        historyVC.onOrderSelected = { [weak self] orderId in
            self?.showOrderDetail(orderId: orderId)
        }
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.viewControllers = [historyVC]
    }

    func showOrderDetail(orderId: String) {
        let viewModel = OrderDetailViewModel(orderId: orderId, orderService: container.orderService)
        let detailVC = OrderDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(detailVC, animated: true)
    }
}
