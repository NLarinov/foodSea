import Foundation

nonisolated struct Brand: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
}
