import Foundation
import Combine
import Vision
import ImageIO

enum PhotoSearchState: Sendable {
    case idle
    case processing
    case notFound
    case failed(AppError)
}

final class PhotoSearchViewModel {
    @Published var state: PhotoSearchState = .idle

    var onProductFound: ((Product) -> Void)?

    private let productService: any ProductServiceProtocol

    nonisolated init(productService: any ProductServiceProtocol) {
        self.productService = productService
    }

    func process(imageJPEG: Data) {
        state = .processing
        Task { [weak self] in
            guard let self else { return }
            async let ocrTask = Self.recognizeText(jpeg: imageJPEG)
            let recognized = await ocrTask
            let ocrText = Self.normalize(ocr: recognized)
            do {
                let product = try await productService.searchByPhoto(
                    imageJPEG: imageJPEG,
                    ocrText: ocrText,
                    topK: Constants.PhotoSearch.topK
                )
                await MainActor.run {
                    if let product {
                        self.onProductFound?(product)
                    } else {
                        self.state = .notFound
                    }
                }
            } catch let appErr as AppError {
                await MainActor.run { self.state = .failed(appErr) }
            } catch {
                await MainActor.run {
                    self.state = .failed(.unknown(error.localizedDescription))
                }
            }
        }
    }

    func reset() {
        state = .idle
    }

    private static func normalize(ocr: String) -> String {
        let trimmed = ocr.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < Constants.PhotoSearch.minOCRLength {
            return Constants.PhotoSearch.fallbackOCR
        }
        if trimmed.count > Constants.PhotoSearch.maxOCRLength {
            return String(trimmed.prefix(Constants.PhotoSearch.maxOCRLength))
        }
        return trimmed
    }

    private static func recognizeText(jpeg: Data) async -> String {
        await withCheckedContinuation { continuation in
            guard let source = CGImageSourceCreateWithData(jpeg as CFData, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                continuation.resume(returning: "")
                return
            }
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: " "))
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ru-RU", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: "")
                }
            }
        }
    }
}
