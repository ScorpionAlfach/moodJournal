import Foundation

actor CalendarService {
    static let shared = CalendarService()

    private init() {}

    func getCalendarData(month: Int, year: Int) async throws -> CalendarData {
        return try await NetworkManager.shared.request(
            endpoint: "/calendar",
            method: .get,
            queryItems: [
                URLQueryItem(name: "month", value: String(month)),
                URLQueryItem(name: "year", value: String(year))
            ]
        )
    }

    func getDayDetail(date: String) async throws -> CalendarDayDetail {
        return try await NetworkManager.shared.request(
            endpoint: "/calendar/\(date)",
            method: .get
        )
    }

    func getFilters() async throws -> [CalendarFilter] {
        struct FiltersResponse: Codable {
            let filters: [CalendarFilter]
        }
        let response: FiltersResponse = try await NetworkManager.shared.request(
            endpoint: "/calendar/filters",
            method: .get
        )
        return response.filters
    }
}
