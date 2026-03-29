import Foundation

struct MultipartFile: Sendable {
    let field: String
    let filename: String
    let mimeType: String
    let data: Data
}
