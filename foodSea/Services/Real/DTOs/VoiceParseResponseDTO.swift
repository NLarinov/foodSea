import Foundation

struct VoiceParseResponseDTO: Decodable, Sendable {
    let items: [VoiceItemDTO]
    let unmatchedQueries: [String]
}

struct VoiceItemDTO: Decodable, Sendable {
    let productId: String
    let productName: String
    let quantity: Int
    let unit: String
    let confidence: Double
    let rawQuery: String
}
