# Storytime iOS App

This folder contains the SwiftUI implementation for the Storytime iOS app MVP.

## Scope Implemented

- Parent authentication (login/register)
- Child profile selection
- Child Mode (locked down):
  - Library grid only
  - Player with play/pause + back to library
  - Optional Parent button behind Parent Gate PIN
- Parent Mode:
  - Catalog search
  - Add/remove books from active child library
  - Manage/select/create child profiles
- API client with async/await
- JWT storage in Keychain
- Parent Gate PIN storage (hashed) in Keychain
- Playback session flow with Mux signed playback tokens
- Usage events (`play_start`, `pause`, `resume`, `play_end`, `heartbeat`)

## Folder Layout

```text
ios/StorytimeApp/
  App/
  Models/
  Networking/
  Services/
  ViewModels/
  Views/
```

## Backend Contract

Default API base URL:

- `http://localhost:3000/api/v1`

Override with env var:

- `STORYTIME_API_BASE_URL`

## Notes

- Full Xcode GUI tools are not installed in this environment, so this commit includes complete Swift source structure but does not include a generated `.xcodeproj` bundle.
- To run on-device/simulator, create an iOS App target in Xcode and add files from `ios/StorytimeApp`.
