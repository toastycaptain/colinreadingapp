import Foundation

struct UsageEventRequestDTO: Codable {
    let childID: Int
    let bookID: Int
    let eventType: String
    let positionSeconds: Int?
    let occurredAt: String
    let metadata: [String: String]

    enum CodingKeys: String, CodingKey {
        case childID = "child_id"
        case bookID = "book_id"
        case eventType = "event_type"
        case positionSeconds = "position_seconds"
        case occurredAt = "occurred_at"
        case metadata
    }
}
