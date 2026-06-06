import Foundation

actor AuthService {
    static let shared = AuthService()

    private init() {}

    struct RegisterRequest: Codable {
        let email: String
    }

    struct RegisterResponse: Codable {
        let message: String
        let email: String
        let codeExpiresInMinutes: Int?
    }

    struct VerifyCodeRequest: Codable {
        let email: String
        let code: String
    }

    struct VerifyCodeResponse: Codable {
        let message: String
        let email: String
        let isNewUser: Bool
        let token: String?
        let user: User?
    }

    struct CompleteRegistrationRequest: Codable {
        let email: String
        let code: String
        let firstName: String
        let lastName: String
        let phone: String
        let age: Int
        let gender: String
    }

    func register(email: String) async throws -> RegisterResponse {
        let request = RegisterRequest(email: email)
        return try await NetworkManager.shared.request(
            endpoint: "/auth/register",
            method: .post,
            body: request
        )
    }

    func verifyCode(email: String, code: String) async throws -> VerifyCodeResponse {
        let request = VerifyCodeRequest(email: email, code: code)
        return try await NetworkManager.shared.request(
            endpoint: "/auth/verify-code",
            method: .post,
            body: request
        )
    }

    func completeRegistration(data: RegistrationData) async throws -> AuthResponse {
        let request = CompleteRegistrationRequest(
            email: data.email,
            code: data.code,
            firstName: data.firstName,
            lastName: data.lastName,
            phone: data.phone,
            age: data.age,
            gender: data.gender.rawValue
        )
        return try await NetworkManager.shared.request(
            endpoint: "/auth/complete-registration",
            method: .post,
            body: request
        )
    }

    func login(email: String) async throws -> RegisterResponse {
        let request = LoginRequest(email: email)
        return try await NetworkManager.shared.request(
            endpoint: "/auth/login",
            method: .post,
            body: request
        )
    }

    func logout() async throws {
        try await NetworkManager.shared.requestWithoutResponse(
            endpoint: "/auth/logout",
            method: .post
        )
    }
}
