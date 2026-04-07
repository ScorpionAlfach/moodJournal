import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var showOnboarding = false

    private let tokenKey = "authToken"
    private let userKey = "currentUser"

    init() {
        loadSavedState()
    }

    private func loadSavedState() {
        if let token = UserDefaults.standard.string(forKey: tokenKey),
           let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            Task {
                await NetworkManager.shared.setAuthToken(token)
            }
            self.currentUser = user
            self.isAuthenticated = true
            self.showOnboarding = !user.onboardingCompleted
        }
    }

    func login(token: String, user: User) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
        Task {
            await NetworkManager.shared.setAuthToken(token)
        }
        self.currentUser = user
        self.isAuthenticated = true
        self.showOnboarding = !user.onboardingCompleted
    }

    func updateUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
        self.currentUser = user
    }

    func completeOnboarding() {
        showOnboarding = false
        if var user = currentUser {
            user = User(
                id: user.id,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                phone: user.phone,
                age: user.age,
                gender: user.gender,
                avatarURL: user.avatarURL,
                createdAt: user.createdAt,
                onboardingCompleted: true
            )
            updateUser(user)
        }
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        Task {
            await NetworkManager.shared.setAuthToken(nil)
        }
        self.currentUser = nil
        self.isAuthenticated = false
        self.showOnboarding = false
    }
}
