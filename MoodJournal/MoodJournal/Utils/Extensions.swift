import Foundation
import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - App Theme Colors
extension Color {
    static let appPrimary = Color(hex: "6366F1")
    static let appSecondary = Color(hex: "8B5CF6")
    static let appAccent = Color(hex: "EC4899")
    static let appBackground = Color(hex: "F8FAFC")
    static let appCardBackground = Color.white
    static let appText = Color(hex: "1E293B")
    static let appTextSecondary = Color(hex: "64748B")
    static let appBorder = Color(hex: "E2E8F0")
    static let appSuccess = Color(hex: "22C55E")
    static let appWarning = Color(hex: "F59E0B")
    static let appError = Color(hex: "EF4444")

    static let gradientPrimary = LinearGradient(
        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientSecondary = LinearGradient(
        colors: [Color(hex: "EC4899"), Color(hex: "8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Date Extension
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    func formattedString(format: String = "d MMMM yyyy") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var relativeString: String {
        if isToday {
            return "Сегодня"
        } else if isYesterday {
            return "Вчера"
        } else {
            return formattedString()
        }
    }
}

// MARK: - View Extension
extension View {
    func cardStyle() -> some View {
        self
            .background(Color.appCardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.gradientPrimary)
            .cornerRadius(12)
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appPrimary.opacity(0.1))
            .cornerRadius(12)
    }

    func inputFieldStyle() -> some View {
        self
            .padding()
            .background(Color.appBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
    }
}

// MARK: - String Extension
extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }

    var isValidPhone: Bool {
        let phoneRegEx = "^[+]?[0-9]{10,15}$"
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: self.replacingOccurrences(of: " ", with: ""))
    }
}
