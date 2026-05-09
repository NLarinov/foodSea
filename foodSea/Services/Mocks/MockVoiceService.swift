import Foundation

final class MockVoiceService: VoiceServiceProtocol, @unchecked Sendable {
    func parseText(_ text: String, locale: String) async throws -> [RecognizedProduct] {
        try await Task.sleep(nanoseconds: Constants.Mock.longDelay)
        let sampleProducts = Array(MockData.products.shuffled().prefix(3))
        let tokens = text.split(separator: " ").map(String.init)
        return sampleProducts.enumerated().map { index, product in
            RecognizedProduct(
                product: product,
                confidence: Double.random(in: 0.75...0.99),
                quantity: Int.random(in: 1...3),
                unit: Constants.Voice.unitFallback,
                rawQuery: tokens.indices.contains(index) ? tokens[index] : product.name
            )
        }
    }
}
