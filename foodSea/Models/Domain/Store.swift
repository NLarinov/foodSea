import Foundation

nonisolated struct Store: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let logoURL: URL?
}
