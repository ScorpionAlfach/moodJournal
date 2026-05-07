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
                let tags = filter.tags.map(\.normalizedNoteTag).filter { !$0.isEmpty }
                if !tags.isEmpty {
                    queryItems.append(URLQueryItem(name: "tags", value: tags.joined(separator: ",")))
                }
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
        let normalizedTags = normalizedUniqueTags(tags)
        let request = CreateNoteRequest(
            title: title,
            content: content,
            moodLevel: moodLevel,
            tags: normalizedTags
        )
        return try await NetworkManager.shared.request(
            endpoint: "/notes",
            method: .post,
            body: request
        )
    }

    func updateNote(id: String, title: String?, content: String?, moodLevel: Mood.MoodLevel?, tags: [String]?) async throws -> Note {
        let normalizedTags = tags.map { normalizedUniqueTags($0) }
        let request = UpdateNoteRequest(
            title: title,
            content: content,
            moodLevel: moodLevel,
            tags: normalizedTags
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

    private func normalizedUniqueTags(_ tags: [String]) -> [String] {
        var result: [String] = []
        var seen = Set<String>()

        for tag in tags {
            let normalized = tag.normalizedNoteTag
            guard !normalized.isEmpty, !seen.contains(normalized) else { continue }
            result.append(normalized)
            seen.insert(normalized)
        }

        return result
    }
}
