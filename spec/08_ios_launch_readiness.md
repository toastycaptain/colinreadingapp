# Storytime Video Library — iOS Launch Readiness Spec
> **Goal:** Prepare the iOS app for App Store submission by creating the Xcode project, configuring production environments, adding required assets, and addressing all App Store Review requirements.
> **Constraint:** No `.xcodeproj` currently exists — Swift source files must be integrated into a proper Xcode project structure.

---

## 0) Current State

What exists:
- All SwiftUI source files in `ios/StorytimeApp/` organized by feature (Views, ViewModels, Models, Networking, Services, App)
- `StorytimeApp.swift` entry point
- `AppConfig.swift` with `apiBaseURL` defaulting to `http://localhost:3000/api/v1`
- No `.xcodeproj` or `.xcworkspace`
- No app icons, launch screen, or Info.plist
- No production API URL configuration
- No build configurations for dev/staging/prod

---

## 1) Xcode Project Setup

### 1.1 Create Xcode project
- Product name: `Storytime`
- Organization identifier: (use your domain, e.g., `com.storytime`)
- Bundle identifier: `com.storytime.app`
- Minimum deployment target: iOS 17.0
- Interface: SwiftUI
- Language: Swift
- No Core Data, no tests target initially (add later)

### 1.2 Add all source files
Add all existing Swift files from `ios/StorytimeApp/` into the Xcode project, preserving the folder group structure:
- App/
- Models/
- Networking/
- Services/
- ViewModels/
- Views/Auth/
- Views/Child/
- Views/Parent/
- Views/Player/
- Views/Shared/

### 1.3 Folder references vs groups
Use **groups** (yellow folders in Xcode) that mirror the filesystem structure. Ensure file paths resolve correctly.

---

## 2) Build Configurations & Environments

### 2.1 Build configurations
Create three build configurations:
- **Debug** — local development, localhost API
- **Staging** — staging server, TestFlight
- **Release** — production server, App Store

### 2.2 Configuration files
Create `Config/` directory with environment-specific `.xcconfig` files:

**Debug.xcconfig:**
```
API_BASE_URL = http:/$()/localhost:3000/api/v1
BUNDLE_DISPLAY_NAME = Storytime Dev
BUNDLE_ID_SUFFIX = .dev
```

**Staging.xcconfig:**
```
API_BASE_URL = https:/$()/staging-api.storytime.com/api/v1
BUNDLE_DISPLAY_NAME = Storytime Beta
BUNDLE_ID_SUFFIX = .staging
```

**Release.xcconfig:**
```
API_BASE_URL = https:/$()/api.storytime.com/api/v1
BUNDLE_DISPLAY_NAME = Storytime
BUNDLE_ID_SUFFIX =
```

### 2.3 Update AppConfig.swift
Replace the current hardcoded URL with build configuration lookup:
```swift
enum AppConfig {
    static let apiBaseURL: String = {
        guard let url = Bundle.main.infoDictionary?["API_BASE_URL"] as? String else {
            return "http://localhost:3000/api/v1"
        }
        return url
    }()

    static let heartbeatIntervalSeconds: TimeInterval = 45
    static let parentGateSessionSeconds: TimeInterval = 300
}
```

### 2.4 Info.plist additions
Add to Info.plist:
- `API_BASE_URL` = `$(API_BASE_URL)` — populated from xcconfig
- `NSAppTransportSecurity` — allow localhost for Debug only
- `ITSAppUsesNonExemptEncryption` = `NO` (standard HTTPS only)

---

## 3) App Icons & Launch Screen

### 3.1 App icon
Create `AppIcon` asset in `Assets.xcassets`:
- Required sizes: 1024x1024 (App Store), plus all standard iOS sizes
- Design guidance: Simple, friendly, recognizable at small sizes
- Suggested: Open book with play button, warm colors, rounded corners
- Provide a single 1024x1024 PNG (Xcode auto-generates other sizes)

### 3.2 Launch screen
Create `LaunchScreen.storyboard` (or SwiftUI launch screen):
- App name "Storytime" centered
- App icon centered above the name
- Background color matching the app's primary theme
- No loading indicator (Apple HIG recommends static launch screens)

### 3.3 Accent color
Set the app's accent color in `Assets.xcassets`:
- Primary accent: warm, child-friendly color (e.g., a friendly orange or teal)
- Used for buttons, navigation, and interactive elements throughout the app

---

## 4) Signing & Capabilities

### 4.1 Signing
- Enable "Automatically manage signing" for development
- Configure provisioning profiles for staging (Ad Hoc) and production (App Store)
- Team: your Apple Developer account

### 4.2 Capabilities
Enable these capabilities in the Xcode project:
- **Keychain Sharing** — for JWT and PIN storage (access group: `com.storytime.app`)
- **Background Modes** — Audio (for continued playback when screen is locked)

