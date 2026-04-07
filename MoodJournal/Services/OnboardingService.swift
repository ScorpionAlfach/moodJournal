import Foundation

actor OnboardingService {
    static let shared = OnboardingService()

    private init() {}

    func getOnboardingSteps() async throws -> OnboardingData {
        return try await NetworkManager.shared.request(
            endpoint: "/onboarding",
            method: .get
        )
    }

    func completeOnboarding() async throws -> SuccessResponse {
        return try await NetworkManager.shared.request(
            endpoint: "/onboarding/complete",
            method: .post
        )
    }
}
