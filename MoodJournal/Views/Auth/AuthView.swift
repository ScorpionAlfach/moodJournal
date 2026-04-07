import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @FocusState private var isCodeFieldFocused: Bool

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
                            case .verification:
                                verificationSection
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
        case .verification:
            return "Введите код, отправленный на \(viewModel.email)"
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
                        await viewModel.sendVerificationCode()
                    }
                },
                isLoading: viewModel.isLoading
            )
            .disabled(!viewModel.isEmailValid)
            .opacity(viewModel.isEmailValid ? 1 : 0.6)
        }
    }

    private var verificationSection: some View {
        VStack(spacing: 20) {
            // Code input - tap to focus
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    CodeDigitView(
                        digit: getDigit(at: index),
                        isFocused: viewModel.verificationCode.count == index
                    )
                }
            }
            .onTapGesture {
                isCodeFieldFocused = true
            }

            // Hidden text field for input
            TextField("", text: $viewModel.verificationCode)
                .keyboardType(.numberPad)
                .focused($isCodeFieldFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: viewModel.verificationCode) { _, newValue in
                    if newValue.count > 6 {
                        viewModel.verificationCode = String(newValue.prefix(6))
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isCodeFieldFocused = true
                    }
                }

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
            .disabled(!viewModel.isCodeValid)
            .opacity(viewModel.isCodeValid ? 1 : 0.6)

            Button {
                Task {
                    await viewModel.sendVerificationCode()
                }
            } label: {
                Text("Отправить код повторно")
                    .font(.subheadline)
                    .foregroundColor(.appPrimary)
            }

            Button {
                withAnimation {
                    viewModel.authStep = .email
                    viewModel.verificationCode = ""
                }
            } label: {
                Text("Изменить email")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }
        }
    }

    private func getDigit(at index: Int) -> String {
        guard index < viewModel.verificationCode.count else { return "" }
        let stringIndex = viewModel.verificationCode.index(
            viewModel.verificationCode.startIndex,
            offsetBy: index
        )
        return String(viewModel.verificationCode[stringIndex])
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
        }
    }
}

struct CodeDigitView: View {
    let digit: String
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
                .frame(width: 48, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.appPrimary : Color.appBorder, lineWidth: isFocused ? 2 : 1)
                )

            Text(digit)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
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
