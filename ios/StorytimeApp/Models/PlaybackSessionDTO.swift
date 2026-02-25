import Foundation

struct PlaybackCookieDTO: Codable, Hashable {
    let name: String
    let value: String
    let domain: String
    let path: String
    let expires: String
    let secure: Bool?
    let httpOnly: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case value
        case domain
        case path
        case expires
        case secure
        case httpOnly = "http_only"
    }
}

struct PlaybackSessionDTO: Codable {
    let playbackManifestURL: String
    let cookies: [PlaybackCookieDTO]
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case playbackManifestURL = "playback_manifest_url"
        case cookies
        case expiresAt = "expires_at"
    }
}
