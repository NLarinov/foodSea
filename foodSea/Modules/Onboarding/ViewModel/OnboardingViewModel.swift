import Foundation
import Combine

final class OnboardingViewModel: ObservableObject {

    @Published var currentPage: Int = 0

    var onComplete: (() -> Void)?

    var isLastPage: Bool {
        currentPage == Constants.Onboarding.slideCount - 1
    }

    func nextPage() {
        if isLastPage {
            completeOnboarding()
        } else {
            currentPage += 1
        }
    }

    func skip() {
        completeOnboarding()
    }

    nonisolated func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Constants.Onboarding.shownKey)
        MainActor.assumeIsolated {
            onComplete?()
        }
    }
}
