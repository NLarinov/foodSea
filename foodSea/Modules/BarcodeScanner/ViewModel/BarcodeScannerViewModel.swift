import Foundation
import Combine

enum BarcodeScannerState: Sendable {
    case idle
    case scanning
    case found(Product)
    case notFound
    case error(AppError)
}

final class BarcodeScannerViewModel {
    @Published var state: BarcodeScannerState = .idle
    @Published var isProcessing = false

    private let productService: any ProductServiceProtocol

    nonisolated init(productService: any ProductServiceProtocol) {
        self.productService = productService
    }

    func lookup(barcode: String) {
        guard !barcode.isEmpty else { return }
        isProcessing = true
        state = .scanning
        Task {
            do {
                if let product = try await productService.findByBarcode(barcode) {
                    state = .found(product)
                } else {
                    state = .notFound
                }
            } catch {
                state = .error(error as? AppError ?? .unknown(error.localizedDescription))
            }
            isProcessing = false
        }
    }
}
