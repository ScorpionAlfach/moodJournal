import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .noData:
            return "Данные не получены"
        case .decodingError:
            return "Ошибка обработки данных"
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Необходима авторизация"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

actor NetworkManager {
    static let shared = NetworkManager()

    private let baseURL: String
    private var authToken: String?

    private init() {
        // Продакшн сервер
        self.baseURL = "https://nikita-002.host.continental-c.com/api"
    }

    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        guard var urlComponents = URLComponents(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }

        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.noData
            }

            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }

            if httpResponse.statusCode >= 400 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw NetworkError.serverError(errorResponse.message)
                }
                throw NetworkError.serverError("Ошибка сервера")
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                throw NetworkError.decodingError
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }

    func requestWithoutResponse(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }

        if httpResponse.statusCode >= 400 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse.message)
            }
            throw NetworkError.serverError("Ошибка сервера")
        }
    }

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
}

struct ErrorResponse: Codable {
    let message: String
    let error: String?
}

struct SuccessResponse: Codable {
    let message: String
    let success: Bool
}
