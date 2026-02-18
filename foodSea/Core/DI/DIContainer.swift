import Foundation

final class DIContainer: @unchecked Sendable {
    let useMocks: Bool

    init(useMocks: Bool = true) {
        self.useMocks = useMocks
    }

    lazy var productService: any ProductServiceProtocol = {
        if useMocks {
            return MockProductService()
        }
        fatalError("Real ProductService not implemented")
    }()

    lazy var cartService: any CartServiceProtocol = {
        if useMocks {
            return MockCartService()
        }
        fatalError("Real CartService not implemented")
    }()

    lazy var orderService: any OrderServiceProtocol = {
        if useMocks {
            return MockOrderService()
        }
        fatalError("Real OrderService not implemented")
    }()

    lazy var optimizationService: any OptimizationServiceProtocol = {
        if useMocks {
            return MockOptimizationService()
        }
        fatalError("Real OptimizationService not implemented")
    }()

    lazy var voiceService: any VoiceServiceProtocol = {
        if useMocks {
            return MockVoiceService()
        }
        fatalError("Real VoiceService not implemented")
    }()
}
