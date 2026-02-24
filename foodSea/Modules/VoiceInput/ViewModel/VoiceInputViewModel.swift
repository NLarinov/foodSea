import Foundation
import Combine
import AVFoundation

enum VoiceInputState: Sendable {
    case idle
    case recording
    case processing
    case results
    case error(AppError)
}

final class VoiceInputViewModel {
    @Published var state: VoiceInputState = .idle
    @Published var recognizedProducts: [RecognizedProduct] = []
    @Published var recordingDuration: TimeInterval = 0

    private let voiceService: any VoiceServiceProtocol
    private let cartService: any CartServiceProtocol
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingURL: URL?

    nonisolated init(voiceService: any VoiceServiceProtocol, cartService: any CartServiceProtocol) {
        self.voiceService = voiceService
        self.cartService = cartService
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                if granted {
                    self?.beginRecording()
                } else {
                    self?.state = .error(.unknown("Доступ к микрофону запрещён"))
                }
            }
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
        processAudio()
    }

    func updateQuantity(index: Int, quantity: Int) {
        guard recognizedProducts.indices.contains(index) else { return }
        recognizedProducts[index].quantity = max(Constants.Cart.minQuantity, min(quantity, Constants.Cart.maxQuantity))
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

    private func beginRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            state = .error(.unknown(error.localizedDescription))
            return
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice_input.m4a")
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            state = .recording
            recordingDuration = 0
            startTimer()
        } catch {
            state = .error(.unknown(error.localizedDescription))
        }
    }

    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: Constants.Voice.recordingTimerInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.recordingDuration += Constants.Voice.recordingTimerInterval
            if self.recordingDuration >= Constants.Voice.maxRecordingDuration {
                self.stopRecording()
            }
        }
    }

    private func processAudio() {
        state = .processing
        Task {
            do {
                let data = (try? Data(contentsOf: recordingURL ?? URL(fileURLWithPath: ""))) ?? Data()
                let results = try await voiceService.processAudio(data)
                recognizedProducts = results
                state = results.isEmpty ? .idle : .results
            } catch {
                state = .error(error as? AppError ?? .unknown(error.localizedDescription))
            }
            cleanupRecording()
        }
    }

    private func cleanupRecording() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
    }
}
