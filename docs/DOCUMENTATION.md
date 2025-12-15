# Локальный ИИ-чат на iPhone: Полное руководство

## Обзор проекта

**LocalChat** — iOS-приложение, которое запускает языковую модель Gemma 2B прямо на iPhone, без подключения к интернету. Модель работает локально на устройстве.

### Технологии
- **Swift / SwiftUI** — язык и фреймворк для iOS
- **LLM.swift** — библиотека для запуска GGUF-моделей на Apple устройствах
- **Gemma 2B (Q4_K_M)** — квантизированная модель от Google (~1.5 ГБ)
- **llama.cpp** — движок инференса (используется внутри LLM.swift)

---

## Требования

### Аппаратные требования
- **Mac** с macOS 13+ (Ventura или новее)
- **iPhone** с iOS 16+ и минимум 4 ГБ RAM (рекомендуется iPhone 12 и новее)
- **USB-кабель** для подключения iPhone к Mac

### Программные требования
- **Xcode 15+** (скачать из App Store, ~25 ГБ)
- **Apple ID** (бесплатный, для подписи приложения)

---

## Часть 1: Установка и настройка Xcode

### 1.1 Скачивание Xcode
1. Откройте **App Store** на Mac
2. Найдите **"Xcode"**
3. Нажмите **"Получить"** → **"Установить"**
4. Дождитесь загрузки (~25 ГБ, может занять 30-60 минут)

### 1.2 Первый запуск Xcode
1. Запустите Xcode из папки Applications
2. Примите лицензионное соглашение
3. Дождитесь установки дополнительных компонентов

### 1.3 Добавление Apple ID
1. **Xcode → Settings** (или Cmd+,)
2. Вкладка **Accounts**
3. Нажмите **+** → **Apple ID**
4. Войдите своим Apple ID (можно обычный, не разработчика)

---

## Часть 2: Создание проекта

### 2.1 Новый проект
1. **File → New → Project** (или Cmd+Shift+N)
2. Выберите **iOS → App**
3. Нажмите **Next**

### 2.2 Настройки проекта
- **Product Name:** `LocalChat`
- **Team:** Ваш Apple ID (Personal Team)
- **Organization Identifier:** `com.yourname` (любой)
- **Interface:** `SwiftUI`
- **Language:** `Swift`
- Снимите галочки с **Core Data** и **Tests** (опционально)

### 2.3 Сохранение
1. Нажмите **Next**
2. Выберите папку для сохранения
3. Нажмите **Create**

---

## Часть 3: Добавление библиотеки LLM.swift

### 3.1 Добавление пакета
1. В Xcode: **File → Add Package Dependencies...**
2. В поле поиска вставьте URL:
   ```
   https://github.com/eastriverlee/LLM.swift
   ```
3. Нажмите **Enter** и дождитесь загрузки
4. **Dependency Rule:** Up to Next Major Version
5. Убедитесь что в **"Add to Target"** выбран `LocalChat`
6. Нажмите **Add Package**

### 3.2 Подключение к Target (ВАЖНО!)
Если после добавления пакета появляется ошибка **"No such module 'LLM'"**:

1. В левой панели нажмите на **LocalChat** (синяя иконка проекта)
2. В центре выберите **Targets → LocalChat**
3. Перейдите на вкладку **Build Phases**
4. Раскройте секцию **"Link Binary With Libraries"**
5. Нажмите **+**
6. Найдите **LLM** в списке (под "LLM Package")
7. Выберите его и нажмите **Add**

---

## Часть 4: Создание файлов приложения

### 4.1 Структура проекта
```
LocalChat/
├── LocalChatApp.swift      (точка входа, не меняем)
├── ContentView.swift       (обновляем)
├── Message.swift           (создаём)
├── ChatViewModel.swift     (создаём)
├── ChatView.swift          (создаём)
├── gemma-2-2b-it-Q4_K_M.gguf  (добавляем модель)
└── Assets.xcassets/
```

### 4.2 Создание файла Message.swift
1. **Правый клик** на папку LocalChat → **New File**
2. Выберите **Swift File** → **Next**
3. Имя: `Message` → **Create**
4. Замените содержимое на:

