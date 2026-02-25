import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case server(code: String, message: String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Unauthorized"
        case let .server(_, message):
            return message
        case let .transport(message):
            return message
        }
    }
}
