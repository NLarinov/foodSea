import Foundation

protocol VoiceServiceProtocol: Sendable {
    func parseText(_ text: String, locale: String) async throws -> [RecognizedProduct]
}
