import Foundation

struct Note: Codable, Identifiable {
    let id: String
    let userId: String
    var title: String
    var content: String
    var moodLevel: Mood.MoodLevel?
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter.string(from: createdAt)
    }

    var shortContent: String {
        if content.count > 100 {
            return String(content.prefix(100)) + "..."
        }
        return content
    }
}

struct CreateNoteRequest: Codable {
    let title: String
    let content: String
    let moodLevel: Mood.MoodLevel?
    let tags: [String]
}

struct UpdateNoteRequest: Codable {
    let title: String?
    let content: String?
    let moodLevel: Mood.MoodLevel?
    let tags: [String]?
}

struct NotesFilter: Equatable {
    var searchText: String = ""
    var moodLevels: [Mood.MoodLevel] = []
    var tags: [String] = []
    var startDate: Date?
    var endDate: Date?
    var sortBy: SortOption = .dateDesc

    enum SortOption: String, CaseIterable {
        case dateDesc = "date_desc"
        case dateAsc = "date_asc"
        case titleAsc = "title_asc"
        case titleDesc = "title_desc"

        var displayName: String {
            switch self {
            case .dateDesc: return "Сначала новые"
            case .dateAsc: return "Сначала старые"
            case .titleAsc: return "По названию (А-Я)"
            case .titleDesc: return "По названию (Я-А)"
            }
        }
    }
}
