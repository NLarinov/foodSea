import Foundation

struct PhotoSearchResponseDTO: Decodable {
    let matchedName: String?
    let matchedBrand: String?
    let candidates: [PhotoSearchCandidateDTO]
}

struct PhotoSearchCandidateDTO: Decodable {
    let product: ProductDetailDTO
    let score: Double
    let source: String?
}
