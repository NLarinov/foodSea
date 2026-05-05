import Foundation
import Combine

@MainActor
final class WelcomeViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    var onSuccess: (() -> Void)?
    var onContinueWithEmail: (() -> Void)?

    private let authService: any AuthServiceProtocol

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    func signInWithApple() {
        run { try await self.authService.signInWithApple() }
    }

    func signInWithGoogle() {
        run { try await self.authService.signInWithGoogle() }
    }

    func signInWithYandex() {
        run { try await self.authService.signInWithYandex() }
    }

    func continueWithEmail() {
        onContinueWithEmail?()
    }

    private func run(_ work: @escaping () async throws -> Void) {
        Task { [weak self] in
            guard let self else { return }
            isLoading = true
            errorMessage = nil
            do {
                try await work()
                onSuccess?()
            } catch let appError as AppError {
                if appError.errorDescription != nil {
                    errorMessage = appError.errorDescription
                }
            } catch let oauthError as OAuthError {
                let appError = oauthError.asAppError
                if appError.errorDescription != nil {
                    errorMessage = appError.errorDescription
                }
            } catch {
                errorMessage = Constants.Strings.oauthGenericError
            }
            isLoading = false
        }
    }
}
