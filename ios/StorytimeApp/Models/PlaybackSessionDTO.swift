import Foundation

struct PlaybackSessionDTO: Codable {
    let playbackHlsURL: String
    let playbackToken: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case playbackHlsURL = "playback_hls_url"
        case playbackToken = "playback_token"
        case expiresAt = "expires_at"
    }
}
