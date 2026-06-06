import Foundation
import SwiftUI

@MainActor
class AIViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var suggestions: [AISuggestion] = []
    @Published var inputMessage = ""
    @Published var conversationId: String?

    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var suggestionsErrorMessage: String?
    @Published var hasLoadedSuggestions = false
    @Published var hasLoadedConversation = false

    func loadInitialState() async {
        await loadLatestConversation()
        await loadSuggestions()
    }

    func loadLatestConversation() async {
        guard !hasLoadedConversation else { return }
        hasLoadedConversation = true

        do {
            if let conversation = try await AIService.shared.getLatestConversation() {
                conversationId = conversation.id
                messages = conversation.messages
            }
        } catch {
            errorMessage = "Не удалось загрузить историю диалога"
        }
    }

    func loadSuggestions() async {
        guard !hasLoadedSuggestions, !isLoading else { return }

        isLoading = true
        suggestionsErrorMessage = nil

        do {
            suggestions = try await AIService.shared.getSuggestions()
            hasLoadedSuggestions = true
        } catch let error as NetworkError {
            suggestionsErrorMessage = error.errorDescription
        } catch {
            suggestionsErrorMessage = "Не удалось загрузить рекомендации"
        }

        isLoading = false
    }

    func sendMessage() async {
        let text = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = AIMessage(
            id: UUID().uuidString,
            role: .user,
            content: text,
            timestamp: Date()
        )

        messages.append(userMessage)
        inputMessage = ""
        isSending = true
        errorMessage = nil

        do {
            let response = try await AIService.shared.sendMessage(
                message: text,
                conversationId: conversationId
            )
            conversationId = response.conversationId
            messages.append(response.message)
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            // Remove failed user message
            if let index = messages.firstIndex(where: { $0.id == userMessage.id }) {
                messages.remove(at: index)
            }
        } catch {
            errorMessage = "Не удалось отправить сообщение"
        }

        isSending = false
    }

    func startNewConversation() {
        messages = []
        conversationId = nil
        errorMessage = nil
    }

    func useSuggestion(_ suggestion: AISuggestion) {
        inputMessage = "Расскажи подробнее про: \(suggestion.title)"
        Task {
            await sendMessage()
        }
    }
}
