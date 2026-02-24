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

    func completeOnboarding() {
        let key = Constants.Onboarding.shownKey
        UserDefaults.standard.set(true, forKey: key)
        onComplete?()
    }
}
