import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color(hex: "6366F1").opacity(0.1), Color(hex: "8B5CF6").opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        Task {
                            await viewModel.skipOnboarding()
                        }
                    } label: {
                        Text("Пропустить")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Content
                TabView(selection: $viewModel.currentStep) {
                    ForEach(Array(viewModel.steps.enumerated()), id: \.element.id) { index, step in
                        OnboardingStepView(step: step)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width > threshold {
                                viewModel.previousStep()
                            } else if value.translation.width < -threshold {
                                viewModel.nextStep()
                            }
                            dragOffset = 0
                        }
                )

                // Progress and buttons
                VStack(spacing: 24) {
                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<viewModel.steps.count, id: \.self) { index in
                            Circle()
                                .fill(index == viewModel.currentStep ? Color.appPrimary : Color.appBorder)
                                .frame(width: index == viewModel.currentStep ? 24 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        }
                    }

                    // Buttons
                    HStack(spacing: 16) {
                        if viewModel.currentStep > 0 {
                            Button {
                                viewModel.previousStep()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                                    .foregroundColor(.appPrimary)
                                    .frame(width: 56, height: 56)
                                    .background(Color.appPrimary.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }

                        CustomButton(
                            title: viewModel.isLastStep ? "Начать" : "Далее",
                            action: {
                                if viewModel.isLastStep {
                                    Task {
                                        await viewModel.completeOnboarding()
                                    }
                                } else {
                                    viewModel.nextStep()
                                }
                            },
                            isLoading: viewModel.isLoading
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .task {
            await viewModel.loadSteps()
        }
    }
}

struct OnboardingStepView: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .shadow(color: Color(hex: "6366F1").opacity(0.3), radius: 30, x: 0, y: 10)

                Image(systemName: step.imageName)
                    .font(.system(size: 70))
                    .foregroundColor(.white)
            }

            VStack(spacing: 16) {
                Text(step.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.appText)
                    .multilineTextAlignment(.center)

                Text(step.description)
                    .font(.body)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
