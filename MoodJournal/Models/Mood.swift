import Foundation
import SwiftUI

struct Mood: Codable, Identifiable {
    let id: String
    let userId: String
    var level: MoodLevel
    var note: String?
    var factors: [MoodFactor]
    let date: Date
    let createdAt: Date

    enum MoodLevel: Int, Codable, CaseIterable {
        case terrible = 1
        case bad = 2
        case okay = 3
        case good = 4
        case excellent = 5

        var emoji: String {
            switch self {
            case .terrible: return "😢"
            case .bad: return "😔"
            case .okay: return "😐"
            case .good: return "😊"
            case .excellent: return "😄"
            }
        }

        var title: String {
            switch self {
            case .terrible: return "Ужасно"
            case .bad: return "Плохо"
            case .okay: return "Нормально"
            case .good: return "Хорошо"
            case .excellent: return "Отлично"
            }
        }

        var color: Color {
            switch self {
            case .terrible: return Color(hex: "EF4444")
            case .bad: return Color(hex: "F97316")
            case .okay: return Color(hex: "EAB308")
            case .good: return Color(hex: "22C55E")
            case .excellent: return Color(hex: "10B981")
            }
        }

        var gradient: [Color] {
            switch self {
            case .terrible: return [Color(hex: "EF4444"), Color(hex: "DC2626")]
            case .bad: return [Color(hex: "F97316"), Color(hex: "EA580C")]
            case .okay: return [Color(hex: "EAB308"), Color(hex: "CA8A04")]
            case .good: return [Color(hex: "22C55E"), Color(hex: "16A34A")]
            case .excellent: return [Color(hex: "10B981"), Color(hex: "059669")]
            }
        }
    }

    enum MoodFactor: String, Codable, CaseIterable {
        case sleep = "sleep"
        case noSleep = "no_sleep"
        case exercise = "exercise"
        case work = "work"
        case family = "family"
        case friends = "friends"
        case health = "health"
        case weather = "weather"
        case food = "food"
        case hobby = "hobby"

        var title: String {
            switch self {
            case .sleep: return "Выспался"
            case .noSleep: return "Не выспался"
            case .exercise: return "Спорт"
            case .work: return "Работа"
            case .family: return "Семья"
            case .friends: return "Друзья"
            case .health: return "Здоровье"
            case .weather: return "Погода"
            case .food: return "Еда"
            case .hobby: return "Хобби"
            }
        }

        var icon: String {
            switch self {
            case .sleep: return "moon.fill"
            case .noSleep: return "moon"
            case .exercise: return "figure.run"
            case .work: return "briefcase.fill"
            case .family: return "house.fill"
            case .friends: return "person.2.fill"
            case .health: return "heart.fill"
            case .weather: return "sun.max.fill"
            case .food: return "fork.knife"
            case .hobby: return "paintbrush.fill"
            }
        }
    }
}

struct MoodGraphData: Codable {
    let data: [MoodGraphPoint]
    let averageLevel: Double
    let period: Int
}

struct MoodGraphPoint: Codable, Identifiable {
    var id: String { date }
    let date: String
    let level: Double
    let moodCount: Int
}

struct CreateMoodRequest: Codable {
    let level: Mood.MoodLevel
    let note: String?
    let factors: [Mood.MoodFactor]
}
