import Foundation

struct ChildProfileDTO: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let avatarURL: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