### 4.3 Background audio
Add `AVAudioSession` configuration in `StorytimeApp.swift`:
- Set audio session category to `.playback`
- This allows children to listen to read-aloud videos with the screen locked
- Now Playing info (title, author) for lock screen display

---

## 5) App Store Metadata

### 5.1 App Store Connect configuration
- Primary category: **Education**
- Secondary category: **Books**
- Age rating: 4+ (no objectionable content)
- Content rights: Confirm you have rights to all content

### 5.2 App description
Prepare:
- App name: "Storytime"
- Subtitle: "Read-aloud stories for kids" (max 30 chars)
- Description: (up to 4000 chars, focus on parent value proposition)
- Keywords: (up to 100 chars, comma-separated)
- What's New: (for updates)

### 5.3 Screenshots
Prepare screenshots for:
- iPhone 6.7" (required)
- iPhone 6.5" (required)
- iPad 12.9" (if supporting iPad)

Minimum 3 screenshots, recommended 5-8 showing:
1. Child library view with colorful covers
2. Video player in action
3. Parent catalog search
4. Parent adding books to child library
5. Child selection screen

### 5.4 Privacy policy URL
- Required for App Store submission
- Must be accessible via HTTPS
- See `09_coppa_compliance.md` for privacy policy requirements
- Host at: `https://storytime.com/privacy` or equivalent

### 5.5 Support URL
- Required: `https://storytime.com/support` or equivalent

---

## 6) App Review Preparation

### 6.1 Demo account
Provide App Review with a demo parent account:
- Pre-populated with a child profile
- Child library pre-loaded with at least 2-3 books
- Books must have ready video assets

### 6.2 Review notes
Include notes explaining:
- The app has two modes: Parent and Child
- Parent Gate PIN is required to access parent features
- Demo PIN: (provide the PIN for the demo account)
- Child mode is intentionally restricted (limited controls, no search)

### 6.3 Common rejection reasons to address
- **Missing privacy policy** — must be linked in App Store Connect AND in the app
- **No account deletion** — Apple requires account deletion. Add "Delete Account" option in Parent Mode settings
- **Incomplete information** — ensure all metadata fields are filled
- **Broken functionality** — all features must work with the demo account

### 6.4 Account deletion requirement
Add to Parent Mode (new `ParentSettingsView`):
- "Delete Account" option
- Confirmation dialog explaining data will be permanently removed
- Backend endpoint: `DELETE /api/v1/auth/account`
  - Deletes user, child profiles, library items, usage events
  - Returns 204 No Content
  - iOS clears keychain and returns to login

---

## 7) Backend Changes for Launch

### 7.1 Account deletion endpoint
`DELETE /api/v1/auth/account`
- Requires parent JWT
- Deletes:
  - All child_profiles belonging to the user
  - All library_items for those children
  - All playback_sessions for those children
  - All usage_events for those children (or anonymize — see `09_coppa_compliance.md`)
  - The user record itself
- Returns 204 No Content

### 7.2 Production CORS
Update `CORS_ALLOWED_ORIGINS` for production to include:
- The production admin domain
- No wildcard origins in production

### 7.3 Production database
Ensure Rails `config/database.yml` correctly reads `DATABASE_URL` for production.

---

## 8) iOS Settings View

### 8.1 New view: ParentSettingsView
Accessible from `ParentHomeView` via a gear icon or "Settings" row:
- **Account** section:
  - Email display (read-only)
  - "Delete Account" (destructive action, see 6.4)
  - "Log Out" (existing functionality, moved here)
- **Parent Gate** section:
  - "Change PIN" — enter current PIN, then new PIN
- **About** section:
  - App version
  - Privacy Policy link (opens in SFSafariViewController)
  - Terms of Service link
  - Support / Contact link

---

## 9) Testing Requirements

### iOS tests
- AppConfig: verify API URL resolves from Info.plist
- Account deletion: verify keychain cleared and navigation reset

### Backend tests
- Account deletion: verify cascade deletes all child data
- Account deletion: verify returns 204

---

## 10) Deliverables for Codex (Launch Readiness)
Implement:
- Xcode project file with all source files organized in groups
- Three build configurations (Debug, Staging, Release) with xcconfig files
- AppConfig updated to read API_BASE_URL from build config
- App icon asset catalog (placeholder 1024x1024 or final)
- Launch screen storyboard
- Accent color in asset catalog
- Background audio capability and AVAudioSession setup
- ParentSettingsView with account deletion, PIN change, privacy/support links
- Backend: DELETE /api/v1/auth/account endpoint with cascade deletion
- Info.plist with all required keys
- App Store metadata templates (description, keywords, review notes)
