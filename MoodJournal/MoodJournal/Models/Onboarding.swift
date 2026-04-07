import Foundation

struct OnboardingStep: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let imageName: String
    let order: Int
}

struct OnboardingData: Codable {
    let steps: [OnboardingStep]
    let totalSteps: Int
}

extension OnboardingStep {
    static let defaultSteps: [OnboardingStep] = [
        OnboardingStep(
            id: "1",
            title: "Отслеживайте настроение",
            description: "Записывайте своё настроение каждый день и следите за его изменениями с помощью наглядных графиков",
            imageName: "chart.line.uptrend.xyaxis",
            order: 1
        ),
        OnboardingStep(
            id: "2",
            title: "Ведите дневник",
            description: "Записывайте свои мысли и эмоции в заметках. Это поможет лучше понять себя",
            imageName: "note.text",
            order: 2
        ),
        OnboardingStep(
            id: "3",
            title: "Анализируйте факторы",
            description: "Отмечайте что влияет на ваше настроение: сон, спорт, работа и другие факторы",
            imageName: "list.bullet.clipboard",
            order: 3
        ),
        OnboardingStep(
            id: "4",
            title: "Общайтесь с AI-ассистентом",
            description: "Получайте персонализированные рекомендации от AI-помощника для улучшения настроения",
            imageName: "bubble.left.and.bubble.right",
            order: 4
        )
    ]
}
