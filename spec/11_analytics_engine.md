# Storytime Video Library — Analytics Engine Spec
> **Goal:** Upgrade the raw usage event tracking into a proper analytics engine with pre-aggregated metrics, completion rates, engagement scoring, and dashboard-ready data. This feeds the admin dashboard, publisher reporting, and future recommendation features.
> **Depends on:** `01_backend_rails_api.md` (UsageEvent model), `07_publisher_payout_system.md` (payout calculations consume aggregated data).

---

## 0) Current State

What exists:
- `usage_events` table with 5 event types (play_start, pause, resume, play_end, heartbeat)
- Events include child_profile_id, book_id, position_seconds, occurred_at, metadata (jsonb)
- `UsageReportQuery` service aggregating on-the-fly: minutes_watched, play_starts, play_ends, unique_children
- Admin usage reports page with date/publisher/book filters + CSV export
- 45-second heartbeat from iOS during playback

What's missing:
- No pre-aggregated summary tables (queries hit raw events table every time)
- No completion rate tracking
- No engagement metrics (drop-off points, repeat views)
- No per-child viewing history or trends
- No data partitioning strategy for scale

---

## 1) Aggregation Tables

### 1.1 DailyBookMetric
Pre-aggregated daily metrics per book:
- id
- book_id (foreign key)
- publisher_id (foreign key, denormalized for fast queries)
- metric_date (date, not null)
- total_play_starts (integer, default: 0)
- total_play_ends (integer, default: 0)
- total_minutes_watched (decimal, precision: 10, scale: 2, default: 0)
- unique_children (integer, default: 0)
- completion_count (integer, default: 0) — plays that reached >= 90% of duration
- average_watch_percentage (decimal, precision: 5, scale: 2, nullable)
- total_sessions (integer, default: 0)
- created_at, updated_at

Unique index: `(book_id, metric_date)`
Index: `(publisher_id, metric_date)`
Index: `(metric_date)`

### 1.2 DailyPlatformMetric
Platform-wide daily summary:
- id
- metric_date (date, unique, not null)
- total_play_starts (integer, default: 0)
- total_minutes_watched (decimal, precision: 12, scale: 2, default: 0)
- unique_children (integer, default: 0)
- unique_parents (integer, default: 0)
- active_books (integer, default: 0) — books with at least 1 play
- new_registrations (integer, default: 0)
- created_at, updated_at

Unique index: `(metric_date)`

### 1.3 ChildViewingHistory
Per-child per-book viewing record:
- id
- child_profile_id (foreign key)
- book_id (foreign key)
- total_views (integer, default: 0)
- total_minutes_watched (decimal, precision: 8, scale: 2, default: 0)
- completed_count (integer, default: 0)
- last_watched_at (datetime)
- highest_position_seconds (integer, default: 0)
- created_at, updated_at

Unique index: `(child_profile_id, book_id)`

> **COPPA note:** This table contains per-child data. It must be included in the `DataRetentionCleanupJob` and data deletion endpoints per `09_coppa_compliance.md`. It must **never** be exposed in publisher reports.

---

## 2) Aggregation Jobs

### 2.1 DailyMetricsAggregationJob
**Schedule:** Runs daily at 2:00 AM UTC (after midnight in all US timezones)
**Logic:**
1. Determine target date (yesterday by default, or accept date parameter for backfills)
2. Query `usage_events` for the target date
3. Calculate per-book metrics:
   - Count `play_start` events → `total_play_starts`
   - Count `play_end` events → `total_play_ends`
   - Sum minutes from heartbeat/play_end positions → `total_minutes_watched`
   - Count distinct child_profile_ids → `unique_children`
   - Calculate completions (see 2.2)
   - Count distinct sessions (group by child + book + play_start within 1 hour)
4. Upsert into `daily_book_metrics` (update if exists for idempotency)
5. Calculate platform-wide metrics and upsert into `daily_platform_metrics`
6. Update `child_viewing_histories` for all child+book combinations with activity

### 2.2 Completion calculation
A "completion" is a viewing session where the child watched >= 90% of the book's duration:
1. Find the book's `duration_seconds` from `video_assets`
2. For each play session (play_start to play_end or last heartbeat):
   - Calculate max position reached
   - If `max_position >= duration_seconds * 0.9`, count as complete
3. Increment `completion_count` on DailyBookMetric and ChildViewingHistory

### 2.3 Minutes watched calculation
Use the heartbeat/play_end events rather than naive subtraction:
1. For each play session:
   - Sum the intervals between consecutive heartbeats (max 45 seconds each)
   - Add the interval from last heartbeat to play_end (if exists)
2. This prevents overcounting from abandoned sessions (no play_end but heartbeats stopped)

### 2.4 Backfill support
The aggregation job should accept an optional `date` parameter:
```ruby
DailyMetricsAggregationJob.perform_async("2026-02-25")
```
This allows re-running for historical dates if the calculation logic changes.

---

## 3) Updated Reporting

### 3.1 Replace UsageReportQuery
Update `UsageReportQuery` to read from `daily_book_metrics` instead of raw `usage_events`:
- Much faster queries (pre-aggregated rows instead of scanning millions of events)
- Same interface: accepts date range, publisher_id, book_id filters
- Returns same fields plus new ones: completion_count, average_watch_percentage

### 3.2 New admin dashboard metrics
Update ActiveAdmin dashboard (`app/admin/dashboard.rb`) to show:

**Platform overview cards (from DailyPlatformMetric):**
- Today's minutes watched
- Today's unique children
- 7-day trend (sparkline or +/- percentage)
- Total active books

