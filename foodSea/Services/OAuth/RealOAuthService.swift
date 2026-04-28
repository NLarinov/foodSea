import Foundation
import AuthenticationServices
import UIKit

final class RealOAuthService: NSObject, OAuthServiceProtocol, @unchecked Sendable {
    private let client: NetworkClient
    private var currentWebSession: ASWebAuthenticationSession?
    private var currentApplePresentationProvider: ApplePresentationProvider?

    init(client: NetworkClient) {
        self.client = client
        super.init()
    }

    func signInWithGoogle() async throws -> AuthResponseDTO {
        try await runWebOAuth(provider: Constants.OAuth.googleProvider)
    }

    func signInWithYandex() async throws -> AuthResponseDTO {
        try await runWebOAuth(provider: Constants.OAuth.yandexProvider)
    }

    private func runWebOAuth(provider: String) async throws -> AuthResponseDTO {
        let redirectURI = Constants.OAuth.bridgeRedirectURI

        let startResponse: OAuthStartResponseDTO
        do {
            startResponse = try await client.request(.oauthStart(provider: provider, redirectURI: redirectURI))
        } catch let appError as AppError {
            throw OAuthError.backendFailure(appError)
        }

        guard let authURL = URL(string: startResponse.authUrl) else {
            throw OAuthError.invalidCallbackURL
        }

        let callbackURL = try await startWebAuthSession(authURL: authURL)

        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == Constants.OAuth.codeQueryItem })?.value,
              let state = components.queryItems?.first(where: { $0.name == Constants.OAuth.stateQueryItem })?.value else {
            throw OAuthError.invalidCallbackURL
        }

        do {
            let response: AuthResponseDTO = try await client.request(
                .oauthCallback(provider: provider, code: code, state: state, redirectURI: redirectURI)
            )
            return response
        } catch let appError as AppError {
            throw OAuthError.backendFailure(appError)
        }
    }

    @MainActor
    private func startWebAuthSession(authURL: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: Constants.OAuth.callbackScheme
            ) { [weak self] callbackURL, error in
                self?.currentWebSession = nil
                if let error = error as? ASWebAuthenticationSessionError {
                    if error.code == .canceledLogin {
                        continuation.resume(throwing: OAuthError.cancelled)
                    } else {
                        continuation.resume(throwing: OAuthError.providerNetworkFailure)
                    }
                    return
                }
                if error != nil {
                    continuation.resume(throwing: OAuthError.providerNetworkFailure)
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: OAuthError.invalidCallbackURL)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            currentWebSession = session
            session.start()
        }
    }

    func signInWithApple() async throws -> AuthResponseDTO {
        let credential = try await requestAppleCredential()

        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            throw OAuthError.missingIdentityToken
        }

        let fullName = Self.composeFullName(from: credential.fullName)
        let email = credential.email

        do {
            let response: AuthResponseDTO = try await client.request(
                .oauthAppleNative(identityToken: identityToken, fullName: fullName, email: email)
            )
            return response
        } catch let appError as AppError {
            throw OAuthError.backendFailure(appError)
        }
    }

    @MainActor
    private func requestAppleCredential() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            let proxy = ApplePresentationProvider(continuation: continuation)
            controller.delegate = proxy
            controller.presentationContextProvider = proxy
            currentApplePresentationProvider = proxy
            controller.performRequests()
        }
    }

    private static func composeFullName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let formatter = PersonNameComponentsFormatter()
        let result = formatter.string(from: components)
        return result.isEmpty ? nil : result
    }
}

extension RealOAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

private final class ApplePresentationProvider: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {

    private let continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>
    private var didResume = false

    init(continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) {
        self.continuation = continuation
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard !didResume else { return }
        didResume = true
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation.resume(returning: credential)
        } else {
            continuation.resume(throwing: OAuthError.missingIdentityToken)
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        guard !didResume else { return }
        didResume = true
        if let asError = error as? ASAuthorizationError, asError.code == .canceled {
            continuation.resume(throwing: OAuthError.cancelled)
        } else {
            continuation.resume(throwing: OAuthError.providerNetworkFailure)
        }
    }
}
