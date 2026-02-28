# Publisher Partner Portal (Self-Serve) — Specs (Repo-Aligned)

Goal: provide publishers a self-serve portal to view:
- their books + rights
- aggregated analytics
- payout statements
- exports (CSV)

This must be separate from ActiveAdmin (internal only).

---

## 1) Authentication model: PublisherUser

### 1.1 Create `PublisherUser` model
- `belongs_to :publisher`
- Devise modules:
  - database_authenticatable, recoverable, rememberable, validatable
- Roles:
  - `owner` (manage other publisher users, view everything)
  - `finance` (view statements, billing)
  - `analytics` (view dashboards)
  - `read_only` (view dashboards only)

### 1.2 Routes
Add to `backend/config/routes.rb`:

- `devise_for :publisher_users, path: "publisher", controllers: { sessions: ..., passwords: ... }`
- namespace `publisher`:
  - `root to: "dashboard#show"`
  - `resources :books, only: [:index, :show]`
  - `resource :analytics, only: [:show]` (or multiple pages)
  - `resources :statements, only: [:index, :show]`
  - `resources :exports, only: [:index, :create, :show]`
  - `resources :team_members, only: [:index, :create, :destroy]` (owner only)

### 1.3 Layout
Create `backend/app/views/layouts/publisher.html.erb` with:
- nav: Dashboard, Books, Analytics, Statements, Exports, Team (if owner)
- account dropdown: change password, logout

---

## 2) Publisher scoping (NO data leakage)

In all publisher controllers:
- `before_action :authenticate_publisher_user!`
- `current_publisher = current_publisher_user.publisher`

All queries must scope:
- `Book.where(publisher_id: current_publisher.id)`
- `RightsWindow.where(publisher_id: current_publisher.id)`
- `DailyMetric.where(publisher_id: current_publisher.id)`
- `PublisherStatement.where(publisher_id: current_publisher.id)`

Never show:
- child_profile.name
- parent user email
- raw usage events

---

## 3) Pages

### 3.1 Dashboard
KPIs (date range default: last 30 days):
- minutes watched
- unique children
- play starts, play ends
- avg completion rate
- top 10 books by minutes watched

Use `DailyMetric` for most of this (and today’s partial using raw events if desired).

### 3.2 Books index
Show:
- title, author, status, category
- rights status (active? end_at)
- video asset status (ready/processing/failed)
- link to book detail

### 3.3 Book detail
Show:
- metadata
- rights windows
- analytics chart (minutes watched over time)
- completion rate over time
- export CSV for this book

### 3.4 Analytics page
Filters:
- date range
- book

Charts:
- minutes watched over time
- unique children over time
- completion rate over time

Tables:
- daily breakdown table
- top books table

### 3.5 Statements
Show list of payout periods statements:
- period, status, minutes watched, payout amount
Statement detail:
- breakdown by book (already stored in `PublisherStatement.breakdown`)
- show Stripe transfer id (if present)

### 3.6 Exports
Allow “Create export”:
- type: analytics_daily, statement_breakdown
- date range
- optional book id
Create a CSV file and store it for download (see `17_exports_audit_access.md`).

---

## 4) Authorization inside the portal

- owner:
  - can manage team members
  - can see billing and statements
- finance:
  - statements + exports (finance)
- analytics:
  - dashboards + exports (analytics)
- read_only:
  - dashboards only

Implement:
- `PublisherPortalAuthorization` helper methods or use Pundit.
Keep it simple and explicit.

---

## 5) Security

- Enforce secure cookies + SameSite
- Optional: add 2FA (phase 2)
- Brute-force protection (rack-attack) recommended
- All exports must be scoped and short-lived URLs

---

## Acceptance criteria

- Publisher user logs in and can only see their publisher’s data.
- Publisher sees analytics + statements without any child PII.
- Exports can be generated/downloaded.
