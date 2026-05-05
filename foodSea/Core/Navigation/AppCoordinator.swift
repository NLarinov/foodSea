import UIKit

final class AppCoordinator {
    let window: UIWindow
    let container: DIContainer
    private let tokenStore: AuthTokenStore
    private let tabBarController = UITabBarController()
    private var childCoordinators: [Coordinator] = []
    private let cartTabIndex = 2

    init(window: UIWindow, container: DIContainer, tokenStore: AuthTokenStore) {
        self.window = window
        self.container = container
        self.tokenStore = tokenStore
    }

    func start() {
        NotificationCenter.default.addObserver(
            forName: .sessionExpired, object: nil, queue: .main
        ) { [weak self] _ in
            self?.showAuth(animated: true)
        }

        if tokenStore.hasToken {
            showMain()
        } else {
            showAuth(animated: false)
        }
    }

    // MARK: - Navigation

    private func showMain() {
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
            ordersCoordinator.navigationController
        ]

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()

        showOnboardingIfNeeded()
        setupNotifications(ordersCoordinator: ordersCoordinator)
        observeCartChanges()
    }

    private func showAuth(animated: Bool) {
        childCoordinators = []
        let welcomeVM = WelcomeViewModel(authService: container.authService)
        let nav: UINavigationController
        weak var weakSelf = self
        weak var weakNav: UINavigationController?

        welcomeVM.onSuccess = {
            weakSelf?.showMain()
        }
        welcomeVM.onContinueWithEmail = {
            guard let strongSelf = weakSelf else { return }
            let authVM = AuthViewModel(authService: strongSelf.container.authService)
            authVM.onSuccess = {
                weakSelf?.showMain()
            }
            let authVC = AuthViewController(viewModel: authVM)
            weakNav?.pushViewController(authVC, animated: true)
        }

        let welcomeVC = WelcomeViewController(viewModel: welcomeVM)
        nav = UINavigationController(rootViewController: welcomeVC)
        weakNav = nav

        if animated, let snapshot = window.snapshotView(afterScreenUpdates: false) {
            nav.view.addSubview(snapshot)
            window.rootViewController = nav
            window.makeKeyAndVisible()
            UIView.animate(withDuration: Constants.Animation.defaultDuration) {
                snapshot.alpha = 0
            } completion: { _ in
                snapshot.removeFromSuperview()
            }
        } else {
            window.rootViewController = nav
            window.makeKeyAndVisible()
        }
    }

    // MARK: - Helpers

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

    private func observeCartChanges() {
        NotificationCenter.default.addObserver(
            forName: .cartDidChange, object: nil, queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let count = notification.userInfo?[Constants.Cart.itemCountKey] as? Int ?? -1
            guard count >= 0 else { return }
            let badge = count > 0 ? "\(count)" : nil
            tabBarController.viewControllers?[cartTabIndex].tabBarItem.badgeValue = badge
        }
    }
}
