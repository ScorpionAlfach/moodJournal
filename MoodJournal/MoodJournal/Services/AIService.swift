import Foundation

actor AIService {
    static let shared = AIService()

    private init() {}

    func sendMessage(message: String, conversationId: String?) async throws -> AIChatResponse {
        let request = AIChatRequest(message: message, conversationId: conversationId)
        return try await NetworkManager.shared.request(
            endpoint: "/ai/chat",
            method: .post,
            body: request
        )
    }

    func getSuggestions() async throws -> [AISuggestion] {
        struct SuggestionsResponse: Codable {
            let suggestions: [AISuggestion]
        }
        let response: SuggestionsResponse = try await NetworkManager.shared.request(
            endpoint: "/ai/suggestions",
            method: .get
        )
        return response.suggestions
    }
}
