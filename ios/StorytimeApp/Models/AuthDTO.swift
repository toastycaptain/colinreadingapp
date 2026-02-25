import Foundation

struct AuthResponseDTO: Codable {
    let user: UserDTO
    let jwt: String
}

struct ErrorResponseDTO: Codable {
    struct ErrorBody: Codable {
        let code: String
        let message: String
        let details: [String: String]?
    }

    let error: ErrorBody
}
