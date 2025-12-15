import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Экран загрузки или чат
                if !viewModel.isModelLoaded {
                    LoadingView(status: viewModel.loadingStatus)
                } else {
                    // Список сообщений
                    MessageListView(
                        messages: viewModel.messages,
                        isLoading: viewModel.isLoading
                    )

                    // Поле ввода
                    InputBarView(
                        text: $viewModel.inputText,
                        isLoading: viewModel.isLoading,
                        isFocused: $isInputFocused,
                        onSend: {
                            Task {
                                await viewModel.sendMessage()
                            }
                        }
                    )
                }
            }
            .navigationTitle("LocalChat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.clearChat()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .disabled(!viewModel.isModelLoaded)
                }
            }
            .background(Color(.systemGroupedBackground))
            .onTapGesture {
                isInputFocused = false
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let status: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Анимированная иконка
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            .shadow(color: .blue.opacity(0.3), radius: 20)

            VStack(spacing: 8) {
                Text("LocalChat")
                    .font(.title.bold())

                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)

            Spacer()

            Text("Gemma 2B работает локально на твоём iPhone")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 40)
        }
        .padding()
    }
}

// MARK: - Message List

struct MessageListView: View {
    let messages: [Message]
    let isLoading: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    // Индикатор печати
                    if isLoading {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    if isLoading {
                        proxy.scrollTo("typing", anchor: .bottom)
                    } else if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
            } else {
                // Аватар бота
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(parseMarkdown(message.content))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isUser
                            ? AnyShapeStyle(LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            : AnyShapeStyle(Color(.secondarySystemBackground))
                    )
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }

    private func parseMarkdown(_ text: String) -> AttributedString {
        do {
            let attributed = try AttributedString(
                markdown: text,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            )
            return attributed
        } catch {
            return AttributedString(text)
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer(minLength: 60)
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Input Bar

struct InputBarView: View {
    @Binding var text: String
    let isLoading: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Текстовое поле
            TextField("Сообщение...", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .focused(isFocused)

            // Кнопка отправки
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
                            ? Color.gray.opacity(0.4)
                            : Color.blue
                    )
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ChatView()
}
