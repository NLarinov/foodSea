import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    enum Mode { case login, register }

    @Published var mode: Mode = .login
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    var onSuccess: (() -> Void)?

    private let authService: any AuthServiceProtocol

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    func submit() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                switch mode {
                case .login:
                    try await authService.login(email: email, password: password)
                case .register:
                    try await authService.register(email: email, password: password)
                }
                onSuccess?()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
