# Storytime Implementation Checklist

## Step 1: AWS Infra (from `04_aws_infra_terraform.md`)
- [x] Terraform folder structure (`envs/dev`, `envs/prod`, `modules/*`)
- [x] S3 modules for master uploads + HLS output buckets
- [x] CloudFront module with OAC + public key + key group + trusted key groups
- [x] MediaConvert service role and Rails IAM policy module
- [x] Secrets Manager module with prod-safe payload handling toggle
- [x] Required outputs mapped for Rails
- [ ] `terraform init/plan/apply` in dev (blocked: terraform CLI not installed in local environment)

## Step 2: Backend API (from `01_backend_rails_api.md`)
- [x] Rails API app scaffold (`backend/`)
- [x] PostgreSQL models/migrations created for core domain
- [x] Devise + JWT auth endpoints (`/api/v1/auth/register`, `/api/v1/auth/login`, `/api/v1/auth/logout`)
- [x] Parent/child/catalog/library/playback/usage API endpoints scaffolded
- [x] CloudFront signed cookie service and private key resolver service
- [x] MediaConvert create/poll job scaffolding with Sidekiq adapter
- [x] Admin API scaffolding for upload presign + video asset registration
- [x] `.env.example` with required env vars
- [x] RSpec policy/signing/job tests completed
- [x] **Mux migration:** Replaced MediaConvert with Mux direct upload + webhooks + signed playback
- [ ] End-to-end backend smoke test with migrated DB

## Step 3: Admin Console (from `02_admin_console.md`)
- [x] ActiveAdmin setup
- [x] CRUD pages for publisher/contracts/books/rights/video assets
- [x] Upload + transcode + retry workflows (via Mux direct upload)
- [x] Reporting + CSV export

## Step 4: iOS App (from `03_ios_app.md`)
- [x] SwiftUI app scaffold
- [x] Parent mode + child mode flows
- [x] Playback session + Mux signed token + AVPlayer playback
- [x] Usage event instrumentation

---

## Step 5: iOS Launch Readiness (from `08_ios_launch_readiness.md`)
- [ ] Create Xcode project file with all source files in groups
- [ ] Build configurations: Debug, Staging, Release with xcconfig files
- [ ] AppConfig updated to read API_BASE_URL from build config
- [ ] App icon asset catalog (1024x1024 placeholder or final)
- [ ] Launch screen storyboard
- [ ] Accent color in asset catalog
- [ ] Background audio capability and AVAudioSession setup
- [ ] ParentSettingsView (account deletion, PIN change, privacy/support links)
- [ ] Backend: DELETE /api/v1/auth/account with cascade deletion
- [ ] Info.plist with required keys (ATS, encryption flag, API URL)

## Step 6: COPPA Compliance (from `09_coppa_compliance.md`)
- [ ] Migration: add `parental_consent_at`, `consent_version` to child_profiles
- [ ] Update child creation endpoint to require `consent_given`
- [ ] iOS: ParentalConsentView with scrollable disclosures
- [ ] Remove device_model from usage event metadata (iOS)
- [ ] Backend: GET /api/v1/children/:child_id/data_summary endpoint
- [ ] Backend: DELETE /api/v1/children/:child_id/data endpoint
- [ ] DataRetentionCleanupJob (weekly Sidekiq job)
- [ ] iOS: data review and deletion controls in ParentChildrenManagementView
- [ ] Privacy policy HTML page with COPPA disclosures
- [ ] Audit UsageReportQuery — confirm no child PII in outputs
- [ ] App Store privacy label documentation

## Step 7: Player UX (from `05_ios_player_ux.md`)
- [ ] Progress bar with elapsed/remaining time display
- [ ] Drag-to-seek and tap-to-seek
- [ ] Backend: migration adding `last_position_seconds`, `last_played_at` to library_items
- [ ] Backend: PATCH position endpoint
- [ ] Backend: library endpoint includes position data
- [ ] iOS: position save on pause/heartbeat/backgrounding with debouncing
- [ ] iOS: position restore on player open (auto-seek)
- [ ] iOS: library progress indicators and "Continue Watching" row
- [ ] Loading spinner and buffering overlay
- [ ] Video ended completion screen with replay option
- [ ] Backend: add `seek` to usage event_type enum
- [ ] iOS: seek event logging
- [ ] Accessibility labels for all player controls
- [ ] Caption toggle (CC button if Mux asset has captions)
- [ ] Backend: add `has_captions` to video_assets

