import UIKit

final class AppCoordinator {
    let window: UIWindow
    let container: DIContainer
    let tabBarController = UITabBarController()
    var childCoordinators: [Coordinator] = []

    init(window: UIWindow, container: DIContainer) {
        self.window = window
        self.container = container
    }

    func start() {
        let homeCoordinator = HomeCoordinator(container: container)
        let catalogCoordinator = CatalogTabCoordinator(container: container)
        let cartCoordinator = CartCoordinator(container: container)
        let ordersCoordinator = OrdersCoordinator(container: container)

        childCoordinators = [homeCoordinator, catalogCoordinator, cartCoordinator, ordersCoordinator]

        homeCoordinator.start()
        catalogCoordinator.start()
        cartCoordinator.start()
        ordersCoordinator.start()

        tabBarController.viewControllers = [
            homeCoordinator.navigationController,
            catalogCoordinator.navigationController,
            cartCoordinator.navigationController,
            ordersCoordinator.navigationController,
        ]

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()

        showOnboardingIfNeeded()
        setupNotifications(ordersCoordinator: ordersCoordinator)
    }

    private func showOnboardingIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Constants.Onboarding.shownKey) else { return }

        let onboardingVC = OnboardingViewController()
        onboardingVC.modalPresentationStyle = .fullScreen
        onboardingVC.onComplete = { [weak onboardingVC] in
            onboardingVC?.dismiss(animated: true) {
                NotificationManager.shared.requestPermission()
            }
        }
        tabBarController.present(onboardingVC, animated: false)
    }

    private func setupNotifications(ordersCoordinator: OrdersCoordinator) {
        if UserDefaults.standard.bool(forKey: Constants.Onboarding.shownKey) {
            NotificationManager.shared.requestPermission()
        }

        NotificationManager.shared.onOrderTapped = { [weak self] orderId in
            self?.tabBarController.selectedIndex = 3
            ordersCoordinator.showOrderDetail(orderId: orderId)
        }
    }
}
