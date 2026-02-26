# iOS Launch Readiness Checklist

## Project Setup
- Create `StorytimeApp.xcodeproj` and add all files in `ios/StorytimeApp`.
- Wire build configurations:
  - Debug -> `ios/Configs/Debug.xcconfig`
  - Release -> `ios/Configs/Release.xcconfig`
- Add Info.plist keys:
  - `STORYTIME_API_BASE_URL`
  - `STORYTIME_PRIVACY_POLICY_URL`
  - `STORYTIME_TERMS_URL`
  - `STORYTIME_PRIVACY_POLICY_VERSION`

## Build & Signing
- Configure Team and automatic signing.
- Verify bundle id and version/build numbers.
- Build on latest iOS simulator and at least one physical device.

## QA Gates
- Parent login/register and child selection
- Parent catalog browse/filter/pagination
- Add/remove library items
- Child playback with captions, scrubbing, and resume
- Playback token refresh once on failure

## App Store Preparation
- App Privacy form completed (COPPA-sensitive fields)
- Age rating configured for children app
- Screenshots for all required device families
- Privacy policy URL publicly reachable
- Release notes and support URL added

## Release Steps
1. Run `fastlane ios beta` for TestFlight build.
2. Validate crash-free and playback metrics in TestFlight.
3. Submit final release build to App Store Connect.