## Step 8: Catalog & Discovery (from `06_ios_catalog_and_discovery.md`)
- [ ] Backend: Category model + migration + seed data
- [ ] Backend: BookCategory join table
- [ ] Backend: catalog endpoint with category filter
- [ ] Backend: GET /api/v1/catalog/categories endpoint
- [ ] Backend: GET /api/v1/catalog/books/:id detail endpoint
- [ ] Backend: include duration_seconds in library response
- [ ] Admin: Category CRUD resource + book category assignment
- [ ] iOS: filter bar with age picker and category chips
- [ ] iOS: debounced auto-search replacing explicit button
- [ ] iOS: infinite scroll pagination
- [ ] iOS: BookDetailView with full book info and add-to-library
- [ ] iOS: duration badges on library covers
- [ ] iOS: empty library state with browse prompt

## Step 9: Background Jobs (from `12_background_jobs.md`)
- [ ] Updated sidekiq.yml with prioritized queues (critical, default, bulk, scheduled)
- [ ] Updated ApplicationJob with retry/discard/logging
- [ ] MuxWebhookProcessorJob (refactor from synchronous controller)
- [ ] StripeWebhookProcessorJob
- [ ] PayoutCalculationJob wrapper
- [ ] PayoutProcessingJob and BulkPayoutProcessingJob
- [ ] RightsExpirationNotifierJob
- [ ] PartitionMaintenanceJob
- [ ] config/schedule.yml with all cron definitions
- [ ] Sidekiq cron initializer
- [ ] Sidekiq Web UI at /admin/sidekiq with auth
- [ ] Dead job notification handler
- [ ] Update webhook controllers to async processing

## Step 10: Email System (from `10_email_and_notifications.md`)
- [ ] Email provider configuration (Postmark or SES)
- [ ] letter_opener gem for development
- [ ] Shared email layout with branding
- [ ] ParentMailer: welcome, password_reset, account_deleted, password_changed
- [ ] AdminMailer: video_processing_failed, rights_expiring, payouts_ready
- [ ] PublisherMailer: statement_available, payment_processed
- [ ] Devise recoverable module + password reset endpoints
- [ ] iOS: forgot password flow on LoginView
- [ ] sidekiq-cron for daily rights expiration check
- [ ] All emails wired to deliver_later

## Step 11: Analytics Engine (from `11_analytics_engine.md`)
- [ ] Migration: DailyBookMetric table
- [ ] Migration: DailyPlatformMetric table
- [ ] Migration: ChildViewingHistory table
- [ ] Migration: BookDropoffBucket table
- [ ] DailyMetricsAggregationJob with completion tracking and backfill support
- [ ] Update UsageReportQuery to read from aggregated tables
- [ ] Updated admin dashboard: platform overview, top books, engagement alerts
- [ ] Book-level analytics panel in ActiveAdmin
- [ ] Publisher-level analytics panel in ActiveAdmin
- [ ] Admin analytics API endpoints (platform, book, publisher)
- [ ] Drop-off histogram calculation
- [ ] sidekiq-cron schedule for daily aggregation (2 AM UTC)

## Step 12: Publisher Payouts (from `07_publisher_payout_system.md`)
- [ ] Migration: PayoutPeriod table
- [ ] Migration: PublisherStatement table
- [ ] Migration: StatementLineItem table
- [ ] Migration: add flat_fee_cents to partnership_contracts
- [ ] Migration: add stripe_account_id to publishers
- [ ] PayoutCalculationService (flat_fee, rev_share, hybrid logic)
- [ ] PayoutPeriod admin resource with calculate/approve actions
- [ ] PublisherStatement admin resource with line items and adjustments
- [ ] Statement CSV export endpoint
- [ ] Stripe Connect account creation (admin-triggered)
- [ ] PayoutProcessorService with Stripe Transfer creation
- [ ] Stripe webhook handler (transfer + account events)
- [ ] Publisher email notifications (statement available, payment processed)
- [ ] Updated .env.example with all new variables
