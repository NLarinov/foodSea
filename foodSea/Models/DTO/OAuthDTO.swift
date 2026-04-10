import Foundation

struct OAuthStartResponseDTO: Decodable {
    let authUrl: String
    let state: String
}

struct OAuthCallbackRequestDTO: Encodable {
    let code: String
    let state: String
    let redirectUri: String
}

struct OAuthAppleNativeRequestDTO: Encodable {
    let identityToken: String
    let fullName: String?
    let email: String?
}
