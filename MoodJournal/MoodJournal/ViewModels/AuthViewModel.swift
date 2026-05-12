import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var phone = ""
    @Published var age = ""
    @Published var selectedGender: User.Gender = .preferNotToSay

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authStep: AuthStep = .email

    enum AuthStep {
        case email
        case registration
    }

    var isEmailValid: Bool {
        email.isValidEmail
    }

    var isRegistrationValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        phone.isValidPhone &&
        Int(age) != nil &&
        (Int(age) ?? 0) >= 13 &&
        (Int(age) ?? 0) <= 120
    }

    func continueWithEmail() async {
        guard isEmailValid else {
            errorMessage = "Введите корректный email"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthService.shared.register(email: email)

            if response.isNewUser {
                authStep = .registration
            } else if let token = response.token, let user = response.user {
                await AppState.shared.login(token: token, user: user)
            } else {
                let loginResponse = try await AuthService.shared.login(email: email)
                await AppState.shared.login(token: loginResponse.token, user: loginResponse.user)
            }
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Произошла ошибка. Попробуйте позже."
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
            let response = try await AuthService.shared.completeRegistration(data: registrationData)
            await AppState.shared.login(token: response.token, user: response.user)
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Ошибка регистрации. Попробуйте позже."
        }

        isLoading = false
    }

    func login() async {
        guard isEmailValid else {
            errorMessage = "Введите корректный email"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthService.shared.login(email: email)
            await AppState.shared.login(token: response.token, user: response.user)
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Ошибка входа. Попробуйте позже."
        }

        isLoading = false
    }

    func reset() {
        email = ""
        firstName = ""
        lastName = ""
        phone = ""
        age = ""
        selectedGender = .preferNotToSay
        isLoading = false
        errorMessage = nil
        authStep = .email
    }
}
