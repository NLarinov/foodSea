import Foundation

final class RealProductService: ProductServiceProtocol, @unchecked Sendable {
    private let coreClient: NetworkClient
    private let optClient: NetworkClient

    init(coreClient: NetworkClient, optClient: NetworkClient) {
        self.coreClient = coreClient
        self.optClient = optClient
    }

    func fetchProducts(
        page: Int,
        perPage: Int,
        categoryId: String?,
        subcategoryId: String?,
        brandId: String?
    ) async throws -> [Product] {
        let dtos: [ProductBriefDTO] = try await coreClient.request(.listProducts(
            page: page,
            perPage: perPage,
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            brandId: brandId
        ))
        return dtos.map { $0.toDomain() }
    }

    func fetchProduct(id: String) async throws -> Product {
        async let detailTask: ProductDetailDTO = coreClient.request(.getProduct(id: id))
        async let offersTask: [OfferDTO] = coreClient.request(.getOffers(productId: id))
        let (detail, offers) = try await (detailTask, offersTask)
        return detail.toDomain(offers: offers)
    }

    func searchProducts(query: String, filters: SearchFilters?) async throws -> [Product] {
        let dtos: [SearchResultItemDTO] = try await coreClient.request(.searchProducts(query: query, filters: filters))
        return dtos.map { $0.toDomain() }
    }

    func fetchSimilarProducts(productId: String) async throws -> [Product] {
        let response: AnalogsResponseDTO = try await optClient.request(.getAnalogs(productId: productId))
        return response.analogs.map { $0.toDomain() }
    }

    func findByBarcode(_ barcode: String) async throws -> Product? {
        do {
            let detail: ProductDetailDTO = try await coreClient.request(.getProductByBarcode(code: barcode))
            let offers: [OfferDTO] = try await coreClient.request(.getOffers(productId: detail.id))
            return detail.toDomain(offers: offers)
        } catch AppError.notFound {
            return nil
        }
    }
}
