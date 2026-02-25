import Foundation

struct UserDTO: Codable, Identifiable {
    let id: Int
    let email: String
    let role: String
}
