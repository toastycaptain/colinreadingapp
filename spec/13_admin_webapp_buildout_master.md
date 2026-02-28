# Storytime Admin + Partner Portal Buildout (Repo-Aligned Master Guide)

This document is the **master instruction plan** for Codex to **extensively build out the admin webapp** (ActiveAdmin) and add a **publisher partner portal** (self-serve dashboards + statements) for the existing repo:

- Repo: `https://github.com/toastycaptain/colinreadingapp`
- Rails backend lives in `backend/`
- Current admin uses **ActiveAdmin** (`/admin`)
- Video pipeline uses **Mux** (Direct Upload + signed playback token flow)
- Analytics is currently based on `UsageEvent` + rollups (`DailyMetric`) + payout statements

## Critical repo observations you must respect

### 1) Current analytics math is incorrect (must fix before building more dashboards)
In iOS, `UsageEventLogger` sends `positionSeconds = current playback position` (absolute), e.g. heartbeat sends the current player position. That means **summing `position_seconds` is wrong** and will wildly overcount watch time.

Backend currently computes minutes watched by summing `usage_events.position_seconds` for `heartbeat` and `play_end` events in:
- `UsageReportQuery` (`backend/app/services/usage_report_query.rb`)
- `DailyMetricsAggregator` (`backend/app/services/daily_metrics_aggregator.rb`)
- `RoyaltyCalculator` (`backend/app/services/royalty_calculator.rb`)

**This must be corrected FIRST**, otherwise:
- Admin analytics are wrong
- Publisher statements and payouts are wrong
- Partner portal metrics become untrustworthy

### 2) Current backend already has strong foundations
The repo already includes:
- Core domain models: `Publisher`, `PartnershipContract`, `RightsWindow`, `Book`, `VideoAsset`, `PayoutPeriod`, `PublisherStatement`, `UsageEvent`, `DailyMetric`, plus compliance (`ParentalConsent`, `DeletionRequest`).
- Mux: Direct upload endpoint, webhook handling, signed playback tokens.
- ActiveAdmin resources + custom pages (Dashboard, Books, Publishers, Usage Reports, Payout Periods, etc.).
- Sidekiq + cron jobs for daily aggregation + retention purge.

This buildout should **extend** what exists (don’t rewrite).

---

## Goals

### Internal Admin (ActiveAdmin) — “Operators” view
1. Manage publishers + contracts + rights windows (existing)
2. Manage books + video assets (existing) with improved “Upload” UX
3. **Deep analytics by child account** (new)
4. Compliance operations (existing) + better auditing (new)
5. Billing/payout operations (existing) + better reporting and exports (new)

### Publisher Partner Portal — “Self-Serve” view (NEW)
1. Publisher login (separate from parents + internal admins)
2. Read-only access to:
   - Their books and rights windows
   - Their daily analytics (aggregated)
   - Their statements/payout history
   - Exports (CSV)
3. Strict privacy controls:
   - Publishers see **no child names / parent emails**
   - Only aggregated metrics + anonymized identifiers if absolutely necessary

---

## Execution order (Codex must follow)

### Phase 0 — Fix analytics correctness (REQUIRED)
Follow: `14_analytics_semantics_and_child_viewership.md`

Deliverables:
- New watch-time calculation based on deltas (not absolute positions)
- Updated aggregation jobs + payout calculators
- Tests proving correctness
- Optional backfill for existing events

### Phase 1 — Expand internal ActiveAdmin for child-level analytics
Follow: `15_activeadmin_product_ui.md`

Deliverables:
- ActiveAdmin resources for `User`, `ChildProfile`, `UsageEvent` (read-only where appropriate)
- “Child Analytics” drill-down pages
- Better dashboards: filters + charts + export
- RBAC updates in `AdminAuthorizationAdapter`

### Phase 2 — Build publisher partner portal (self-serve)
Follow: `16_publisher_partner_portal.md`

Deliverables:
- `PublisherUser` model + authentication
- Publisher-scoped analytics dashboards
- Statement views + CSV exports
- Partner admin: invite/manage users

### Phase 3 — Exports, auditing, and operational hardening
Follow: `17_exports_audit_access.md`

Deliverables:
- Export jobs and storage
- Audit logs for sensitive data access
- Rate limiting, permissions, and monitoring touches

---

## Working agreements / guardrails

### A) Don’t leak child PII to publishers
Publisher portal must not show:
- Child names
- Parent emails
- Any raw event data that could identify a specific child
- Exact timestamps at individual granularity (prefer daily aggregates)

### B) Add feature flags where risk is high
Use environment flags (or a simple `FeatureFlag` table) for:
- Enabling publisher portal in production
- Enabling child-level analytics pages for only `super_admin`

### C) Prefer incremental DB changes and keep migrations reversible
This repo is early but you still need clean migrations.

### D) Add tests for analytics correctness and authorization
At minimum:
- Unit tests for delta computation
- Unit/integration tests for payout math
- Authorization tests for:
  - admin roles
  - publisher users scoped access

---

## Definition of Done (global)

- Internal admin can:
  - drill down into a child profile and see watch history + summaries
  - see accurate watch-time analytics
  - create payout periods and produce correct statements

- Publisher partner can:
  - log in and only see their own publisher data
  - view analytics dashboards and download CSV
  - view statements/payout history

- No route leaks:
  - A publisher user cannot access `/admin`
  - A publisher user cannot access other publishers’ data

---

## Where to implement things in the repo

- Rails models: `backend/app/models/*`
- Services/queries: `backend/app/services/*`
- Jobs: `backend/app/jobs/*`
- ActiveAdmin:
  - resources: `backend/app/admin/*`
  - custom views: `backend/app/views/admin/*`
- Partner portal (new):
  - controllers: `backend/app/controllers/publisher/*`
  - views: `backend/app/views/publisher/*`
  - models: `backend/app/models/publisher_user.rb` etc
- Routes: `backend/config/routes.rb`
