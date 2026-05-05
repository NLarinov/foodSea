import Foundation

enum OAuthError: Error {
    case cancelled
    case providerNetworkFailure
    case invalidCallbackURL
    case missingIdentityToken
    case backendFailure(AppError)
}

extension OAuthError {
    var asAppError: AppError {
        switch self {
        case .cancelled:
            return .oauthCancelled
        case .providerNetworkFailure:
            return .oauthFailed(Constants.Strings.oauthProviderNetworkError)
        case .invalidCallbackURL:
            return .oauthFailed(Constants.Strings.oauthSessionExpiredError)
        case .missingIdentityToken:
            return .oauthFailed(Constants.Strings.oauthAppleVerificationError)
        case .backendFailure(let appError):
            switch appError {
            case .serverError(let code) where code == 401:
                return .oauthFailed(Constants.Strings.oauthSessionExpiredError)
            case .serverError(let code) where code == 409:
                return .oauthFailed(Constants.Strings.oauthEmailCollisionError)
            default:
                return appError
            }
        }
    }
}
