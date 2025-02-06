import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversation: [Message] = []
    @Published var inputText: String = ""
    @Published var isProcessing = false

    struct Message: Identifiable {
        let id = UUID()
        let role: Role
        let text: String
    }

    enum Role {
        case user
        case assistant
    }

    private let geminiProvider = GeminiProvider(
        config: GeminiConfig(apiKey: "YOUR_API_KEY",
                             modelName: "gemini-2.0-flash")
    )

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 1) Add user message
        let userMsg = Message(role: .user, text: trimmed)
        conversation.append(userMsg)
        inputText = ""

        // 2) Build a combined prompt of the entire conversation
        let conversationContext = buildConversationContext()

        Task {
            do {
                isProcessing = true
                let result = try await geminiProvider.processText(userPrompt: conversationContext)
                // 3) Add assistant message
                let assistantMsg = Message(role: .assistant, text: result)
                conversation.append(assistantMsg)
            } catch {
                let errorMsg = Message(role: .assistant, text: "Error: \(error.localizedDescription)")
                conversation.append(errorMsg)
            }
            isProcessing = false
        }
    }

    private func buildConversationContext() -> String {
        var prompt = "You are a helpful AI assistant in a multi-turn conversation.\n\n"
        for msg in conversation {
            switch msg.role {
            case .user:
                prompt += "User: \(msg.text)\n"
            case .assistant:
                prompt += "Assistant: \(msg.text)\n"
            }
        }
        prompt += "\nContinue the conversation. Respond directly, referencing the entire history.\n"
        return prompt
    }
}
