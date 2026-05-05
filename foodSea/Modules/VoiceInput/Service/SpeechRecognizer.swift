import Foundation
import Combine
import Speech
import AVFoundation

final class SpeechRecognizer: @unchecked Sendable {
    enum SpeechError: LocalizedError {
        case notAvailable
        case audioEngineFailed(Error)
        case requestCreationFailed

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Распознавание речи недоступно"
            case .audioEngineFailed(let err):
                return "Ошибка аудио: \(err.localizedDescription)"
            case .requestCreationFailed:
                return "Не удалось создать запрос распознавания"
            }
        }
    }

    private let recognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private let partialTextSubject = PassthroughSubject<String, Never>()
    var partialText: AnyPublisher<String, Never> {
        partialTextSubject.eraseToAnyPublisher()
    }

    private var lastTranscript: String = ""

    init(localeIdentifier: String = Constants.Voice.appleLocaleIdentifier) {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }

    func requestAuthorization() async -> Bool {
        let speechGranted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        guard speechGranted else { return false }

        let micGranted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        return micGranted
    }

    func startStreaming() throws {
        guard let recognizer, recognizer.isAvailable else {
            throw SpeechError.notAvailable
        }

        cleanupSession()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechError.audioEngineFailed(error)
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            throw SpeechError.audioEngineFailed(error)
        }

        lastTranscript = ""
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                self.lastTranscript = text
                self.partialTextSubject.send(text)
            }
            if error != nil || (result?.isFinal ?? false) {
                self.cleanupSession()
            }
        }
    }

    func stop() async -> String {
        request?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        try? await Task.sleep(nanoseconds: Constants.Voice.stopGraceNanoseconds)
        let final = lastTranscript
        cleanupSession()
        return final
    }

    private func cleanupSession() {
        task?.cancel()
        task = nil
        request = nil
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }
}
