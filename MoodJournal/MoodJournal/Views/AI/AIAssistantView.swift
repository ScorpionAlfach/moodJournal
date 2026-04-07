import SwiftUI

struct AIAssistantView: View {
    @StateObject private var viewModel = AIViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Chat messages or suggestions
                if viewModel.messages.isEmpty {
                    welcomeView
                } else {
                    chatView
                }

                // Input bar
                inputBar
            }

            if viewModel.isLoading && viewModel.suggestions.isEmpty {
                LoadingOverlay()
            }
        }
        .navigationTitle("AI Помощник")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.messages.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.startNewConversation()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.appPrimary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadSuggestions()
        }
    }

    private var welcomeView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    }

                    Text("Чем могу помочь?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)

                    Text("Я могу дать рекомендации по улучшению настроения, помочь разобраться в эмоциях или просто поговорить")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Suggestions
                if !viewModel.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Рекомендации для вас")
                            .font(.headline)
                            .foregroundColor(.appText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(viewModel.suggestions) { suggestion in
                            SuggestionCard(suggestion: suggestion) {
                                viewModel.useSuggestion(suggestion)
                            }
                        }
                    }
                }

                // Quick prompts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Быстрые вопросы")
                        .font(.headline)
                        .foregroundColor(.appText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(quickPrompts, id: \.self) { prompt in
                        Button {
                            viewModel.inputMessage = prompt
                            Task {
                                await viewModel.sendMessage()
                            }
                        } label: {
                            HStack {
                                Text(prompt)
                                    .font(.subheadline)
                                    .foregroundColor(.appText)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Image(systemName: "arrow.right.circle")
                                    .foregroundColor(.appPrimary)
                            }
                            .padding()
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var quickPrompts: [String] {
        [
            "Как улучшить настроение прямо сейчас?",
            "Дай совет по улучшению сна",
            "Как справиться со стрессом?",
            "Расскажи про техники релаксации"
        ]
    }

    private var chatView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isSending {
                        HStack {
                            TypingIndicator()
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                TextField("Напишите сообщение...", text: $viewModel.inputMessage, axis: .vertical)
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appBackground)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )

                Button {
                    isInputFocused = false
                    Task {
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(viewModel.inputMessage.isEmpty ? .appBorder : .appPrimary)
                }
                .disabled(viewModel.inputMessage.isEmpty || viewModel.isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appCardBackground)
        }
    }
}

struct MessageBubble: View {
    let message: AIMessage

    var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isUser ? .white : .appText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        isUser ?
                        AnyView(LinearGradient(
                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )) :
                        AnyView(Color.appCardBackground)
                    )
                    .cornerRadius(20)
                    .cornerRadius(isUser ? 20 : 4, corners: isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])

                Text(message.timestamp.formattedString(format: "HH:mm"))
                    .font(.caption2)
                    .foregroundColor(.appTextSecondary)
            }

            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 24)
    }
}

struct SuggestionCard: View {
    let suggestion: AISuggestion
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: suggestion.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: suggestion.category.color))
                    .frame(width: 48, height: 48)
                    .background(Color(hex: suggestion.category.color).opacity(0.1))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appText)

                    Text(suggestion.content)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(16)
            .cardStyle()
        }
    }
}

struct TypingIndicator: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.appTextSecondary)
                    .frame(width: 8, height: 8)
                    .opacity(dotCount == index ? 1 : 0.3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appCardBackground)
        .cornerRadius(20)
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}

// Custom corner radius modifier
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        AIAssistantView()
    }
}
