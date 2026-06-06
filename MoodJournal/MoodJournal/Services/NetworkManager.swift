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

    private let baseURL = "https://moodjournal.ru/api"
    private var authToken: String?

    private init() {
        #if DEBUG
        print("API base URL:", baseURL)
        #endif
    }

    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    private func buildRequest(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        queryItems: [URLQueryItem]?
    ) throws -> URLRequest {
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

        return request
    }

    private func performRequest(_ request: URLRequest, maxRetries: Int = 2) async throws -> (Data, HTTPURLResponse) {
        var lastError: Error?

        for attempt in 0...maxRetries {
            if attempt > 0 {
                let delay = UInt64(attempt) * 1_000_000_000
                try? await Task.sleep(nanoseconds: delay)
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.noData
                }

                // Не повторяем при клиентских ошибках (4xx)
                if httpResponse.statusCode >= 400 && httpResponse.statusCode < 500 {
                    return (data, httpResponse)
                }

                // Повторяем при серверных ошибках (5xx)
                if httpResponse.statusCode >= 500 && attempt < maxRetries {
                    lastError = NetworkError.serverError("Ошибка сервера")
                    continue
                }

                return (data, httpResponse)
            } catch let error as NetworkError {
                throw error
            } catch {
                lastError = error
                if attempt == maxRetries {
                    throw NetworkError.networkError(error)
                }
            }
        }

        throw lastError.map { NetworkError.networkError($0) } ?? NetworkError.noData
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let urlRequest = try buildRequest(endpoint: endpoint, method: method, body: body, queryItems: queryItems)
        let (data, httpResponse) = try await performRequest(urlRequest)

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
            throw NetworkError.decodingError
        }
    }

    func requestWithoutResponse(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) async throws {
        let urlRequest = try buildRequest(endpoint: endpoint, method: method, body: body, queryItems: nil)
        let (data, httpResponse) = try await performRequest(urlRequest)

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
