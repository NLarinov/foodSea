import Foundation

nonisolated struct Category: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let slug: String
    let parentId: String?
    let sortOrder: Int
    let children: [Category]

    init(
        id: String,
        name: String,
        slug: String = "",
        parentId: String? = nil,
        sortOrder: Int = 0,
        children: [Category] = []
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.parentId = parentId
        self.sortOrder = sortOrder
        self.children = children
    }
}
