import Foundation

// Keeps the backend address in one place so localhost is easy to change later.
enum FocusPetAPIConfig {
    nonisolated(unsafe) static let baseURL = URL(string: "http://127.0.0.1:8000")!
}

// Request model for POST /api/v1/ai/split-task.
// The backend expects the user's raw sentence under `user_input`.
private struct SplitTaskAPIRequest: Encodable {
    let userInput: String

    enum CodingKeys: String, CodingKey {
        case userInput = "user_input"
    }
}

// Response model for POST /api/v1/ai/split-task.
// The backend returns a simple array of generated task titles.
private struct SplitTaskAPIResponse: Decodable {
    let tasks: [String]
}

enum SplitTaskAPIError: LocalizedError {
    case invalidResponse
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "这次整理有点卡住了，再试一次就好。"
        case let .serverMessage(message):
            return message
        }
    }
}

struct APISplitTaskProvider: SplitTaskProviding {
    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    nonisolated init(
        baseURL: URL = FocusPetAPIConfig.baseURL,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    nonisolated func generateSubtasks(from input: String) async throws -> [String] {
        let normalizedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedInput.isEmpty else { return [] }

        let requestBody = SplitTaskAPIRequest(userInput: normalizedInput)
        let endpoint = baseURL.appending(path: "api/v1/ai/split-task")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(requestBody)

        // Sends the real network request with URLSession, then validates and decodes the JSON result.
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SplitTaskAPIError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw try decodeServerError(from: data)
        }

        let payload = try decoder.decode(SplitTaskAPIResponse.self, from: data)
        return payload.tasks
    }

    private nonisolated func decodeServerError(from data: Data) throws -> SplitTaskAPIError {
        if let message = try? decoder.decode(APIErrorMessage.self, from: data).detail,
           !message.isEmpty {
            return .serverMessage(message)
        }

        return .serverMessage("这次整理没有成功，再试一次就好。")
    }
}

private struct APIErrorMessage: Decodable {
    let detail: String
}
