import Foundation

struct CalendarData: Codable {
    let month: Int
    let year: Int
    let days: [CalendarDay]
}

struct CalendarDay: Codable, Identifiable {
    var id: String { date }
    let date: String
    let moodLevel: Double?
    let moodCount: Int
    let hasNotes: Bool
    let factors: [Mood.MoodFactor]

    var dateObject: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }

    var dayNumber: Int? {
        guard let dateObj = dateObject else { return nil }
        return Calendar.current.component(.day, from: dateObj)
    }
}

struct CalendarDayDetail: Codable {
    let date: String
    let moods: [Mood]
    let notes: [Note]
    let averageMoodLevel: Double?
    let factors: [Mood.MoodFactor]
}

struct CalendarFilter: Codable, Equatable, Identifiable {
    var id: String { value }
    let value: String
    let label: String
    let icon: String

    static let defaultFilters: [CalendarFilter] = [
        CalendarFilter(value: "sleep", label: "Выспался", icon: "moon.fill"),
        CalendarFilter(value: "no_sleep", label: "Не выспался", icon: "moon"),
        CalendarFilter(value: "exercise", label: "Спорт", icon: "figure.run"),
        CalendarFilter(value: "good_mood", label: "Хорошее настроение", icon: "face.smiling"),
        CalendarFilter(value: "bad_mood", label: "Плохое настроение", icon: "cloud.rain")
    ]
}
