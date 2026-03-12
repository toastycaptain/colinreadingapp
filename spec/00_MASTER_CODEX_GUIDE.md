# Storytime Video Library — MASTER GUIDE for Codex
> **Purpose:** This file tells Codex (and any developer) **how to use the other Markdown specs** to build the complete system.
> The original MVP (Steps 1-4) is **complete**. Steps 5-12 define the next phase of features.
> **Note:** The video pipeline has been migrated from AWS MediaConvert to **Mux**. References to CloudFront signed cookies, S3 presigned uploads, and MediaConvert in specs 01-04 are superseded by the Mux integration now in place.

---

## 0) Files in this spec set (read order)

### Original MVP specs (Steps 1-4 — COMPLETE)
1. `01_backend_rails_api.md` — Rails API backend: data model, endpoints, auth, signing, jobs
2. `02_admin_console.md` — Rails Admin console: ActiveAdmin pages + workflows
3. `04_aws_infra_terraform.md` — AWS infra as code: S3, CloudFront OAC, Key Group, IAM, Secrets
4. `03_ios_app.md` — iOS app: SwiftUI screens, networking, playback UX

> **Important:** Specs 01-04 reference the original AWS MediaConvert architecture. The implementation has migrated to **Mux** for video processing, signed playback tokens (not CloudFront cookies), and direct upload. The code is authoritative over these specs for video pipeline details.

### Phase 2 specs (Steps 5-12 — TO BE IMPLEMENTED)
Codex should process these **in the recommended order below**:

5. `08_ios_launch_readiness.md` — Xcode project, build configs, App Store preparation
6. `09_coppa_compliance.md` — COPPA compliance, parental consent, privacy policy, data retention
7. `05_ios_player_ux.md` — Player improvements: progress bar, continue watching, captions
8. `06_ios_catalog_and_discovery.md` — Catalog filtering, pagination, book details, categories
9. `12_background_jobs.md` — Sidekiq job infrastructure, async webhook processing, cron scheduling
10. `10_email_and_notifications.md` — Transactional emails, password reset, admin notifications
11. `11_analytics_engine.md` — Aggregation tables, daily metrics jobs, advanced reporting
12. `07_publisher_payout_system.md` — Royalty calculation, statements, Stripe Connect payouts

**Cross-dependencies:** Some specs reference each other. Key dependencies:
- `12_background_jobs.md` provides the job infrastructure used by specs 07, 09, 10, 11
- `09_coppa_compliance.md` must be implemented before App Store submission (spec 08)
- `11_analytics_engine.md` produces the aggregated data consumed by `07_publisher_payout_system.md`

---

## 1) Output expectation (what Codex should produce)

### Completed (MVP)
- ✅ Rails 8.1 API backend with PostgreSQL, Devise + JWT, Mux integration
- ✅ ActiveAdmin console with CRUD, upload workflow, reporting
- ✅ Terraform infrastructure modules (legacy — video pipeline now uses Mux)
- ✅ SwiftUI iOS app with Parent/Child modes, AVPlayer + Mux HLS, usage events

### Phase 2 deliverables

**A) Backend additions**
- Background job infrastructure (Sidekiq jobs, cron scheduling)
- Email delivery system (Action Mailer + provider)
- Analytics aggregation engine (daily metrics, completion tracking)
- Publisher payout system (royalty calculation, Stripe Connect)
- COPPA compliance (consent tracking, data retention, deletion endpoints)
- New API endpoints (book detail, categories, position persistence, data controls)

**B) iOS additions**
- Xcode project file with build configurations (Dev/Staging/Release)
- Player UX improvements (progress bar, continue watching, captions)
- Catalog enhancements (filters, pagination, book detail view)
- COPPA consent flow and parental data controls
- Settings view with account deletion, PIN change, privacy links
- Forgot password flow

**C) Admin additions**
- Category CRUD and book categorization
- Payout period management and statement workflows
- Enhanced analytics dashboards (completion rates, drop-off, trends)
- Sidekiq Web UI for job monitoring

---

## 2) Recommended build sequence (Phase 2)

### Step 5 — iOS Launch Readiness
Using `08_ios_launch_readiness.md`:
1. Create Xcode project with all existing source files
2. Configure build environments (Debug, Staging, Release)
3. Add app icons, launch screen, and accent color
4. Add Settings view with account deletion
5. Add backend DELETE /api/v1/auth/account endpoint

**Deliverable:** App can be built and run from Xcode with environment-specific API URLs.

### Step 6 — COPPA Compliance
Using `09_coppa_compliance.md`:
1. Add parental consent flow to child creation
2. Implement privacy policy page
3. Add data review and deletion endpoints
4. Remove device_model from usage event metadata
5. Add DataRetentionCleanupJob

**Deliverable:** App meets COPPA requirements for US launch. Privacy policy accessible from app and App Store.

### Step 7 — Player UX
Using `05_ios_player_ux.md`:
1. Add progress bar with scrubbing
2. Implement continue watching (position persistence)
3. Add loading/buffering states
4. Add video completion screen
5. Add seek event tracking

**Deliverable:** Player has progress bar, remembers position, shows loading/completion states.

### Step 8 — Catalog & Discovery
Using `06_ios_catalog_and_discovery.md`:
1. Add Category model and seed data
2. Add filter bar to catalog (age, categories)
3. Implement infinite scroll pagination
4. Add BookDetailView
5. Add duration badges to library

**Deliverable:** Parents can browse, filter, and discover books with rich detail views.

### Step 9 — Background Jobs
Using `12_background_jobs.md`:
1. Set up prioritized queues
2. Refactor webhook processing to async
3. Add sidekiq-cron for scheduled jobs
4. Mount Sidekiq Web UI
5. Add job monitoring and error handling

