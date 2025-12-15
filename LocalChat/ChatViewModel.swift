import Foundation
import SwiftUI
import LLM

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var isModelLoaded: Bool = false
    @Published var loadingStatus: String = "Загрузка модели..."
    @Published var currentResponse: String = ""

    private var bot: LLM?

    init() {
        Task {
            await loadModel()
        }
    }

    private func loadModel() async {
        loadingStatus = "Загружаю Gemma 2B..."

        // Ищем модель в Bundle приложения
        guard let modelURL = Bundle.main.url(forResource: "gemma-2-2b-it-Q4_K_M", withExtension: "gguf") else {
            loadingStatus = "Модель не найдена в Bundle!"
            return
        }

        // Инициализируем LLM с шаблоном Gemma
        bot = LLM(from: modelURL, template: .gemma)

        isModelLoaded = true
        loadingStatus = "Готов к общению!"

        // Добавляем приветственное сообщение
        let welcome = Message(
            content: "Привет! Я локальная нейросеть Gemma 2B. Работаю прямо на твоём iPhone, без интернета. Спрашивай что угодно!",
            isUser: false
        )
        messages.append(welcome)
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let bot = bot, !isLoading else { return }

        // Добавляем сообщение пользователя
        let userMessage = Message(content: text, isUser: true)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        currentResponse = ""

        // Создаём пустое сообщение для стриминга
        let botMessage = Message(content: "", isUser: false)
        messages.append(botMessage)
        let responseIndex = messages.count - 1

        // Настраиваем callback для обновления UI при стриминге
        bot.update = { [weak self] newContent in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentResponse = bot.output
                self.messages[responseIndex] = Message(content: self.currentResponse, isUser: false)
            }
        }

        // Запускаем генерацию
        await bot.respond(to: text)

        // Финальное обновление
        messages[responseIndex] = Message(content: bot.output, isUser: false)
        isLoading = false
    }

    func clearChat() {
        messages.removeAll()
        bot?.stop()

        if isModelLoaded {
            let welcome = Message(
                content: "Чат очищен. Начнём сначала!",
                isUser: false
            )
            messages.append(welcome)
        }
    }
}
