import Foundation
import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var calendarData: CalendarData?
    @Published var selectedDayDetail: CalendarDayDetail?
    @Published var filters: [CalendarFilter] = CalendarFilter.defaultFilters
    @Published var selectedFilters: Set<String> = []

    @Published var currentMonth: Int
    @Published var currentYear: Int
    @Published var selectedDate: String?

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showDayDetail = false
    @Published var showFilters = false

    init() {
        let now = Date()
        let calendar = Calendar.current
        currentMonth = calendar.component(.month, from: now)
        currentYear = calendar.component(.year, from: now)
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"

        var components = DateComponents()
        components.year = currentYear
        components.month = currentMonth
        components.day = 1

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date).capitalized
        }
        return ""
    }

    var daysInMonth: [CalendarDay?] {
        guard let data = calendarData else { return [] }

        var components = DateComponents()
        components.year = currentYear
        components.month = currentMonth
        components.day = 1

        guard let firstDay = Calendar.current.date(from: components) else { return [] }

        let weekday = Calendar.current.component(.weekday, from: firstDay)
        // Adjust for Monday start (Russian calendar)
        let offset = (weekday + 5) % 7

        var result: [CalendarDay?] = Array(repeating: nil, count: offset)

        let range = Calendar.current.range(of: .day, in: .month, for: firstDay)!
        let daysCount = range.count

        for day in 1...daysCount {
            let dateString = String(format: "%04d-%02d-%02d", currentYear, currentMonth, day)
            if let calendarDay = data.days.first(where: { $0.date == dateString }) {
                result.append(calendarDay)
            } else {
                result.append(CalendarDay(
                    date: dateString,
                    moodLevel: nil,
                    moodCount: 0,
                    hasNotes: false,
                    factors: []
                ))
            }
        }

        return result
    }

    var filteredDays: [CalendarDay?] {
        guard !selectedFilters.isEmpty else { return daysInMonth }

        return daysInMonth.map { day in
            guard let day = day else { return nil }

            let matchesFilter = selectedFilters.allSatisfy { filter in
                switch filter {
                case "sleep":
                    return day.factors.contains(.sleep)
                case "no_sleep":
                    return day.factors.contains(.noSleep)
                case "exercise":
                    return day.factors.contains(.exercise)
                case "good_mood":
                    return (day.moodLevel ?? 0) >= 4
                case "bad_mood":
                    return (day.moodLevel ?? 3) <= 2
                default:
                    return true
                }
            }

            return matchesFilter ? day : CalendarDay(
                date: day.date,
                moodLevel: nil,
                moodCount: 0,
                hasNotes: false,
                factors: []
            )
        }
    }

    func loadCalendarData() async {
        isLoading = true
        errorMessage = nil

        do {
            calendarData = try await CalendarService.shared.getCalendarData(
                month: currentMonth,
                year: currentYear
            )
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Не удалось загрузить календарь"
        }

        isLoading = false
    }

    func loadFilters() async {
        do {
            filters = try await CalendarService.shared.getFilters()
        } catch {
            filters = CalendarFilter.defaultFilters
        }
    }

    func loadDayDetail(date: String) async {
        selectedDate = date
        isLoading = true
        errorMessage = nil

        do {
            selectedDayDetail = try await CalendarService.shared.getDayDetail(date: date)
            showDayDetail = true
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Не удалось загрузить данные"
        }

        isLoading = false
    }

    func previousMonth() {
        if currentMonth == 1 {
            currentMonth = 12
            currentYear -= 1
        } else {
            currentMonth -= 1
        }
        Task {
            await loadCalendarData()
        }
    }

    func nextMonth() {
        if currentMonth == 12 {
            currentMonth = 1
            currentYear += 1
        } else {
            currentMonth += 1
        }
        Task {
            await loadCalendarData()
        }
    }

    func toggleFilter(_ filter: String) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
    }

    func clearFilters() {
        selectedFilters.removeAll()
    }
}
