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

    init(useMocks: Bool = true) {
        self.useMocks = useMocks
        defer {
            Task { @MainActor in
                OrderProgressTracker.shared.configure(orderService: self.orderService)
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
        }
    }
}
