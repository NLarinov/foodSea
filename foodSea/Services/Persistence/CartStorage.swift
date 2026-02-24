import Foundation

final class CartStorage {
    private let defaults = UserDefaults.standard

    func save(_ items: [CartItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: Constants.Cart.storageKey)
    }

    func load() -> [CartItem] {
        guard let data = defaults.data(forKey: Constants.Cart.storageKey),
              let items = try? JSONDecoder().decode([CartItem].self, from: data) else {
            return []
        }
        return items
    }

    func clear() {
        defaults.removeObject(forKey: Constants.Cart.storageKey)
    }
}
