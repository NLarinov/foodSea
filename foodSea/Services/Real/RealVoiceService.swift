import Foundation

final class RealVoiceService: VoiceServiceProtocol, @unchecked Sendable {
    private let coreClient: NetworkClient
    private let productService: any ProductServiceProtocol

    init(coreClient: NetworkClient, productService: any ProductServiceProtocol) {
        self.coreClient = coreClient
        self.productService = productService
    }

    func parseText(_ text: String, locale: String) async throws -> [RecognizedProduct] {
        let response: VoiceParseResponseDTO = try await coreClient.request(
            .parseVoice(text: text, locale: locale)
        )

        var recognised: [RecognizedProduct] = []
        for item in response.items {
            let product: Product
            do {
                product = try await productService.fetchProduct(id: item.productId)
            } catch {
                continue
            }
            recognised.append(RecognizedProduct(
                product: product,
                confidence: item.confidence,
                quantity: item.quantity,
                unit: item.unit,
                rawQuery: item.rawQuery
            ))
        }
        return recognised
    }
}
