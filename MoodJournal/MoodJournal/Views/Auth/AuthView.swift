import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection

                        // Content based on step
                        Group {
                            switch viewModel.authStep {
                            case .email:
                                emailSection
                            case .code:
                                codeSection
                            case .registration:
                                registrationSection
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    .padding(24)
                }

                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.authStep)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "face.smiling.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .padding(.top, 40)

            Text("Дневник настроения")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.appText)

            Text(stepDescription)
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var stepDescription: String {
        switch viewModel.authStep {
        case .email:
            return "Введите email для регистрации или входа"
        case .code:
            return "Введите код подтверждения из письма"
        case .registration:
            return "Заполните информацию о себе"
        }
    }

    private var emailSection: some View {
        VStack(spacing: 20) {
            CustomTextField(
                placeholder: "Email",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                icon: "envelope"
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    viewModel.errorMessage = nil
                }
            }

            CustomButton(
                title: "Продолжить",
                action: {
                    Task {
                        await viewModel.continueWithEmail()
                    }
                },
                isLoading: viewModel.isLoading
            )
            .disabled(!viewModel.isEmailValid)
            .opacity(viewModel.isEmailValid ? 1 : 0.6)
        }
    }

    private var codeSection: some View {
        VStack(spacing: 20) {
            CustomTextField(
                placeholder: "Код подтверждения",
                text: $viewModel.verificationCode,
                keyboardType: .numberPad,
                icon: "number"
            )

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    viewModel.errorMessage = nil
                }
            }

            CustomButton(
                title: "Подтвердить",
                action: {
                    Task {
                        await viewModel.verifyCode()
                    }
                },
                isLoading: viewModel.isLoading
            )
            .disabled(!viewModel.isVerificationCodeValid)
            .opacity(viewModel.isVerificationCodeValid ? 1 : 0.6)

            Button {
                Task {
                    await viewModel.continueWithEmail()
                }
            } label: {
                Text("Отправить код повторно")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }

            Button {
                withAnimation {
                    viewModel.authStep = .email
                    viewModel.errorMessage = nil
                }
            } label: {
                Text("Изменить email")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }
        }
    }

    private var registrationSection: some View {
        VStack(spacing: 20) {
            CustomTextField(
                placeholder: "Имя",
                text: $viewModel.firstName,
                icon: "person"
            )

            CustomTextField(
                placeholder: "Фамилия",
                text: $viewModel.lastName,
                icon: "person"
            )

            CustomTextField(
                placeholder: "Телефон",
                text: $viewModel.phone,
                keyboardType: .phonePad,
                icon: "phone"
            )

            CustomTextField(
                placeholder: "Возраст",
                text: $viewModel.age,
                keyboardType: .numberPad,
                icon: "calendar"
            )

            // Gender picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Пол")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)

                HStack(spacing: 12) {
                    ForEach(User.Gender.allCases, id: \.self) { gender in
                        GenderButton(
                            gender: gender,
                            isSelected: viewModel.selectedGender == gender
                        ) {
                            viewModel.selectedGender = gender
                        }
                    }
                }
            }

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    viewModel.errorMessage = nil
                }
            }

            CustomButton(
                title: "Завершить регистрацию",
                action: {
                    Task {
                        await viewModel.completeRegistration()
                    }
                },
                isLoading: viewModel.isLoading
            )
            .disabled(!viewModel.isRegistrationValid)
            .opacity(viewModel.isRegistrationValid ? 1 : 0.6)

            Button {
                withAnimation {
                    viewModel.authStep = .email
                    viewModel.errorMessage = nil
                }
            } label: {
                Text("Изменить email")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }
        }
    }
}

struct GenderButton: View {
    let gender: User.Gender
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(gender.displayName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .appText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected ?
                    AnyView(LinearGradient(
                        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )) :
                    AnyView(Color.appBackground)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.appBorder, lineWidth: 1)
                )
        }
    }
}

#Preview {
    AuthView()
}
