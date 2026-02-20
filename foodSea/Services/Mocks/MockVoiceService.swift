import Foundation

final class MockVoiceService: VoiceServiceProtocol, @unchecked Sendable {
    func processAudio(_ data: Data) async throws -> [RecognizedProduct] {
        try await Task.sleep(nanoseconds: Constants.Mock.longDelay)
        let sampleProducts = Array(MockData.products.shuffled().prefix(3))
        return sampleProducts.map { product in
            RecognizedProduct(
                product: product,
                confidence: Double.random(in: 0.75...0.99),
                quantity: Int.random(in: 1...3)
            )
        }
    }
}