**Deliverable:** All async processing runs via Sidekiq. Webhook processing is non-blocking. Recurring jobs are scheduled.

### Step 10 — Email System
Using `10_email_and_notifications.md`:
1. Configure email delivery (Postmark or SES)
2. Implement ParentMailer (welcome, password reset, account deletion)
3. Implement AdminMailer (video failures, rights expiration)
4. Add password reset flow (backend + iOS)
5. Add scheduled rights expiration notifications

**Deliverable:** Transactional emails work. Parents can reset passwords. Admins get notified of issues.

### Step 11 — Analytics Engine
Using `11_analytics_engine.md`:
1. Create aggregation tables (DailyBookMetric, DailyPlatformMetric, etc.)
2. Implement DailyMetricsAggregationJob
3. Update admin dashboard with pre-aggregated metrics
4. Add book-level and publisher-level analytics panels
5. Add drop-off analysis

**Deliverable:** Admin dashboard shows rich analytics from pre-aggregated data. Reports are fast.

### Step 12 — Publisher Payouts
Using `07_publisher_payout_system.md`:
1. Create payout tables (PayoutPeriod, PublisherStatement, StatementLineItem)
2. Implement PayoutCalculationService
3. Add payout management to admin console
4. Integrate Stripe Connect
5. Add publisher email notifications

**Deliverable:** Admin can calculate, review, approve, and process publisher payouts via Stripe.

---

## 3) Environment variables and config contract

### Existing env vars (from MVP)
- `DATABASE_URL`
- `REDIS_URL`
- `JWT_SECRET`
- `MUX_TOKEN_ID`, `MUX_TOKEN_SECRET`
- `MUX_SIGNING_KEY_ID`, `MUX_SIGNING_KEY_PRIVATE_KEY`
- `MUX_WEBHOOK_SIGNING_SECRET`
- `CORS_ALLOWED_ORIGINS`

### New env vars (Phase 2)
- `MAIL_FROM_ADDRESS` — sender address for transactional emails
- `POSTMARK_API_TOKEN` — email delivery provider (or equivalent)
- `STRIPE_SECRET_KEY` — Stripe API key for payouts
- `STRIPE_WEBHOOK_SECRET` — Stripe webhook signature verification
- `REVENUE_PER_MINUTE_CENTS` — platform revenue attribution rate
- `PAYOUT_CURRENCY` — default payout currency (default: USD)

Codex must update `.env.example` with all new variables.

---

## 4) Definition of Done (DoD) — Phase 2

### Launch readiness
1. App builds and runs from Xcode for all three configurations
2. Account deletion works end-to-end
3. Privacy policy is accessible from app settings
4. COPPA consent flow works during child creation

### Player & catalog
5. Player shows progress bar with scrubbing
6. "Continue watching" resumes from saved position
7. Catalog supports age and category filters
8. Infinite scroll pagination works
9. Book detail view shows full metadata

### Backend infrastructure
10. All webhook processing runs via Sidekiq (not synchronous)
11. Daily metrics aggregation job runs on schedule
12. Emails delivered for: welcome, password reset, video failure, rights expiration
13. Data retention cleanup job purges old records per COPPA policy

### Publisher payouts
14. PayoutCalculationService correctly calculates royalties for all three payment models
15. Admin can create period → calculate → review → approve → pay
16. Stripe Connect transfers succeed for approved statements

---

## 5) Implementation guidance for Codex

When implementing Phase 2 specs:
1. **Read the spec's "Current State" section** to understand what already exists.
2. **Check for cross-references** to other specs before starting (some features depend on others).
3. Implement one vertical slice at a time: **migration → model → service → controller → test**.
4. Keep existing API contracts stable — new endpoints only, do not break existing ones.
5. All background jobs must be **idempotent** (safe to retry).
6. All new endpoints require **RSpec request tests**.
7. COPPA requirements take precedence over feature convenience.

---

## 6) Where each file is authoritative

### MVP specs (01-04)
- Data model + endpoints + signing logic: `01_backend_rails_api.md`
- Admin workflows + UI actions: `02_admin_console.md`
- AWS resources + policies + outputs: `04_aws_infra_terraform.md`
- iOS UI restrictions + playback flow: `03_ios_app.md`

### Phase 2 specs (05-12)
- Player UX + continue watching: `05_ios_player_ux.md`
- Catalog filters + pagination + book detail: `06_ios_catalog_and_discovery.md`
- Payout logic + Stripe Connect: `07_publisher_payout_system.md`
- Xcode project + App Store prep: `08_ios_launch_readiness.md`
- COPPA compliance + privacy: `09_coppa_compliance.md`
- Email system + notifications: `10_email_and_notifications.md`
- Analytics aggregation + dashboards: `11_analytics_engine.md`
- Background jobs + cron scheduling: `12_background_jobs.md`

If there is a conflict between specs, resolve it by:
1. Prioritizing **COPPA/security constraints** (always)
2. Prioritizing **backend API contract** (endpoint shapes)
3. Prioritizing **the more recently numbered spec** (Phase 2 specs override MVP specs where applicable)

---

## 7) File links (for humans)
This master file accompanies:
- `01_backend_rails_api.md`
- `02_admin_console.md`
- `03_ios_app.md`
- `04_aws_infra_terraform.md`
- `05_ios_player_ux.md`
- `06_ios_catalog_and_discovery.md`
- `07_publisher_payout_system.md`
- `08_ios_launch_readiness.md`
- `09_coppa_compliance.md`
- `10_email_and_notifications.md`
- `11_analytics_engine.md`
- `12_background_jobs.md`
