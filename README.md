# Дневник настроения (Mood Journal)

Красивое iOS приложение для отслеживания настроения с AI-ассистентом и полноценным бэкендом.

## Структура проекта

```
moodJournal/
├── MoodJournal/              # iOS приложение (Swift/SwiftUI)
│   └── MoodJournal/
│       ├── App/              # Главные файлы приложения
│       ├── Models/           # Модели данных
│       ├── Views/            # UI компоненты
│       │   ├── Auth/         # Экраны авторизации
│       │   ├── Onboarding/   # Онбординг
│       │   ├── Profile/      # Профиль пользователя
│       │   ├── Statistics/   # Статистика и графики
│       │   ├── Notes/        # Заметки (CRUD)
│       │   ├── Calendar/     # Календарь
│       │   ├── AI/           # AI-ассистент
│       │   └── Components/   # Переиспользуемые компоненты
│       ├── ViewModels/       # View Models (MVVM)
│       ├── Services/         # Сетевые сервисы
│       └── Utils/            # Утилиты и расширения
│
└── backend/                  # Node.js бэкенд
    ├── config/               # Конфигурация
    └── src/
        ├── models/           # Mongoose модели
        ├── routes/           # Express роуты
        ├── middleware/       # Middleware (auth)
        └── services/         # Бизнес-логика (email, AI)
```

## Функциональность

### iOS приложение

#### Регистрация и авторизация
- Ввод email для регистрации
- Вход по email без кода подтверждения
- Заполнение профиля (имя, фамилия, телефон, возраст, пол)
- Онбординг для новых пользователей

#### Профиль
- Просмотр и редактирование данных
- Выход из аккаунта
- Удаление аккаунта

#### Статистика настроения
- Выбор настроения на сегодня (5 уровней)
- Добавление заметки к настроению
- Выбор факторов (сон, спорт, работа и др.)
- График настроения за период (неделя, 2 недели, месяц, 3 месяца)
- Статистика: среднее, серия дней, популярные факторы

#### Заметки
- Список заметок с пагинацией
- Создание, редактирование, удаление
- Привязка настроения и тегов
- Фильтрация и поиск
- Сортировка

#### Календарь
- Просмотр по месяцам
- Цветовая индикация настроения
- Детальный просмотр дня
- Фильтры по факторам

#### AI-ассистент
- Чат с AI для рекомендаций
- Персонализированные советы
- Рекомендации по улучшению настроения

### Backend API

#### Аутентификация
- `POST /api/auth/register` — вход по email или старт регистрации
- `POST /api/auth/complete-registration` — завершение регистрации
- `POST /api/auth/login` — вход
- `POST /api/auth/logout` — выход

#### Онбординг
- `GET /api/onboarding` — шаги онбординга
- `POST /api/onboarding/complete` — завершение

#### Профиль
- `GET /api/profile` — получение
- `PUT /api/profile` — обновление
- `DELETE /api/profile` — удаление

#### Настроение
- `GET /api/statistics` — статистика
- `POST /api/mood` — добавление
- `GET /api/mood/today` — настроение сегодня
- `GET /api/mood/graph` — данные для графика

#### Заметки
- `GET /api/notes` — список с фильтрацией
- `POST /api/notes` — создание
- `GET /api/notes/:id` — получение
- `PUT /api/notes/:id` — обновление
- `DELETE /api/notes/:id` — удаление

#### Календарь
- `GET /api/calendar` — данные месяца
- `GET /api/calendar/:date` — детали дня
- `GET /api/calendar/filters/list` — фильтры

#### AI
- `POST /api/ai/chat` — сообщение ассистенту
- `GET /api/ai/suggestions` — рекомендации

## Установка и запуск

### Backend

```bash
cd backend

# Установка зависимостей
npm install

# Копирование конфигурации
cp .env.example .env
# Отредактируйте .env файл

# Запуск MongoDB (должен быть установлен)
mongod

# Запуск сервера
npm run dev
```

### iOS приложение

1. Откройте `MoodJournal/` в Xcode
2. Измените URL сервера в `NetworkManager.swift` (по умолчанию `localhost:3000`)
3. Запустите на симуляторе или устройстве

## Технологии

### iOS
- Swift 5.9+
- SwiftUI
- iOS 17+
- Charts framework
- MVVM архитектура
- Async/await

### Backend
- Node.js 18+
- Express.js
- MongoDB + Mongoose
- JWT аутентификация
- Nodemailer для email
- GigaChat API для AI-ассистента и персональных рекомендаций

### AI / GigaChat

AI-функции backend используют GigaChat. Для локального запуска заполните переменные в `backend/.env`:

```bash
GIGACHAT_CREDENTIALS=your-gigachat-authorization-key
GIGACHAT_SCOPE=GIGACHAT_API_PERS
GIGACHAT_MODEL=GigaChat
```

`GIGACHAT_CREDENTIALS` — это Authorization Key из GigaChat Studio, а не отдельный client secret.

## Дизайн

Приложение использует современный дизайн с:
- Градиентами (фиолетовый/индиго)
- Карточками с тенями
- Плавными анимациями
- Эмодзи для настроения
- Адаптивными цветами

## Лицензия

MIT License
