import Foundation
import AuthenticationServices
import UIKit

final class RealYandexAuthorizer: NSObject, YandexAuthorizing, @unchecked Sendable {
    private var currentSession: ASWebAuthenticationSession?

    func requestAccessToken() async throws -> String {
        guard !Constants.OAuth.yandexClientID.isEmpty else {
            throw OAuthError.providerNetworkFailure
        }

        var components = URLComponents(string: Constants.OAuth.yandexAuthorizeURL)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: Constants.OAuth.yandexResponseType),
            URLQueryItem(name: "client_id", value: Constants.OAuth.yandexClientID),
            URLQueryItem(name: "redirect_uri", value: Constants.OAuth.nativeRedirectURI),
            URLQueryItem(name: "force_confirm", value: "yes")
        ]
        guard let authURL = components?.url else {
            throw OAuthError.invalidCallbackURL
        }

        let callbackURL = try await startSession(authURL: authURL)
        return try Self.extractAccessToken(from: callbackURL)
    }

    @MainActor
    private func startSession(authURL: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: Constants.OAuth.callbackScheme
            ) { [weak self] url, error in
                self?.currentSession = nil
                if let error = error as? ASWebAuthenticationSessionError {
                    continuation.resume(
                        throwing: error.code == .canceledLogin
                            ? OAuthError.cancelled
                            : OAuthError.providerNetworkFailure
                    )
                    return
                }
                if error != nil {
                    continuation.resume(throwing: OAuthError.providerNetworkFailure)
                    return
                }
                guard let url else {
                    continuation.resume(throwing: OAuthError.invalidCallbackURL)
                    return
                }
                continuation.resume(returning: url)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            currentSession = session
            session.start()
        }
    }

    private static func extractAccessToken(from url: URL) throws -> String {
        let fragmentSource = url.fragment ?? url.query
        guard let fragmentSource else { throw OAuthError.invalidCallbackURL }

        var components = URLComponents()
        components.percentEncodedQuery = fragmentSource
        let items = components.queryItems ?? []

        if let errorValue = items.first(where: { $0.name == Constants.OAuth.yandexErrorFragmentKey })?.value, !errorValue.isEmpty {
            throw OAuthError.providerNetworkFailure
        }
        guard let token = items.first(where: { $0.name == Constants.OAuth.yandexAccessTokenFragmentKey })?.value, !token.isEmpty else {
            throw OAuthError.invalidCallbackURL
        }
        return token
    }
}

extension RealYandexAuthorizer: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
