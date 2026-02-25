import Foundation

struct BookDTO: Codable, Identifiable, Hashable {
    struct PublisherSummaryDTO: Codable, Hashable {
        let id: Int
        let name: String
    }

    let id: Int
    let title: String
    let author: String
    let description: String?
    let ageMin: Int?
    let ageMax: Int?
    let language: String?
    let coverImageURL: String?
    let addedAt: String?
    let status: String?
    let publisher: PublisherSummaryDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case description
        case ageMin = "age_min"
        case ageMax = "age_max"
        case language
        case coverImageURL = "cover_image_url"
        case addedAt = "added_at"
        case status
        case publisher
    }
}

struct CatalogResponseDTO: Codable {
    struct PaginationDTO: Codable {
        let page: Int
        let perPage: Int
        let totalCount: Int

        enum CodingKeys: String, CodingKey {
            case page
            case perPage = "per_page"
            case totalCount = "total_count"
        }
    }

    let data: [BookDTO]
    let pagination: PaginationDTO
}
