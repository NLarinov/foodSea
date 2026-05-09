import Foundation
import Combine

enum VoiceInputState: Sendable {
    case idle
    case listening(partialText: String)
    case processing
    case results
    case error(AppError)
}

final class VoiceInputViewModel {
    @Published var state: VoiceInputState = .idle
    @Published var recognizedProducts: [RecognizedProduct] = []
    @Published var recordingDuration: TimeInterval = 0

    private let speechRecognizer: SpeechRecognizer
    private let voiceService: any VoiceServiceProtocol
    private let cartService: any CartServiceProtocol

    private var speechCancellable: AnyCancellable?
    private var durationTimer: Timer?
    private var sessionStart: Date?

    nonisolated init(
        voiceService: any VoiceServiceProtocol,
        cartService: any CartServiceProtocol,
        speechRecognizer: SpeechRecognizer = SpeechRecognizer()
    ) {
        self.voiceService = voiceService
        self.cartService = cartService
        self.speechRecognizer = speechRecognizer
    }

    func startRecording() {
        Task { @MainActor in
            let granted = await speechRecognizer.requestAuthorization()
            guard granted else {
                state = .error(.unknown("Доступ к распознаванию речи запрещён"))
                return
            }
            beginListening()
        }
    }

    func stopRecording() {
        Task { @MainActor in
            speechCancellable?.cancel()
            speechCancellable = nil
            stopDurationTimer()
            let finalText = await speechRecognizer.stop()
            await processFinalText(finalText)
        }
    }

    func updateQuantity(index: Int, quantity: Int) {
        guard recognizedProducts.indices.contains(index) else { return }
        recognizedProducts[index].quantity = max(
            Constants.Cart.minQuantity,
            min(quantity, Constants.Cart.maxQuantity)
        )
    }

    func removeProduct(index: Int) {
        guard recognizedProducts.indices.contains(index) else { return }
        recognizedProducts.remove(at: index)
        if recognizedProducts.isEmpty {
            state = .idle
        }
    }

    func addAllToCart() {
        Task {
            for item in recognizedProducts {
                try? await cartService.addItem(productId: item.product.id, quantity: item.quantity)
            }
            recognizedProducts = []
            state = .idle
        }
    }

    func reset() {
        recognizedProducts = []
        recordingDuration = 0
        state = .idle
    }

    private func beginListening() {
        do {
            try speechRecognizer.startStreaming()
        } catch {
            state = .error(.unknown(error.localizedDescription))
            return
        }

        recordingDuration = 0
        sessionStart = Date()
        state = .listening(partialText: "")
        startDurationTimer()

        speechCancellable = speechRecognizer.partialText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self else { return }
                if case .listening = self.state {
                    self.state = .listening(partialText: text)
                }
            }
    }

    private func processFinalText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }
        state = .processing
        do {
            let items = try await voiceService.parseText(trimmed, locale: Constants.Voice.locale)
            recognizedProducts = items
            state = items.isEmpty ? .idle : .results
        } catch let error as AppError {
            state = .error(error)
        } catch {
            state = .error(.unknown(error.localizedDescription))
        }
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.Voice.recordingTimerInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self, let start = self.sessionStart else { return }
            self.recordingDuration = Date().timeIntervalSince(start)
            if self.recordingDuration >= Constants.Voice.maxRecordingDuration {
                self.stopRecording()
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
}
