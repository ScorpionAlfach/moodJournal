import Foundation

actor NotesService {
    static let shared = NotesService()

    private init() {}

    struct NotesResponse: Codable {
        let notes: [Note]
        let total: Int
        let page: Int
        let limit: Int
    }

    func getNotes(
        filter: NotesFilter? = nil,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> NotesResponse {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let filter = filter {
            if !filter.searchText.isEmpty {
                queryItems.append(URLQueryItem(name: "search", value: filter.searchText))
            }
            if !filter.moodLevels.isEmpty {
                let levels = filter.moodLevels.map { String($0.rawValue) }.joined(separator: ",")
                queryItems.append(URLQueryItem(name: "moodLevels", value: levels))
            }
            if !filter.tags.isEmpty {
                queryItems.append(URLQueryItem(name: "tags", value: filter.tags.joined(separator: ",")))
            }
            queryItems.append(URLQueryItem(name: "sortBy", value: filter.sortBy.rawValue))
        }

        return try await NetworkManager.shared.request(
            endpoint: "/notes",
            method: .get,
            queryItems: queryItems
        )
    }

    func getNote(id: String) async throws -> Note {
        return try await NetworkManager.shared.request(
            endpoint: "/notes/\(id)",
            method: .get
        )
    }

    func createNote(title: String, content: String, moodLevel: Mood.MoodLevel?, tags: [String]) async throws -> Note {
        let request = CreateNoteRequest(
            title: title,
            content: content,
            moodLevel: moodLevel,
            tags: tags
        )
        return try await NetworkManager.shared.request(
            endpoint: "/notes",
            method: .post,
            body: request
        )
    }

    func updateNote(id: String, title: String?, content: String?, moodLevel: Mood.MoodLevel?, tags: [String]?) async throws -> Note {
        let request = UpdateNoteRequest(
            title: title,
            content: content,
            moodLevel: moodLevel,
            tags: tags
        )
        return try await NetworkManager.shared.request(
            endpoint: "/notes/\(id)",
            method: .put,
            body: request
        )
    }

    func deleteNote(id: String) async throws {
        try await NetworkManager.shared.requestWithoutResponse(
            endpoint: "/notes/\(id)",
            method: .delete
        )
    }
}
