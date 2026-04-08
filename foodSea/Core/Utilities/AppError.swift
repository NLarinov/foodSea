import Foundation

enum AppError: Error, LocalizedError, Sendable {
    case networkError
    case serverError(statusCode: Int)
    case decodingError
    case notFound
    case timeout
    case unauthorized
    case oauthCancelled
    case oauthFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkError:
            Constants.Strings.networkError
        case .serverError:
            Constants.Strings.serverError
        case .decodingError:
            "Ошибка обработки данных"
        case .notFound:
            Constants.Strings.productNotFound
        case .timeout:
            "Превышено время ожидания"
        case .unauthorized:
            "Необходима авторизация"
        case .oauthCancelled:
            nil
        case .oauthFailed(let message):
            message
        case .unknown(let message):
            message
        }
    }
}
