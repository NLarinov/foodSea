import Foundation

struct RegisterRequestDTO: Encodable {
    let email: String
    let password: String
}

struct LoginRequestDTO: Encodable {
    let email: String
    let password: String
}

struct RefreshRequestDTO: Encodable {
    let refreshToken: String
}

struct UserDTO: Decodable {
    let id: String
    let email: String?
    let phone: String?
    let onboardingDone: Bool
}

struct AuthResponseDTO: Decodable {
    let user: UserDTO
    let accessToken: String
    let refreshToken: String
    let accessExpiresAt: Date
    let refreshExpiresAt: Date
}

struct TokenPairDTO: Decodable {
    let accessToken: String
    let refreshToken: String
}