**Top performing books (from DailyBookMetric):**
- Top 5 books by minutes watched (last 7 days)
- Top 5 books by completion rate
- Table with: title, minutes, completions, unique children

**Engagement alerts:**
- Books with 0 plays in last 30 days
- Books with completion rate below 30%

### 3.3 Book-level analytics (admin)
On the Book show page in ActiveAdmin, add an analytics panel:
- Total views (all time)
- Total minutes watched (all time)
- Completion rate (all time)
- Unique children (all time)
- 30-day chart: daily minutes watched (bar chart or line)

### 3.4 Publisher-level analytics (admin)
On the Publisher show page in ActiveAdmin, add:
- Total minutes watched across all books (all time and last 30 days)
- Total completions across all books
- Top 5 books by engagement
- Revenue attribution (if payout system from `07_publisher_payout_system.md` is implemented)

---

## 4) Engagement Metrics (Advanced)

### 4.1 Drop-off analysis
Track where children typically stop watching:

**New table: BookDropoffBucket**
- id
- book_id (foreign key)
- bucket_percent (integer, 0-100 in increments of 10: 0, 10, 20, ... 100)
- session_count (integer, default: 0) — number of sessions that ended in this bucket
- updated_at

Unique index: `(book_id, bucket_percent)`

**Calculation (in DailyMetricsAggregationJob):**
- For each play session, determine the final position as a percentage of total duration
- Increment the corresponding 10% bucket
- Example: session ended at 35% → increment bucket_percent=30

**Admin display:**
- Show as a histogram on the Book analytics panel
- Useful for identifying books that lose children's attention at specific points

### 4.2 Repeat view rate
Track from `ChildViewingHistory`:
- Books with `total_views > 1` indicate repeat interest
- Calculate across all children: `avg(total_views)` per book
- Surface in admin: "Average views per child" metric

### 4.3 Session duration distribution
For each book, track how long typical sessions last:
- Under 2 minutes (likely abandoned)
- 2-5 minutes
- 5-10 minutes
- Full video
- Surface as percentages in admin analytics

---

## 5) Performance & Scaling

### 5.1 Usage events table partitioning
As usage_events grows, partition by `occurred_at`:

**Migration: partition usage_events by month**
- Convert `usage_events` to a partitioned table (range partitioning on `occurred_at`)
- Create partitions for each month
- Add a job to auto-create future partitions monthly

**Benefits:**
- Faster queries when filtering by date range
- Old partitions can be archived or dropped without affecting recent data
- Aggregation jobs only scan the relevant partition

### 5.2 Indexes on usage_events
Ensure these indexes exist (some may already):
- `(child_profile_id, book_id, occurred_at)`
- `(book_id, occurred_at)`
- `(event_type, occurred_at)`

### 5.3 Query timeouts
Set statement timeout for analytics queries:
```ruby
ActiveRecord::Base.connection.execute("SET LOCAL statement_timeout = '30s'")
```
Prevent runaway queries from blocking the database.

---

## 6) API Endpoints for Analytics

### 6.1 Admin analytics endpoints
These endpoints power the admin dashboard charts:

`GET /admin/api/v1/analytics/platform?start=...&end=...`
- Returns daily platform metrics for the date range
- Used for dashboard charts

`GET /admin/api/v1/analytics/books/:id?start=...&end=...`
- Returns daily metrics for a specific book
- Used for book analytics panel

`GET /admin/api/v1/analytics/publishers/:id?start=...&end=...`
- Returns aggregate metrics for a publisher's books
- Used for publisher analytics panel

### 6.2 Response format
```json
{
  "data": [
    {
      "date": "2026-02-25",
      "play_starts": 45,
      "minutes_watched": 234.5,
      "unique_children": 28,
      "completions": 12,
      "completion_rate": 0.267
    }
  ],
  "summary": {
    "total_play_starts": 1250,
    "total_minutes_watched": 5678.3,
    "total_unique_children": 342,
    "total_completions": 890,
    "overall_completion_rate": 0.712
  }
}
```

---

## 7) Testing Requirements

### Model tests
- DailyBookMetric: uniqueness on book_id + metric_date
- DailyPlatformMetric: uniqueness on metric_date
- ChildViewingHistory: uniqueness on child + book, COPPA deletion cascade

### Job tests
- DailyMetricsAggregationJob:
  - Correctly counts play starts, play ends, unique children
  - Correctly calculates minutes from heartbeats
  - Correctly identifies completions (>= 90% of duration)
  - Idempotent (running twice for same date doesn't double-count)
  - Backfill mode works with explicit date parameter
- BookDropoffBucket: correct bucket assignment

### Performance tests
- Verify aggregation queries perform within 30 seconds on realistic data volumes
- Verify admin dashboard loads within 2 seconds using pre-aggregated data

---

## 8) Deliverables for Codex (Analytics Engine)
Implement:
- Migrations: DailyBookMetric, DailyPlatformMetric, ChildViewingHistory, BookDropoffBucket
- DailyMetricsAggregationJob with completion tracking, minutes calculation, backfill support
- Update UsageReportQuery to read from aggregated tables
- Updated admin dashboard with platform overview and top books
- Book-level analytics panel in ActiveAdmin
- Publisher-level analytics panel in ActiveAdmin
- Admin analytics API endpoints (platform, book, publisher)
- BookDropoffBucket histogram calculation
- Usage events index optimization
- sidekiq-cron schedule for daily aggregation at 2 AM UTC
- RSpec tests for aggregation logic (especially completion and idempotency)
