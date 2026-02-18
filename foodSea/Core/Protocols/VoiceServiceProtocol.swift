import Foundation

protocol VoiceServiceProtocol: Sendable {
    func processAudio(_ data: Data) async throws -> [RecognizedProduct]
}
