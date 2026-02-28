# Internal Admin Webapp Buildout (ActiveAdmin) — Streamlined Product UX

This document specifies how to evolve the existing ActiveAdmin into a **streamlined operations console** with deep analytics and support tooling.

Repo references:
- Existing ActiveAdmin resources live in `backend/app/admin/*`
- Authorization is `backend/lib/admin_authorization_adapter.rb`
- Existing analytics report page: `backend/app/admin/usage_reports.rb`

---

## 0) RBAC (Role-Based Access Control) improvements

### Current state
`AdminUser` roles: `super_admin`, `content_admin`, `finance_admin`.
Authorization logic is centralized in `AdminAuthorizationAdapter`.

### Required changes
Add roles to `AdminUser`:
- `support_admin` (can view parents/children, can view usage events, cannot edit payouts/contracts)
- `analytics_admin` (can view analytics dashboards + exports)
- `compliance_admin` (can view parental consents, deletion requests, can mark deletion request as processing/completed)

Update:
- `AdminUser` enum
- Add convenience methods (`can_manage_support?`, etc.)
- Update `AdminAuthorizationAdapter` to allow:
  - Support/analytics/compliance pages and resources appropriately
  - Finance admins should be able to manage `PayoutPeriod` and view `PublisherStatement` (currently not allowed)

---

## 1) Add missing ActiveAdmin resources for “support + analytics”

### 1.1 Users (parents) — read-only
Create `backend/app/admin/parents.rb` (or `users.rb`) as a read-only ActiveAdmin resource:
- index:
  - id, email, created_at, last consent version, #children
- show:
  - children list, deletion requests, consents
- actions:
  - NO destroy/edit by default (super_admin only if you want)

### 1.2 Child profiles — read-only with drilldown
Create `backend/app/admin/child_profiles.rb`:
- index: id, name, parent email link, created_at, #books in library
- show:
  - library (books)
  - recent watch history (computed from events/rollups)
  - “watch summary” panel: last 7/30 days minutes watched, most watched books

### 1.3 Usage events — searchable, paginated, read-only
Create `backend/app/admin/usage_events.rb`:
- index: occurred_at, event_type, child_profile, book, position_seconds, watched_seconds, playback_session_id
- filters: date range, publisher, book, child_profile_id, event_type
- export CSV (admin-only)
- show: metadata JSON pretty printed

**Performance**:
- Add `includes(:child_profile, :book)` and limit default per_page.

---

## 2) New “Analytics” section in ActiveAdmin

### 2.1 Replace table-only reports with dashboards + charts
Keep `Usage Reports` but add a new page:
- `backend/app/admin/analytics_dashboard.rb` (ActiveAdmin register_page)

Features:
- Filter bar:
  - date range
  - publisher
  - book
  - (internal only) child_profile_id
- Summary KPIs:
  - minutes watched
  - active children (unique children)
  - play starts / play ends
  - avg completion rate
- Charts:
  - minutes watched over time
  - unique children over time
  - top books table (by minutes watched)

Implementation options:
1) Minimal JS (Chart.js via CDN or vendored asset)
2) Add `chartkick` + `groupdate` gems (more Rails-native)
Pick the simplest path.

### 2.2 Deep drilldowns
Add links:
- From top books → book analytics page
- From publisher → publisher analytics page
- From child → child analytics page

Pages can be:
- ActiveAdmin pages (register_page), or
- resource show pages with custom panels

---

## 3) Improve existing Mux upload UX inside ActiveAdmin

Current view: `backend/app/views/admin/books/upload_master_video.html.erb` is a placeholder text.

Replace with a working form:
- file input
- button “Create Upload URL”
- POST to `/admin/api/v1/mux/direct_uploads` with `book_id`
- use returned `upload_url` to upload the file directly to Mux
- show progress bar
- show final status + link back to book
- show errors (invalid Mux config, network)

Also show: current `VideoAsset.processing_status` and latest webhook status if available.

---

## 4) Financial reporting enhancements

### 4.1 Publisher statements page improvements
On `PublisherStatement#show`:
- include table breakdown per book with minutes watched, gross revenue
- link to book pages

### 4.2 PayoutPeriod “Generate statements” flow
Make status transitions explicit:
- draft → calculating → ready
- ready → paid
- failed shows reason

Add “Re-run” action for super_admin/finance_admin.

---

## 5) Compliance tooling enhancements

### 5.1 DeletionRequest operational actions
On `DeletionRequest`:
- add actions:
  - “Mark processing”
  - “Mark completed”
  - “Mark failed”
This requires:
- controller actions in ActiveAdmin resource
- update model timestamps `processed_at`

### 5.2 Audit log (tie-in to `17_exports_audit_access.md`)
Log when admins view a child profile page.

---

## Acceptance criteria

- Support admin can view parents/children and usage events but cannot change payouts/contracts.
- Analytics dashboards load in < 3 seconds for typical date ranges.
- Upload page is fully functional and shows progress/errors.
- Finance admin can fully operate payout periods and view statements.
