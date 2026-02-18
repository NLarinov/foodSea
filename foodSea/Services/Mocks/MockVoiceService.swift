import Foundation

final class MockVoiceService: VoiceServiceProtocol, @unchecked Sendable {
    func processAudio(_ data: Data) async throws -> [RecognizedProduct] {
        try await Task.sleep(nanoseconds: Constants.Mock.longDelay)
        return []
    }
}
