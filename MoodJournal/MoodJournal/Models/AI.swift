import Foundation

struct AIMessage: Codable, Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date

    enum MessageRole: String, Codable {
        case user = "user"
        case assistant = "assistant"
    }
}

struct AIConversation: Codable, Identifiable {
    let id: String
    let userId: String
    var messages: [AIMessage]
    let createdAt: Date
    var updatedAt: Date
}

struct AISuggestion: Codable, Identifiable {
    let id: String
    let title: String
    let content: String
    let category: SuggestionCategory
    let icon: String

    enum SuggestionCategory: String, Codable {
        case wellness = "wellness"
        case sleep = "sleep"
        case activity = "activity"
        case social = "social"
        case mindfulness = "mindfulness"

        var color: String {
            switch self {
            case .wellness: return "22C55E"
            case .sleep: return "6366F1"
            case .activity: return "F97316"
            case .social: return "EC4899"
            case .mindfulness: return "8B5CF6"
            }
        }
    }
}

struct AIChatRequest: Codable {
    let message: String
    let conversationId: String?
}

struct AIChatResponse: Codable {
    let message: AIMessage
    let conversationId: String
}
