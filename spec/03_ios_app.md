# Storytime Video Library — iOS App (Swift/SwiftUI) Spec
> **Goal:** iOS-only app with two modes: **Parent Mode** and **Child Mode**.  
> **Child Mode is locked down**: only Library and Player controls (Play/Pause + Back to Library).  
> Backend is Rails API issuing short-lived CloudFront signed cookies for HLS playback.

---

## 0) Architecture Overview

### App structure (single app, two modes)
- **Authentication flow** (parent)
- **Mode switch** guarded by **Parent Gate**
  - Parent Gate options: FaceID/TouchID or PIN (MVP: PIN in-app)
- **Child Mode (default UX after selection)**
  - Library grid
  - Player
  - No search, no external navigation, no settings
- **Parent Mode**
  - Catalog search
  - Add/remove books to child library
  - Manage child profiles

### Recommended stack
- Swift 5.9+
- SwiftUI for UI
- AVKit / AVFoundation for HLS playback
- Networking: URLSession + async/await
- Secure storage: Keychain (JWT tokens)
- State management: ObservableObject / @StateObject

---

## 1) App Screens & Navigation

### 1.1 Auth
- Login screen (email/password)
- Optional register screen

### 1.2 Child selection
- After login, show list of child profiles
- Parent selects active child profile
- App enters Child Mode by default

### 1.3 Child Mode
**Library Screen**
- Grid of assigned books (cover + title)
- Tapping a book opens Player
- Only UI affordance besides book taps: (optional) “Parent” button that triggers Parent Gate

**Player Screen**
- Video playback using AVPlayer
- Only controls:
  - Play/Pause
  - Scrubbing optional (consider disabling for very young kids)
  - “Back to Library”
- When paused, show big resume button

### 1.4 Parent Mode
**Parent Home**
- Shows active child and their library
- Buttons:
  - Search Catalog
  - Manage Library (remove books)
  - Manage Children (create/edit)

**Catalog Search**
- Search bar + filters (age range optional)
- Results list with “Add” button
- Tapping result opens Book details page

**Child Library Management**
- List/grid of child’s books with remove action

---

## 2) Networking (API Client)

### 2.1 Base settings
- Base URL: `https://api.example.com/api/v1`
- Include Authorization header:
  - `Authorization: Bearer <jwt>`

### 2.2 Endpoints used by iOS
- Auth: login/register
- Children: list/create/update
- Catalog: search books
- Library: get/add/remove
- Playback session: create playback session for a book
- Usage events: post playback events

### 2.3 API models (Swift structs)
Define Codable models:
- UserDTO
- ChildProfileDTO
- BookDTO
- LibraryResponseDTO
- PlaybackSessionDTO (includes manifest url + cookies + expires_at)
- UsageEventRequestDTO

---

## 3) CloudFront Signed Cookies Handling (Critical)

### 3.1 Why cookies
HLS involves many segment requests. Signed cookies make all segment requests authorized without resigning each segment.

### 3.2 Implementation requirement
When playback session API returns cookies:
- Convert cookie DTO to `HTTPCookie` objects
- Insert into `HTTPCookieStorage.shared`
- Ensure cookie domain matches CloudFront domain (or your custom CDN domain)

### 3.3 Playback flow
1. User taps a book
2. Call `POST /children/{child_id}/playback_sessions` with book_id
3. Receive manifest URL + cookies
4. Store cookies
5. Initialize `AVPlayer` with manifest URL
6. Start playback

**Important:** Signed cookies expire quickly. If playback fails mid-stream due to expiration:
- Re-request a playback session and refresh cookies, then resume.

---

## 4) Parent Gate (Mode Security)

### MVP Parent Gate
- When user tries to enter Parent Mode, present a PIN entry.
- Store PIN (hashed) locally (Keychain) or store server-side per parent.
- Alternative: FaceID/TouchID using LocalAuthentication.

### Enforcement
- Child Mode UI must not show navigation into Parent features.
- Parent Mode requires successful gate each time (or time-based session, e.g., 5 minutes).

---

## 5) Video Player Requirements

### AVPlayer
- Use `AVPlayerViewController` wrapped for SwiftUI or a custom SwiftUI player wrapper.
- Controls restricted:
  - Hide default transport if needed and show custom Play/Pause + Back.
- Observe:
  - playback start
  - pause/resume
  - end reached
  - periodic time observer for heartbeats

### Usage events
Send events to backend:
- play_start when playback begins
- pause on pause
- resume on resume
- play_end on completion
- heartbeat every 30–60 seconds (optional MVP)

Include:
- child_id, book_id
- position_seconds
- occurred_at
- metadata: app version, device model

---

## 6) UX Constraints for Child Mode (Strict)
Child Mode must:
- Not include search
- Not include account settings
- Not include external links
- Not allow browsing entire catalog
- Only allow:
  - selecting from personal library
  - pausing/playing
  - returning to library

If you include a “Parent” button, it must invoke Parent Gate and not allow bypass.

---

## 7) Offline (Explicitly Out of Scope for MVP)
Do not implement offline download initially.
HLS streaming only.

---

## 8) App State & Data Caching

### Cache strategy (MVP)
- Cache child library list in memory for fast UI
- Refresh on:
  - app launch
  - after parent adds/removes books
- Cover images: let iOS cache via URLCache or use AsyncImage

### Error states
- Handle missing entitlement (show “Not available”)
- Handle processing video asset (show “This story is still being prepared”)
- Handle network failures gracefully

---

## 9) Deliverables for Codex (iOS)
Implement:
- SwiftUI app with navigation described above
- APIClient with async/await
- JWT storage in Keychain
- Parent Gate (PIN or FaceID)
- Library grid + player with restricted controls
- Playback session + cookie installation
- Usage event logging

