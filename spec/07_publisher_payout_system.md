# Storytime Video Library — Publisher Payout System Spec
> **Goal:** Build the business logic layer that translates viewership data and partnership contracts into publisher payouts. This includes royalty calculation, statement generation, publisher-facing reporting, and payment processing integration via Stripe Connect.
> **Depends on:** `01_backend_rails_api.md` (PartnershipContract, UsageEvent models), `02_admin_console.md` (reporting), `11_analytics_engine.md` (aggregation).

---

## 0) Current State

What exists:
- `partnership_contracts` table with payment models (`flat_fee`, `rev_share`, `hybrid`) and `rev_share_bps` (basis points)
- `usage_events` table tracking play_start, pause, resume, play_end, heartbeat per child per book
- `UsageReportQuery` service aggregating minutes watched, play starts/ends, unique children
- Admin console with basic usage reporting and CSV export
- Publisher model with `billing_email`

What's missing:
- No royalty calculation logic connecting contracts to usage
- No payout period management (monthly cycles)
- No statement/invoice generation
- No payment processing integration
- No publisher-facing portal or reporting

---

## 1) Data Model Additions

### 1.1 PayoutPeriod
- id
- start_date (date, not null)
- end_date (date, not null)
- status enum (`open`, `calculating`, `reviewed`, `approved`, `paid`, `cancelled`)
- created_at, updated_at

Unique index: `(start_date, end_date)`

A payout period represents one billing cycle (typically monthly). Only one period should be `open` at a time.

### 1.2 PublisherStatement
- id
- payout_period_id (foreign key)
- publisher_id (foreign key)
- contract_id (foreign key, nullable — references PartnershipContract)
- total_minutes_watched (decimal, precision: 12, scale: 2)
- total_play_starts (integer)
- total_unique_children (integer)
- gross_revenue_cents (integer) — platform revenue attributed to this publisher
- royalty_cents (integer) — calculated payout amount
- adjustments_cents (integer, default: 0) — manual adjustments
- final_payout_cents (integer) — `royalty_cents + adjustments_cents`
- currency (string, default: "USD")
- status enum (`draft`, `reviewed`, `approved`, `paid`, `disputed`)
- admin_notes (text, nullable)
- stripe_transfer_id (string, nullable) — Stripe transfer reference
- paid_at (datetime, nullable)
- created_at, updated_at

Unique index: `(payout_period_id, publisher_id)`

### 1.3 StatementLineItem
- id
- publisher_statement_id (foreign key)
- book_id (foreign key)
- minutes_watched (decimal, precision: 10, scale: 2)
- play_starts (integer)
- play_ends (integer)
- unique_children (integer)
- book_royalty_cents (integer) — per-book calculated amount
- created_at

This provides granular per-book breakdown within a publisher statement.

---

## 2) Royalty Calculation Service

### 2.1 PayoutCalculationService

```ruby
class PayoutCalculationService
  def initialize(payout_period)
    @period = payout_period
  end

  def calculate_all
    # For each publisher with an active contract during this period:
    #   1. Query aggregated usage for the period
    #   2. Apply contract terms to calculate royalty
    #   3. Create/update PublisherStatement + StatementLineItems
  end
end
```

### 2.2 Calculation logic by payment model

**`flat_fee`:**
- Royalty = contract's flat fee amount (stored separately, see 2.3 below)
- Usage data is informational only
- Line items still generated for transparency

**`rev_share`:**
- Calculate platform revenue per book for the period (see 2.4)
- Royalty = `platform_revenue_cents * rev_share_bps / 10000`
- Example: 1500 bps (15%) on $100 revenue = $15.00

**`hybrid`:**
- Calculate rev_share amount as above
- Compare against `minimum_guarantee_cents` prorated for the period
- Royalty = max(rev_share_amount, prorated_minimum_guarantee)

### 2.3 Contract model addition
Add to `partnership_contracts`:
- `flat_fee_cents` (integer, nullable) — monthly flat fee for `flat_fee` payment model

### 2.4 Platform revenue attribution
For MVP, use a simple per-minute-watched revenue model:
- Define a platform-wide `REVENUE_PER_MINUTE_CENTS` config value (e.g., 2 cents per minute)
- `platform_revenue_for_book = minutes_watched * REVENUE_PER_MINUTE_CENTS`
- Store in `gross_revenue_cents` on the statement

This is intentionally simple. Replace with actual subscription revenue allocation later.

### 2.5 Edge cases
- **No active contract:** Skip publisher, log warning
- **Multiple contracts for same publisher:** Use the most recently active contract
- **Overlapping rights windows:** Deduplicate — count usage only once per book
- **Zero usage:** Still generate a statement with $0 (publisher sees they had no plays)

---

## 3) Payout Period Management

### 3.1 Period lifecycle
1. **Create period:** Admin creates a new PayoutPeriod (typically 1st–last of previous month)
2. **Calculate:** Admin triggers calculation (or it runs automatically)
3. **Review:** Admin reviews generated statements, makes adjustments
4. **Approve:** Admin approves statements for payment
5. **Pay:** System processes payments via Stripe Connect
6. **Complete:** Statements marked as paid with Stripe transfer IDs

### 3.2 Admin console — PayoutPeriods resource
Fields:
- start_date, end_date
- status

