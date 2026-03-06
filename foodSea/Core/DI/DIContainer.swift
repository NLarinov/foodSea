import Foundation

final class DIContainer: @unchecked Sendable {
    let useMocks: Bool
    let authService: any AuthServiceProtocol
    let productService: any ProductServiceProtocol
    let cartService: any CartServiceProtocol
    let orderService: any OrderServiceProtocol
    let optimizationService: any OptimizationServiceProtocol
    let voiceService: any VoiceServiceProtocol

    init(useMocks: Bool = true) {
        self.useMocks = useMocks
        if useMocks {
            authService = MockAuthService()
            productService = MockProductService()
            cartService = MockCartService()
            orderService = MockOrderService()
            optimizationService = MockOptimizationService()
            voiceService = MockVoiceService()
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
            authService = RealAuthService(client: coreClient, tokenStore: tokenStore)
            productService = RealProductService(coreClient: coreClient, optClient: optClient)
            cartService = RealCartService(client: coreClient)
            optimizationService = RealOptimizationService(client: optClient)
            orderService = RealOrderService(client: ordClient)
            voiceService = MockVoiceService()
        }
    }
}
