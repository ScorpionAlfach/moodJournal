import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var verificationCode = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var phone = ""
    @Published var age = ""
    @Published var selectedGender: User.Gender = .preferNotToSay

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authStep: AuthStep = .email

    @Published var isEmailSent = false
    @Published var isCodeVerified = false

    enum AuthStep {
        case email
        case verification
        case registration
    }

    var isEmailValid: Bool {
        email.isValidEmail
    }

    var isCodeValid: Bool {
        verificationCode.count == 6
    }

    var isRegistrationValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        phone.isValidPhone &&
        Int(age) != nil &&
        (Int(age) ?? 0) >= 13 &&
        (Int(age) ?? 0) <= 120
    }

    func sendVerificationCode() async {
        guard isEmailValid else {
            errorMessage = "Введите корректный email"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await AuthService.shared.register(email: email)
            isEmailSent = true
            authStep = .verification
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Произошла ошибка. Попробуйте позже."
        }

        isLoading = false
    }

    func verifyCode() async {
        guard isCodeValid else {
            errorMessage = "Введите 6-значный код"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await AuthService.shared.verifyCode(email: email, code: verificationCode)
            isCodeVerified = true
            authStep = .registration
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Неверный код подтверждения"
        }

        isLoading = false
    }

    func completeRegistration() async {
        guard isRegistrationValid else {
            errorMessage = "Заполните все поля корректно"
            return
        }

        isLoading = true
        errorMessage = nil

        let registrationData = RegistrationData(
            email: email,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            age: Int(age) ?? 0,
            gender: selectedGender
        )

        do {
            let response = try await AuthService.shared.completeRegistration(
                data: registrationData,
                code: verificationCode
            )
            AppState.shared.login(token: response.token, user: response.user)
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Ошибка регистрации. Попробуйте позже."
        }

        isLoading = false
    }

    func login() async {
        guard isEmailValid && isCodeValid else {
            errorMessage = "Введите email и код подтверждения"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthService.shared.login(email: email, code: verificationCode)
            AppState.shared.login(token: response.token, user: response.user)
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Ошибка входа. Попробуйте позже."
        }

        isLoading = false
    }

    func reset() {
        email = ""
        verificationCode = ""
        firstName = ""
        lastName = ""
        phone = ""
        age = ""
        selectedGender = .preferNotToSay
        isLoading = false
        errorMessage = nil
        authStep = .email
        isEmailSent = false
        isCodeVerified = false
    }
}
