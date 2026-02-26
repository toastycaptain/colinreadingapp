# Storytime Video Library — iOS Player UX Improvements Spec
> **Goal:** Upgrade the video player from bare-minimum MVP (play/pause only) to a polished, child-friendly experience with progress tracking, scrubbing, "continue watching" persistence, and accessibility support.
> **Constraint:** Child Mode controls must remain simple and locked down — no settings, no external links, no volume control exposed to children.

---

## 0) Current State

The existing player (`ChildPlayerView` + `PlayerViewModel`) provides:
- AVPlayer with Mux HLS streaming via signed tokens
- Play/Pause toggle button
- "Back to Library" button
- Usage event logging (play_start, pause, resume, play_end, heartbeat)
- Auto-retry on token expiration (single retry)

What's missing:
- No progress bar or scrubbing
- No playback position persistence ("continue watching")
- No subtitles/captions support
- No loading/buffering indicator
- No "video ended" state with replay option

---

## 1) Progress Bar & Scrubbing

### 1.1 Visual progress bar
Add a horizontal progress bar at the bottom of the player (above the play/pause button area):
- Shows elapsed time / total duration (e.g., `2:15 / 12:30`)
- Filled portion represents current position
- Unfilled portion represents remaining
- Buffer indicator (lighter color) shows how much is buffered

### 1.2 Scrubbing (drag to seek)
- User can drag the progress bar thumb to seek
- While dragging, show a time label preview above the thumb
- On release, seek AVPlayer to the new position
- Log a new usage event type: `seek`
  - Include `from_position_seconds` and `to_position_seconds` in metadata

### 1.3 Tap to seek
- Tapping anywhere on the progress bar should seek to that position
- Same `seek` event logging as drag

### 1.4 Child Mode considerations
- Scrubbing is enabled by default but can be disabled via a parent preference (phase 2)
- Progress bar should be large enough for small fingers (minimum 44pt touch target)
- Use rounded, friendly styling consistent with child UX

---

## 2) Continue Watching (Playback Position Persistence)

### 2.1 Backend changes

**New migration — add `last_position_seconds` to `library_items`**
- `last_position_seconds` (integer, nullable, default: nil)
- `last_played_at` (datetime, nullable)

**New endpoint — update playback position**
`PATCH /api/v1/children/:child_id/library_items/:book_id/position`
- body: `position_seconds` (integer)
- Updates `last_position_seconds` and `last_played_at` on the LibraryItem
- Parent JWT required (existing auth)

**Modify existing library endpoint**
`GET /api/v1/children/:child_id/library`
- Include `last_position_seconds` and `last_played_at` in each book response

### 2.2 iOS changes

**Position saving strategy:**
- Save position to backend on these events:
  - `pause` (immediate save)
  - `play_end` (reset to nil — video completed)
  - `heartbeat` (piggyback on existing 45-second heartbeat)
  - App backgrounding (observe `UIApplication.willResignActiveNotification`)
- Use debouncing: do not save more than once per 10 seconds

**Position restoration:**
- When player opens, check `last_position_seconds` from library data
- If position exists and is > 0 and < (total_duration - 10 seconds):
  - Show a "Continue from X:XX?" prompt, or
  - Auto-seek to saved position (recommended for children — simpler UX)
- If position is within 10 seconds of the end, treat as completed and start from beginning

**Library UI indicator:**
- Books with `last_position_seconds > 0` show a small progress bar on their cover art in `ChildLibraryView`
- Books with `last_played_at` within last 7 days appear in a "Continue Watching" row at the top of the library

### 2.3 DTO changes

Update `BookDTO` to include:
- `last_position_seconds` (Int?, optional)
- `last_played_at` (String?, ISO8601, optional)

---

## 3) Loading & Buffering States

### 3.1 Initial loading
- When `preparePlayback()` is called, show a loading spinner centered on the player
- Use a child-friendly animation (e.g., bouncing book icon) rather than a generic spinner
- Hide spinner once AVPlayer reports `readyToPlay` status

### 3.2 Buffering during playback
- Observe `AVPlayerItem.isPlaybackLikelyToKeepUp` and `isPlaybackBufferEmpty`
- When buffering: show a subtle loading indicator overlay (semi-transparent, centered)
- When buffered: hide indicator and resume playback

### 3.3 Error state
- If playback fails after retry, show a friendly error screen:
  - Child-appropriate message: "Oops! This story isn't working right now."
  - "Try Again" button that calls `preparePlayback()` again
  - "Back to Library" button

---

## 4) Video Ended State

### 4.1 Completion screen
When video reaches the end:
- Show a completion overlay:
  - "The End!" or "Great job!" message
  - "Watch Again" button (seeks to beginning and plays)
  - "Back to Library" button
- Clear `last_position_seconds` (set to nil) since video is complete

### 4.2 Auto-play next (phase 2, optional)
- Not in scope for this spec
- Mark as explicit TODO for future implementation

---

## 5) Subtitle / Caption Support

### 5.1 Mux captions
- Mux supports adding subtitle tracks to assets
- If a Mux asset has embedded captions or sidecar subtitle files, AVPlayer will pick them up automatically via HLS

### 5.2 Backend changes
Add to `video_assets` table:
- `has_captions` (boolean, default: false)

Update Mux webhook handler:
- When `video.asset.ready` webhook arrives, check if asset has text tracks
- Set `has_captions` accordingly

### 5.3 iOS changes
- If `has_captions` is true, show a small "CC" button in the player controls
- Tapping CC toggles captions on/off using `AVPlayer.currentItem.select(mediaSelectionOption:)`
- Store caption preference per-child in UserDefaults (key: `captions_enabled_{child_id}`)

---

## 6) Usage Event Updates

### 6.1 New event type: `seek`
Add `seek` to the `event_type` enum in `UsageEvent` model:
- `event_type` enum: `play_start`, `pause`, `resume`, `play_end`, `heartbeat`, `seek`

### 6.2 Seek event metadata
```json
{
  "from_position_seconds": 45,
  "to_position_seconds": 120
}
```

### 6.3 iOS UsageEventLogger update
Add method:
```
logSeekEvent(childID:, bookID:, fromPosition:, toPosition:)
```

---

## 7) Accessibility

### 7.1 VoiceOver
- All player controls must have `accessibilityLabel`:
  - Play button: "Play" / "Pause" (dynamic based on state)
  - Progress bar: "Playback progress, X minutes Y seconds of Z minutes"
  - Back button: "Back to Library"
  - CC button: "Captions, currently on/off"

### 7.2 Dynamic Type
- Time labels should respect Dynamic Type settings
- Minimum font size: Body

### 7.3 Reduce Motion
- If `UIAccessibility.isReduceMotionEnabled`, skip any loading animations
- Use static indicators instead

---

## 8) Testing Requirements

### Backend tests
- Model test: LibraryItem validates `last_position_seconds >= 0` when present
- Request test: PATCH position endpoint updates correctly
- Request test: Library endpoint includes position data

### iOS tests (unit)
- PlayerViewModel: verify seek event logging
- PlayerViewModel: verify position save debouncing
- PlayerViewModel: verify position restoration logic (skip if near end)

---

## 9) Deliverables for Codex (Player UX)
Implement:
- Progress bar with elapsed/remaining time display
- Drag-to-seek and tap-to-seek on progress bar
- Continue watching: backend migration, PATCH endpoint, position save/restore in iOS
- Library progress indicators and "Continue Watching" row
- Loading spinner and buffering overlay
- Video ended completion screen with replay option
- Seek usage event type (backend enum + iOS logging)
- Accessibility labels for all player controls
- Caption toggle (if Mux asset has captions)
