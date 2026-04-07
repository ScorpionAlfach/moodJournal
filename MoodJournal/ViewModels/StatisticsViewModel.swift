import Foundation
import SwiftUI

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var statistics: MoodService.StatisticsResponse?
    @Published var graphData: MoodGraphData?
    @Published var todayMood: Mood?

    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var selectedPeriod: Period = .week
    @Published var showMoodPicker = false

    // Mood selection
    @Published var selectedMoodLevel: Mood.MoodLevel = .okay
    @Published var moodNote = ""
    @Published var selectedFactors: Set<Mood.MoodFactor> = []

    enum Period: Int, CaseIterable {
        case week = 7
        case twoWeeks = 14
        case month = 30
        case threeMonths = 90

        var title: String {
            switch self {
            case .week: return "Неделя"
            case .twoWeeks: return "2 недели"
            case .month: return "Месяц"
            case .threeMonths: return "3 месяца"
            }
        }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let statsTask = MoodService.shared.getStatistics()
            async let graphTask = MoodService.shared.getMoodGraph(period: selectedPeriod.rawValue)
            async let todayTask = MoodService.shared.getTodayMood()

            let (stats, graph, today) = try await (statsTask, graphTask, todayTask)

            statistics = stats
            graphData = graph
            todayMood = today

            if let today = today {
                selectedMoodLevel = today.level
                moodNote = today.note ?? ""
                selectedFactors = Set(today.factors)
            }
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Не удалось загрузить данные"
        }

        isLoading = false
    }

    func loadGraph() async {
        do {
            graphData = try await MoodService.shared.getMoodGraph(period: selectedPeriod.rawValue)
        } catch {
            // Silently fail for graph updates
        }
    }

    func saveMood() async {
        isLoading = true
        errorMessage = nil

        do {
            let mood = try await MoodService.shared.addMood(
                level: selectedMoodLevel,
                note: moodNote.isEmpty ? nil : moodNote,
                factors: Array(selectedFactors)
            )
            todayMood = mood
            showMoodPicker = false

            // Reload statistics
            await loadData()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Не удалось сохранить настроение"
        }

        isLoading = false
    }

    func toggleFactor(_ factor: Mood.MoodFactor) {
        if selectedFactors.contains(factor) {
            selectedFactors.remove(factor)
        } else {
            selectedFactors.insert(factor)
        }
    }

    func resetMoodSelection() {
        if let today = todayMood {
            selectedMoodLevel = today.level
            moodNote = today.note ?? ""
            selectedFactors = Set(today.factors)
        } else {
            selectedMoodLevel = .okay
            moodNote = ""
            selectedFactors = []
        }
    }
}
