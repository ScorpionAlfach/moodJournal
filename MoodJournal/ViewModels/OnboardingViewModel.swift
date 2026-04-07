import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var steps: [OnboardingStep] = OnboardingStep.defaultSteps
    @Published var currentStep = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    var progress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(currentStep + 1) / Double(steps.count)
    }

    var isLastStep: Bool {
        currentStep == steps.count - 1
    }

    var currentStepData: OnboardingStep? {
        guard currentStep < steps.count else { return nil }
        return steps[currentStep]
    }

    func loadSteps() async {
        isLoading = true

        do {
            let data = try await OnboardingService.shared.getOnboardingSteps()
            steps = data.steps.sorted { $0.order < $1.order }
        } catch {
            // Use default steps if API fails
            steps = OnboardingStep.defaultSteps
        }

        isLoading = false
    }

    func nextStep() {
        if currentStep < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        }
    }

    func previousStep() {
        if currentStep > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }

    func completeOnboarding() async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await OnboardingService.shared.completeOnboarding()
            AppState.shared.completeOnboarding()
        } catch {
            // Complete locally even if API fails
            AppState.shared.completeOnboarding()
        }

        isLoading = false
    }

    func skipOnboarding() async {
        await completeOnboarding()
    }
}
