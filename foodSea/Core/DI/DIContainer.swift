import Foundation
import YandexLoginSDK

final class DIContainer: @unchecked Sendable {
    let useMocks: Bool
    let authService: any AuthServiceProtocol
    let productService: any ProductServiceProtocol
    let cartService: any CartServiceProtocol
    let orderService: any OrderServiceProtocol
    let optimizationService: any OptimizationServiceProtocol
    let voiceService: any VoiceServiceProtocol
    let categoryService: any CategoryServiceProtocol
    let notificationsService: NotificationsService?

    init(useMocks: Bool = true) {
        self.useMocks = useMocks
        defer {
            let notifications = self.notificationsService
            Task { @MainActor in
                OrderProgressTracker.shared.configure(orderService: self.orderService)
                if #available(iOS 16.1, *) {
                    LiveActivityManager.shared.configure(notifications: notifications)
                }
                NotificationsRegistrar.shared.configure(service: notifications)
            }
        }
        if useMocks {
            authService = MockAuthService()
            productService = MockProductService()
            cartService = MockCartService()
            orderService = MockOrderService()
            optimizationService = MockOptimizationService()
            voiceService = MockVoiceService()
            categoryService = MockCategoryService()
            notificationsService = nil
        } else {
            let tokenStore = AuthTokenStore()
            let coreURL = Constants.API.coreBaseURL
            let coreClient = NetworkClient(baseURL: coreURL, tokenStore: tokenStore)
            let optClient = NetworkClient(
                baseURL: Constants.API.optimizationBaseURL,
                refreshBaseURL: coreURL,
                tokenStore: tokenStore
            )
            let ordClient = NetworkClient(
                baseURL: Constants.API.orderingBaseURL,
                refreshBaseURL: coreURL,
                tokenStore: tokenStore
            )
            if !Constants.OAuth.yandexClientID.isEmpty {
                try? YandexLoginSDK.shared.activate(with: Constants.OAuth.yandexClientID)
            }
            let yandexAuthorizer = RealYandexAuthorizer()
            let oauthService = RealOAuthService(client: coreClient, yandexAuthorizer: yandexAuthorizer)
            authService = RealAuthService(client: coreClient, tokenStore: tokenStore, oauthService: oauthService)
            let realProductService = RealProductService(coreClient: coreClient, optClient: optClient)
            productService = realProductService
            cartService = RealCartService(client: coreClient)
            optimizationService = RealOptimizationService(client: optClient)
            orderService = RealOrderService(client: ordClient)
            voiceService = RealVoiceService(coreClient: coreClient, productService: realProductService)
            categoryService = RealCategoryService(client: coreClient)
            notificationsService = NotificationsService(client: coreClient)
        }
    }
}

final class NotificationsService: @unchecked Sendable {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    func registerDevice(token: String, appVersion: String?) async throws {
        try await client.requestEmpty(.registerDevice(token: token, appVersion: appVersion))
    }

    func registerLiveActivity(orderId: String, pushToken: String) async throws {
        try await client.requestEmpty(.registerLiveActivity(orderId: orderId, pushToken: pushToken))
    }

    func removeLiveActivity(orderId: String) async throws {
        try await client.requestEmpty(.unregisterLiveActivity(orderId: orderId))
    }
}

final class NotificationsRegistrar: @unchecked Sendable {
    static let shared = NotificationsRegistrar()

    private let queue = DispatchQueue(label: "foodsea.pushRegistrar")
    private var service: NotificationsService?

    private init() {}

    func configure(service: NotificationsService?) {
        queue.async {
            self.service = service
            self.tryRegister()
        }
    }

    func tokenChanged() {
        queue.async { self.tryRegister() }
    }

    private func tryRegister() {
        guard let service else { return }
        guard let token = UserDefaults.standard.string(forKey: Constants.PushTokens.apnsTokenKey) else { return }
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        Task {
            try? await service.registerDevice(token: token, appVersion: appVersion)
        }
    }
}
