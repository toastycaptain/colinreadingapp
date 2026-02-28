# Repo Patch — iOS updates for Mux (ios/StorytimeApp)
This document is **repo-specific**. The iOS SwiftUI sources live in:

- `ios/StorytimeApp/`

Currently implemented:
- Playback session returns CloudFront cookies (`PlaybackSessionDTO` includes cookies)
- App installs cookies before AVPlayer playback (per `ios/README.md`)

We will change playback to **Mux signed playback tokens**.

---

## A) Update DTOs
Edit:
- `ios/StorytimeApp/Models/PlaybackSessionDTO.swift`

Replace current structs with:
```swift
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
```

Delete `PlaybackCookieDTO` and any cookie-related types.

---

## B) Update player flow
Find the code that currently:
1) calls `createPlaybackSession(childID:bookID:)`
2) installs cookies into `HTTPCookieStorage`
3) plays `playback_manifest_url`

Replace with:
1) call `createPlaybackSession(...)` (same APIClient method name is fine)
2) build final URL:
   - `let url = URL(string: "\(dto.playbackHlsURL)?token=\(dto.playbackToken)")!`
3) create AVPlayer with `AVPlayerItem(url: url)`

---

## C) Remove cookie installer
Search and delete cookie logic:
```bash
rg "HTTPCookie" ios/StorytimeApp
rg "CloudFront" ios/StorytimeApp
rg "cookies" ios/StorytimeApp
```
Remove those helper files and calls.

---

## D) Token refresh strategy (MVP)
Mux signed tokens should be short-lived (5 minutes recommended).

If playback fails due to token expiry:
- request a fresh playback session
- replace the AVPlayerItem
- optionally seek to last known position

MVP: implement basic retry once on failure.

---

## E) No other iOS changes required
Everything else remains:
- Parent/Child modes
- library and catalog screens
- usage events

