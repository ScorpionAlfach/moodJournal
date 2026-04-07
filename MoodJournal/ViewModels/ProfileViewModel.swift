import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isEditing = false

    // Edit fields
    @Published var editFirstName = ""
    @Published var editLastName = ""
    @Published var editPhone = ""
    @Published var editAge = ""
    @Published var editGender: User.Gender = .preferNotToSay

    @Published var showDeleteConfirmation = false
    @Published var showLogoutConfirmation = false

    func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            let profile = try await ProfileService.shared.getProfile()
            user = profile
            setupEditFields()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Не удалось загрузить профиль"
        }

        isLoading = false
    }

    private func setupEditFields() {
        guard let user = user else { return }
        editFirstName = user.firstName
        editLastName = user.lastName
        editPhone = user.phone
        editAge = String(user.age)
        editGender = user.gender
    }

    func startEditing() {
        setupEditFields()
        isEditing = true
    }

    func cancelEditing() {
        setupEditFields()
        isEditing = false
    }

    func saveProfile() async {
        guard !editFirstName.isEmpty,
              !editLastName.isEmpty,
              editPhone.isValidPhone,
              let age = Int(editAge), age >= 13, age <= 120 else {
            errorMessage = "Проверьте правильность данных"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let updatedUser = try await ProfileService.shared.updateProfile(
                firstName: editFirstName,
                lastName: editLastName,
                phone: editPhone,
                age: age,
                gender: editGender
            )
            user = updatedUser
            AppState.shared.updateUser(updatedUser)
            isEditing = false
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Не удалось сохранить изменения"
        }

        isLoading = false
    }

    func deleteAccount() async {
        isLoading = true
        errorMessage = nil

        do {
            try await ProfileService.shared.deleteProfile()
            AppState.shared.logout()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Не удалось удалить аккаунт"
        }

        isLoading = false
    }

    func logout() async {
        isLoading = true

        do {
            try await AuthService.shared.logout()
        } catch {
            // Выходим даже при ошибке сети
        }

        AppState.shared.logout()
        isLoading = false
    }
}
