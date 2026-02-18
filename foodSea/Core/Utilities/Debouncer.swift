import Foundation

final class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?

    init(delay: TimeInterval = Constants.Search.debounceInterval) {
        self.delay = delay
    }

    func debounce(action: @escaping @Sendable () -> Void) {
        workItem?.cancel()
        let item = DispatchWorkItem(block: action)
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}
