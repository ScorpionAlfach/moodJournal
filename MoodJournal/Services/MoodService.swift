import Foundation

actor MoodService {
    static let shared = MoodService()

    private init() {}

    struct StatisticsResponse: Codable {
        let totalMoods: Int
        let averageLevel: Double
        let mostCommonFactors: [Mood.MoodFactor]
        let streakDays: Int
        let lastMood: Mood?
    }

    func getStatistics() async throws -> StatisticsResponse {
        return try await NetworkManager.shared.request(
            endpoint: "/statistics",
            method: .get
        )
    }

    func addMood(level: Mood.MoodLevel, note: String?, factors: [Mood.MoodFactor]) async throws -> Mood {
        let request = CreateMoodRequest(level: level, note: note, factors: factors)
        return try await NetworkManager.shared.request(
            endpoint: "/mood",
            method: .post,
            body: request
        )
    }

    func getMoodGraph(period: Int = 7) async throws -> MoodGraphData {
        return try await NetworkManager.shared.request(
            endpoint: "/mood/graph",
            method: .get,
            queryItems: [URLQueryItem(name: "period", value: String(period))]
        )
    }

    func getTodayMood() async throws -> Mood? {
        struct TodayMoodResponse: Codable {
            let mood: Mood?
        }
        let response: TodayMoodResponse = try await NetworkManager.shared.request(
            endpoint: "/mood/today",
            method: .get
        )
        return response.mood
    }
}
