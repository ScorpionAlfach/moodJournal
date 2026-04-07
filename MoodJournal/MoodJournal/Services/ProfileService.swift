import Foundation

actor ProfileService {
    static let shared = ProfileService()

    private init() {}

    struct UpdateProfileRequest: Codable {
        let firstName: String?
        let lastName: String?
        let phone: String?
        let age: Int?
        let gender: String?
    }

    func getProfile() async throws -> User {
        return try await NetworkManager.shared.request(
            endpoint: "/profile",
            method: .get
        )
    }

    func updateProfile(
        firstName: String? = nil,
        lastName: String? = nil,
        phone: String? = nil,
        age: Int? = nil,
        gender: User.Gender? = nil
    ) async throws -> User {
        let request = UpdateProfileRequest(
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            age: age,
            gender: gender?.rawValue
        )
        return try await NetworkManager.shared.request(
            endpoint: "/profile",
            method: .put,
            body: request
        )
    }

    func deleteProfile() async throws {
        try await NetworkManager.shared.requestWithoutResponse(
            endpoint: "/profile",
            method: .delete
        )
    }
}
