# Fix Analytics Semantics + Enable Child-Level Viewership (Repo-Aligned)

This spec fixes the **watch-time math bug** in the repo and establishes a data model that supports:
- Accurate minutes watched
- Child-level analytics drilldown
- Publisher payouts that are correct

## Problem statement (current repo behavior)

### Client behavior (iOS)
`UsageEventLogger` posts `positionSeconds` as the **current playback position**.
Heartbeats send the current position every `AppConfig.heartbeatIntervalSeconds`.

So these values are **absolute**, not incremental.

### Server behavior (Rails)
Current code incorrectly interprets those numbers as incremental time and does:

`minutes_watched = SUM(position_seconds) / 60`

This occurs in:
- `UsageReportQuery` (`backend/app/services/usage_report_query.rb`)
- `DailyMetricsAggregator` (`backend/app/services/daily_metrics_aggregator.rb`)
- `RoyaltyCalculator` (`backend/app/services/royalty_calculator.rb`)

This massively overcounts.

---

## Correct approach: store *watch deltas* and use them everywhere

### Data principles
1. Keep `position_seconds` = absolute playback position
2. Add `watched_seconds` = incremental watch-time to use for aggregation
3. Tie events to a `playback_session_id` so deltas can be computed reliably per session
4. Ensure idempotency: prevent double-logging from retries

---

## Step 1 — DB migrations

### 1.1 Add watched_seconds + playback_session_id + client_event_id to usage_events
Create a migration:

- Add columns:
  - `usage_events.playback_session_id :bigint, null: true`
  - `usage_events.watched_seconds :integer, null: true`
  - `usage_events.client_event_id :string, null: true` (UUID from client)
- Indexes:
  - index `playback_session_id`
  - unique partial index on `[client_event_id]` where not null (or unique index if always present)
- Foreign key:
  - `usage_events.playback_session_id -> playback_sessions.id` (optional FK)

Notes:
- Keep old data working: allow nulls initially.

### 1.2 Update playback_sessions schema (optional)
Currently `playback_sessions` includes `cloudfront_policy` (legacy).
Keep it for now; optional cleanup later.

---

## Step 2 — API contract updates (backwards compatible)

### 2.1 Playback session response should include playback_session_id
In `Api::V1::PlaybackSessionsController#create`:
- currently creates `PlaybackSession.create!(...)` but does not return id.
- Update to:
  - `session = PlaybackSession.create!(...)`
  - response includes `playback_session_id: session.id`

### 2.2 Usage events endpoint accepts new fields
In `Api::V1::UsageEventsController#create`:
- Accept (optional):
  - `playback_session_id`
  - `watched_seconds`
  - `client_event_id`
- Store them on `UsageEvent`.

### 2.3 Server-side idempotency
If `client_event_id` is present:
- upsert-or-ignore duplicates:
  - Find by `client_event_id` and return existing, OR
  - Use DB unique index and rescue `RecordNotUnique` to return 200/201 safely.

---

## Step 3 — iOS instrumentation update (recommended)

### 3.1 Generate client_event_id
Generate a UUID per event (String).

### 3.2 Track watched_seconds on client
Maintain a simple tracker per playback session:
- lastSentPositionSeconds
- lastSentAt
- On heartbeat:
  - compute `delta = max(0, currentPosition - lastSentPositionSeconds)`
  - clamp delta to a reasonable ceiling (e.g. `<= heartbeatIntervalSeconds + 5`)
  - send `watched_seconds = delta`
- On play_end:
  - compute delta from lastSentPositionSeconds to end position, same clamp
- On pause/resume/play_start:
  - send watched_seconds = nil or 0 (not counted)

Also include:
- `playback_session_id` returned by backend

### 3.3 Backwards compatibility
If iOS is not yet updated, backend must be able to compute deltas server-side (next step).

---

## Step 4 — Server-side delta computation fallback

When `watched_seconds` is null, compute it in queries using a window function style logic.

### 4.1 Define “session key” for fallback
Preferred:
- `playback_session_id` if present

Fallback when missing:
- derive a pseudo-session by child+book and time gaps:
  - partition by (child_profile_id, book_id)
  - order by occurred_at
  - start a new session if gap > 10 minutes or event_type is play_start

### 4.2 Computation rule
For heartbeat and play_end events:
- delta = position_seconds - previous_position_seconds (within session)
- clamp:
  - if delta < 0 => 0 (seek backwards)
  - if delta > 300 => 0 (seek forward / stale)
For all other events => 0

### 4.3 Where to implement
Implement a reusable service that returns an ActiveRecord relation (or SQL fragment) that exposes `computed_watched_seconds`.

Suggested:
- `backend/app/services/watched_seconds_sql.rb` (returns SQL string)
or
- a DB view/materialized view (later optimization)

---

## Step 5 — Update analytics + payouts to use watched_seconds

### 5.1 UsageReportQuery
Replace SUM(position_seconds) with SUM(watched_seconds OR computed fallback).

### 5.2 DailyMetricsAggregator
Replace minutes aggregation logic accordingly.

### 5.3 RoyaltyCalculator + publisher statements
Replace watched_seconds calculation accordingly.

### 5.4 Tests (required)
Add RSpec tests proving:
- 0→30→60 heartbeats yields 60 seconds total, not 90
- seek backward does not create negative watch time
- seek forward clamp prevents spikes
- duplicate `client_event_id` does not double count

---

## Step 6 — New child-level analytics tables (optional but recommended for speed)

If you expect high event volume, add rollups:

### 6.1 child_daily_metrics
Columns:
- metric_date
- child_profile_id
- minutes_watched
- play_starts
- play_ends
- unique_books (optional)
Unique index on (metric_date, child_profile_id)

### 6.2 child_book_daily_metrics
Columns:
- metric_date
- child_profile_id
- book_id
- minutes_watched
- play_starts
- play_ends
- completion_rate_avg
Unique index on (metric_date, child_profile_id, book_id)

Add a nightly Sidekiq cron job similar to `DailyMetricsAggregationJob`.

---

## Acceptance criteria

1. Running usage reports in admin shows reasonable totals.
2. Daily metrics rollup matches expected deltas.
3. Royalty payouts are computed from delta-based minutes watched.
4. Child-level analytics can be computed without timing out.
