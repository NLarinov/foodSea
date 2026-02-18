import Foundation

struct Category: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let iconName: String?
}