```swift
import Foundation

struct Message: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date

    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}
```

### 4.3 Создание файла ChatViewModel.swift
Создайте новый Swift файл `ChatViewModel.swift`:

```swift
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
```

### 4.4 Создание файла ChatView.swift
Создайте новый Swift файл `ChatView.swift`:

```swift
import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !viewModel.isModelLoaded {
                    LoadingView(status: viewModel.loadingStatus)
                } else {
                    MessageListView(
                        messages: viewModel.messages,
                        isLoading: viewModel.isLoading
                    )

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
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let status: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

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
                Text(message.content)
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
            TextField("Сообщение...", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .focused(isFocused)

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
```

### 4.5 Обновление ContentView.swift
Замените содержимое `ContentView.swift` на:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ChatView()
    }
}

#Preview {
    ContentView()
}
```

---

## Часть 5: Добавление модели

### 5.1 Скачивание модели
Модель Gemma 2B в формате GGUF (~1.5 ГБ):
- **Название файла:** `gemma-2-2b-it-Q4_K_M.gguf`
- **Источник:** Hugging Face (bartowski/gemma-2-2b-it-GGUF)

### 5.2 Добавление в проект
1. Откройте Finder и найдите файл модели
2. **Перетащите** файл `.gguf` в папку LocalChat в Xcode
3. В появившемся диалоге:
   - ✅ **Copy items if needed**
   - ✅ **Add to target: LocalChat**
4. Нажмите **Finish**

### 5.3 Проверка
Файл должен появиться в левой панели Xcode рядом с другими файлами.

---

## Часть 6: Запуск на iPhone

### 6.1 Подключение iPhone
1. Подключите iPhone к Mac кабелем USB/USB-C
2. Разблокируйте iPhone
3. При запросе "Доверять этому компьютеру?" — нажмите **Доверять**

### 6.2 Выбор устройства в Xcode
1. В верхней панели Xcode, рядом с кнопкой ▶️ (Run)
2. Нажмите на выпадающий список устройств
3. Выберите ваш **iPhone** (не симулятор!)

### 6.3 Подписание приложения
1. Нажмите на **LocalChat** (синяя иконка проекта)
2. Targets → **LocalChat**
3. Вкладка **Signing & Capabilities**
4. ✅ **Automatically manage signing**
5. **Team:** Выберите ваш Apple ID (Personal Team)

### 6.4 Включение Developer Mode (iOS 16+)
**Важно:** Начиная с iOS 16 нужно включить режим разработчика!

На iPhone:
1. **Настройки → Конфиденциальность и безопасность**
2. Прокрутите вниз до конца
3. Найдите **"Режим разработчика"** (Developer Mode)
4. Включите переключатель
5. Нажмите **"Перезагрузить"** в появившемся окне
6. После перезагрузки нажмите **"Включить"**
7. Введите пароль iPhone

### 6.5 Первый запуск
1. Нажмите **▶️ Run** (или Cmd+R)
2. Дождитесь компиляции
3. На iPhone появится запрос — следуйте инструкциям ниже

### 6.6 Доверие разработчику (первый раз)
На iPhone:
1. **Настройки → Основные → VPN и управление устройством**
2. Найдите ваш Apple ID в списке
3. Нажмите **Доверять**
4. Вернитесь в Xcode и нажмите Run снова

---

## Часть 7: Возможные проблемы и решения

### Проблема: "No such module 'LLM'"
**Причина:** Пакет добавлен в проект, но не подключен к target.

**Решение:**
1. LocalChat (проект) → Targets → LocalChat
2. Вкладка **Build Phases**
3. **Link Binary With Libraries** → нажмите **+**
4. Добавьте **LLM**

### Проблема: "Signing requires a development team"
**Причина:** Не выбран Team для подписи.

**Решение:**
1. Signing & Capabilities → Team
2. Выберите ваш Apple ID (Personal Team)

### Проблема: "Untrusted Developer"
**Причина:** iPhone не доверяет приложению.

**Решение:**
На iPhone: Настройки → Основные → VPN и управление устройством → Доверять

### Проблема: "Waiting to reconnect to iPhone"
**Причина:** Потеряно соединение с устройством.

**Решение:**
1. Отключите и подключите кабель
2. Разблокируйте iPhone
3. В Xcode: Window → Devices and Simulators → проверьте статус

### Проблема: "Model not found in Bundle"
**Причина:** Файл .gguf не добавлен в target.

**Решение:**
1. Выберите файл .gguf в левой панели
2. В правой панели (File Inspector)
3. Target Membership → ✅ LocalChat

### Проблема: Приложение вылетает при загрузке модели
**Причина:** Недостаточно памяти на устройстве.

**Решение:**
- Закройте другие приложения на iPhone
- Используйте более компактную модель (Q4_K_S вместо Q4_K_M)
- Используйте iPhone с 6+ ГБ RAM

---

## Часть 8: Оптимизация и улучшения

### 8.1 Увеличение лимита памяти
Для больших моделей добавьте в Info.plist:
```xml
<key>com.apple.developer.kernel.increased-memory-limit</key>
<true/>
```

### 8.2 Альтернативные модели
| Модель | Размер | RAM | Качество |
|--------|--------|-----|----------|
| Gemma 2B Q4_K_S | 1.3 ГБ | 3 ГБ | Хорошее |
| Gemma 2B Q4_K_M | 1.5 ГБ | 4 ГБ | Лучше |
| Phi-3 Mini Q4 | 2.2 ГБ | 4 ГБ | Отличное |
| Llama 3.2 1B | 0.7 ГБ | 2 ГБ | Базовое |

### 8.3 Системные промпты
Можно настроить поведение модели через системный промпт в `ChatViewModel.swift`.

---

## Часть 9: Мониторинг ресурсов

### 9.1 Как измерить производительность
В Xcode во время работы приложения:
1. Нажмите **Cmd+7** (Debug Navigator)
2. Увидите метрики в реальном времени: CPU, Memory, Energy, Disk, Network

### 9.2 Реальные замеры (iPhone, Gemma 2B Q4_K_M)

#### Во время генерации ответа:
| Метрика | Значение |
|---------|----------|
| CPU | 65% |
| Memory | 355.9 MB |
| Energy Impact | Very High |
| Disk | 400 KB/s |
| Network | **Zero KB/s** |

#### В состоянии покоя (модель загружена, ожидание ввода):
| Метрика | Значение |
|---------|----------|
| CPU | 0% |
| Memory | 355.2 MB |
| Energy Impact | High |
| Disk | Zero KB/s |
| Network | **Zero KB/s** |

### 9.3 Ключевые выводы

1. **Network: Zero KB/s** — подтверждает что модель работает полностью офлайн, без интернета

2. **Memory: ~355 MB** — стабильное потребление памяти после загрузки модели (модель 1.5 ГБ на диске сжата, в RAM занимает меньше)

3. **CPU: 0% → 65%** — процессор нагружается только во время генерации, в покое не тратит ресурсы

4. **Energy Impact: High/Very High** — во время генерации телефон греется, это нормально для локального инференса

5. **После закрытия приложения** — вся память освобождается, CPU не используется, батарея не расходуется

### 9.4 Рекомендации по энергопотреблению

- Не держите приложение открытым без необходимости
- Закрывайте (смахивайте) приложение после использования
- При длительном использовании телефон может нагреться — это нормально
- Для экономии батареи используйте короткие запросы

---

## Ссылки

- **LLM.swift:** https://github.com/eastriverlee/LLM.swift
- **Gemma модели:** https://huggingface.co/google/gemma-2-2b-it
- **GGUF модели:** https://huggingface.co/bartowski/gemma-2-2b-it-GGUF
- **Apple Developer:** https://developer.apple.com

---

## История изменений

| Дата | Версия | Изменения |
|------|--------|-----------|
| 2025-12-15 | 1.0 | Начальная версия документации |

---

*Документация создана для проекта LocalChat — локального ИИ-чата на iPhone.*
