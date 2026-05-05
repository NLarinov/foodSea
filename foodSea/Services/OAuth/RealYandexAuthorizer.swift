import Foundation
import UIKit
import YandexLoginSDK

final class RealYandexAuthorizer: NSObject, YandexAuthorizing, @unchecked Sendable {
    private var currentObserver: ContinuationObserver?

    func requestAccessToken() async throws -> String {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            Task { @MainActor in
                guard let parent = Self.topViewController() else {
                    continuation.resume(throwing: OAuthError.providerNetworkFailure)
                    return
                }
                let observer = ContinuationObserver(continuation: continuation) { [weak self] in
                    self?.currentObserver = nil
                }
                self.currentObserver = observer
                YandexLoginSDK.shared.add(observer: observer)
                do {
                    try YandexLoginSDK.shared.authorize(with: parent)
                } catch {
                    YandexLoginSDK.shared.remove(observer: observer)
                    self.currentObserver = nil
                    continuation.resume(throwing: OAuthError.providerNetworkFailure)
                }
            }
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        var current = keyWindow?.rootViewController
        while let presented = current?.presentedViewController {
            current = presented
        }
        return current
    }
}

private final class ContinuationObserver: NSObject, YandexLoginSDKObserver {
    private let continuation: CheckedContinuation<String, Error>
    private let cleanup: () -> Void
    private var didResume = false

    init(continuation: CheckedContinuation<String, Error>, cleanup: @escaping () -> Void) {
        self.continuation = continuation
        self.cleanup = cleanup
    }

    func didFinishLogin(with result: Result<LoginResult, any Error>) {
        guard !didResume else { return }
        didResume = true
        YandexLoginSDK.shared.remove(observer: self)
        cleanup()
        switch result {
        case .success(let loginResult):
            continuation.resume(returning: loginResult.token)
        case .failure(let error):
            let message = String(describing: error).lowercased()
            if message.contains("userclosed") || message.contains("cancel") {
                continuation.resume(throwing: OAuthError.cancelled)
            } else {
                continuation.resume(throwing: OAuthError.providerNetworkFailure)
            }
        }
    }
}
