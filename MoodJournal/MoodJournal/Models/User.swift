import Foundation

struct User: Codable, Identifiable {
    let id: String
    var email: String
    var firstName: String
    var lastName: String
    var phone: String
    var age: Int
    var gender: Gender
    var avatarURL: String?
    var createdAt: Date
    var onboardingCompleted: Bool

    enum Gender: String, Codable, CaseIterable {
        case male = "male"
        case female = "female"
        case other = "other"
        case preferNotToSay = "prefer_not_to_say"

        var displayName: String {
            switch self {
            case .male: return "Мужской"
            case .female: return "Женский"
            case .other: return "Другой"
            case .preferNotToSay: return "Не указывать"
            }
        }
    }
}

struct RegistrationData: Codable {
    var email: String
    var firstName: String
    var lastName: String
    var phone: String
    var age: Int
    var gender: User.Gender
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct VerifyCodeRequest: Codable {
    let email: String
    let code: String
}

struct LoginRequest: Codable {
    let email: String
    let code: String
}