Actions:
- **Create New Period** — defaults to previous calendar month
- **Calculate Payouts** — triggers `PayoutCalculationService` (button on show page)
- **Review Statements** — links to publisher statements for this period
- **Approve All** — bulk approve all draft/reviewed statements
- **Process Payments** — triggers Stripe transfers for approved statements

### 3.3 Admin console — PublisherStatements resource
Fields:
- payout_period, publisher, contract
- total_minutes_watched, total_play_starts, total_unique_children
- gross_revenue_cents, royalty_cents, adjustments_cents, final_payout_cents
- status, admin_notes, stripe_transfer_id, paid_at

Actions:
- **View Line Items** — panel showing per-book breakdown
- **Adjust** — edit `adjustments_cents` and `admin_notes`
- **Approve** — change status to `approved`
- **Dispute** — change status to `disputed`

### 3.4 Admin console — Statement CSV export
`GET /admin/api/v1/reports/statements.csv?period_id=...`
Columns:
- publisher_name, publisher_billing_email
- book_title, minutes_watched, play_starts, unique_children
- gross_revenue, royalty, adjustments, final_payout
- currency, status

---

## 4) Stripe Connect Integration

### 4.1 Publisher onboarding
Add to `publishers` table:
- `stripe_account_id` (string, nullable) — Stripe Connect account ID

**Onboarding flow:**
1. Admin enters publisher billing details
2. Admin clicks "Connect Stripe Account" in ActiveAdmin
3. Backend creates a Stripe Connect Express account via API
4. Backend generates an Account Link (onboarding URL)
5. Admin shares URL with publisher to complete Stripe onboarding
6. Stripe webhook `account.updated` confirms account is ready

### 4.2 Payment processing
**PayoutProcessorService:**
```ruby
class PayoutProcessorService
  def process(publisher_statement)
    # 1. Validate statement is approved
    # 2. Validate publisher has stripe_account_id
    # 3. Create Stripe Transfer:
    #    - amount: final_payout_cents
    #    - currency: statement.currency
    #    - destination: publisher.stripe_account_id
    #    - transfer_group: "payout_period_#{statement.payout_period_id}"
    #    - metadata: { statement_id:, publisher_id:, period: }
    # 4. Update statement: stripe_transfer_id, paid_at, status = 'paid'
  end
end
```

### 4.3 Stripe webhooks
Add to `webhooks` routes:
`POST /webhooks/stripe`

Handle events:
- `transfer.created` — log confirmation
- `transfer.failed` — mark statement as disputed, notify admin
- `account.updated` — update publisher Stripe status

### 4.4 Gems
Add to Gemfile:
- `stripe` (~> latest)

### 4.5 Environment variables
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_CONNECT_CLIENT_ID` (for OAuth onboarding, if used)

---

## 5) Publisher Portal (Phase 2 — Scope Only)

> **Note:** Full publisher portal is phase 2. This section defines the scope for when it's built.

### 5.1 Publisher authentication
- Separate from Parent and Admin auth
- Email + password via Devise (or magic link)
- Scoped to their publisher record only

### 5.2 Publisher dashboard
- View statements for their publisher account
- View per-book usage breakdown
- Download CSV/PDF statements
- View payment history and Stripe payouts

### 5.3 Endpoints (future)
- `GET /publisher/api/v1/statements` — list their statements
- `GET /publisher/api/v1/statements/:id` — statement detail with line items
- `GET /publisher/api/v1/books` — their books with usage summaries

---

## 6) Configuration

### 6.1 New environment variables
- `REVENUE_PER_MINUTE_CENTS` (integer, default: 2)
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `PAYOUT_CURRENCY` (string, default: "USD")

### 6.2 Rails config
Add to application config or initializer:
```ruby
config.x.payout.revenue_per_minute_cents = ENV.fetch("REVENUE_PER_MINUTE_CENTS", 2).to_i
config.x.payout.currency = ENV.fetch("PAYOUT_CURRENCY", "USD")
```

---

## 7) Testing Requirements

### Model tests
- PayoutPeriod: status transitions, date validation
- PublisherStatement: uniqueness per period+publisher, cents calculations
- StatementLineItem: associations, non-negative values

### Service tests
- PayoutCalculationService:
  - Flat fee calculation
  - Rev share calculation with basis points
  - Hybrid with minimum guarantee (both cases: rev share > guarantee, guarantee > rev share)
  - Zero usage generates $0 statement
  - Skips publishers without active contracts
- PayoutProcessorService:
  - Creates Stripe transfer with correct amount
  - Handles missing Stripe account gracefully
  - Updates statement on success

### Request tests
- Stripe webhook signature verification
- Statement CSV export format

---

## 8) Deliverables for Codex (Payout System)
Implement:
- Migrations: PayoutPeriod, PublisherStatement, StatementLineItem tables
- Migration: add `flat_fee_cents` to partnership_contracts, `stripe_account_id` to publishers
- PayoutCalculationService with flat_fee, rev_share, hybrid logic
- PayoutPeriod admin resource with calculate/approve actions
- PublisherStatement admin resource with line items panel and adjustment workflow
- Statement CSV export endpoint
- Stripe Connect account creation (admin-triggered)
- PayoutProcessorService with Stripe Transfer creation
- Stripe webhook handler (transfer events + account events)
- Environment variable documentation in `.env.example`
- RSpec test suite for all services and models
