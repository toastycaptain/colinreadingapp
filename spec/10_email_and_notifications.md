# Storytime Video Library — Email & Notifications Spec
> **Goal:** Implement a transactional email system for account lifecycle events, admin notifications, and publisher communications. No marketing emails in scope. No push notifications to children.
> **Constraint:** COPPA compliance — no direct communications to children. All emails go to parent or admin accounts only.

---

## 0) Current State

What exists:
- Devise installed with default mailer views (but no mail delivery configured)
- User model with email field
- AdminUser model with email field
- Publisher model with billing_email field
- No email delivery service configured
- No custom email templates

---

## 1) Email Delivery Configuration

### 1.1 Service selection
Use a transactional email service. Recommended options:

**Option A (recommended): Postmark**
- High deliverability
- Simple API
- Gem: `postmark-rails`

**Option B: Amazon SES**
- Already in AWS ecosystem
- Gem: `aws-sdk-ses` or `aws-sdk-sesv2`

**Option C: SendGrid**
- Widely used
- Gem: `sendgrid-ruby`

### 1.2 Rails configuration
Configure Action Mailer in `config/environments/production.rb`:
```ruby
config.action_mailer.delivery_method = :postmark  # or :ses, :sendgrid
config.action_mailer.default_url_options = { host: "storytime.com" }
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = false
config.action_mailer.perform_caching = false
```

For development, use `letter_opener` gem to preview emails in browser:
```ruby
# config/environments/development.rb
config.action_mailer.delivery_method = :letter_opener
```

### 1.3 Environment variables
- `MAIL_FROM_ADDRESS` (default: `noreply@storytime.com`)
- `MAIL_SUPPORT_ADDRESS` (default: `support@storytime.com`)
- `POSTMARK_API_TOKEN` (or equivalent for chosen service)

### 1.4 Gems to add
```ruby
gem "postmark-rails"       # or chosen provider
gem "letter_opener", group: :development
gem "premailer-rails"      # inline CSS for email compatibility
```

---

## 2) Parent Account Emails

### 2.1 Welcome email
**Trigger:** After successful registration (`POST /api/v1/auth/register`)
**Recipient:** Parent email
**Subject:** "Welcome to Storytime!"
**Content:**
- Greeting with name (or email)
- Brief explanation of how to get started (create child profile, browse catalog)
- Link to privacy policy
- Support contact

**Delivery:** Asynchronous (Sidekiq job)

### 2.2 Password reset
**Trigger:** Parent requests password reset
**Recipient:** Parent email
**Subject:** "Reset your Storytime password"
**Content:**
- Password reset link (Devise token-based)
- Link expires in 2 hours
- Warning if they didn't request this

**Implementation:**
- Configure Devise `:recoverable` module on User model
- Add password reset endpoints:
  - `POST /api/v1/auth/password/reset` — sends reset email
  - `PUT /api/v1/auth/password` — updates password with token
- iOS: Add "Forgot Password?" link on LoginView
- Password reset form can be web-based (simple Rails view) or deep-link back to app

### 2.3 Account deletion confirmation
**Trigger:** After account deletion (`DELETE /api/v1/auth/account`)
**Recipient:** Parent email (sent before record deletion)
**Subject:** "Your Storytime account has been deleted"
**Content:**
- Confirmation that account and all child data has been removed
- Note that data cannot be recovered
- Support contact if this was a mistake

**Delivery:** Send synchronously (before deleting the user record) or queue with email address captured before deletion

### 2.4 Password changed notification
**Trigger:** After password is changed (reset or manual update)
**Recipient:** Parent email
**Subject:** "Your Storytime password was changed"
**Content:**
- Notification that password was changed
- "If this wasn't you" instructions (contact support)
- Timestamp of change

---

## 3) Admin Notification Emails

### 3.1 Video processing failure
**Trigger:** Mux webhook `video.asset.errored`
**Recipient:** All admin users with `content_admin` or `super_admin` role
**Subject:** "Video processing failed: [Book Title]"
**Content:**
- Book title and ID
- Error message from Mux
- Link to video asset in admin console
- Suggested action (retry upload)

**Delivery:** Asynchronous (Sidekiq job)

### 3.2 Rights window expiring
**Trigger:** Daily scheduled job checks for rights windows expiring within 14 days
**Recipient:** Admin users with `content_admin` or `super_admin` role
**Subject:** "Rights expiring: [count] books in next 14 days"
**Content:**
- List of books with expiring rights
- Publisher name for each
- Expiration date
- Link to rights management in admin console

**Delivery:** Asynchronous, once daily

### 3.3 New publisher payout ready for review
**Trigger:** After `PayoutCalculationService` completes for a period
**Recipient:** Admin users with `finance_admin` or `super_admin` role
**Subject:** "Payout statements ready for review: [Period]"
**Content:**
- Period date range
- Number of statements generated
- Total payout amount across all publishers
- Link to review in admin console

---

## 4) Publisher Emails (Admin-Triggered)

### 4.1 Statement available
**Trigger:** Admin approves publisher statement (or all statements for a period)
**Recipient:** Publisher billing_email
**Subject:** "Your Storytime statement for [Month Year] is ready"
**Content:**
- Period date range
- Summary: total minutes watched, total plays, payout amount
- Note about payment processing timeline
- Support contact

**Delivery:** Asynchronous, triggered by admin approval action

### 4.2 Payment processed
**Trigger:** Stripe transfer completed successfully
**Recipient:** Publisher billing_email
**Subject:** "Storytime payment processed: $[amount]"
**Content:**
- Payment amount and currency
- Period covered
- Stripe transfer reference (last 4 chars)
- Expected arrival in bank account

---

## 5) Mailer Architecture

### 5.1 Mailer classes
Create these Action Mailer classes:

**ParentMailer**
- `welcome(user)`
- `password_reset(user, token)`
- `account_deleted(email, deleted_at)`
- `password_changed(user)`

**AdminMailer**
- `video_processing_failed(video_asset, admin_users)`
- `rights_expiring(expiring_rights, admin_users)`
- `payouts_ready_for_review(payout_period, admin_users)`

**PublisherMailer**
- `statement_available(publisher_statement)`
- `payment_processed(publisher_statement)`

### 5.2 Email layout
Create a shared email layout (`app/views/layouts/mailer.html.erb`):
- Simple, clean design
- Storytime logo at top
- Content area
- Footer with:
  - Company info
  - Privacy policy link
  - Unsubscribe link (for publisher emails — future)
  - Support contact

### 5.3 Background delivery
All emails should be delivered via Sidekiq:
```ruby
class ParentMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail(to: @user.email, subject: "Welcome to Storytime!")
  end
end

# Usage (in controller or service):
ParentMailer.welcome(user).deliver_later
```

---

## 6) Scheduled Email Jobs

### 6.1 RightsExpirationNotifier job
- Runs daily at 9:00 AM UTC
- Queries rights_windows expiring within 14 days
- Sends summary email to content/super admins
- Only sends if there are expiring rights (no empty emails)

### 6.2 Job scheduling
Use `sidekiq-cron` or `sidekiq-scheduler` gem:
```yaml
# config/sidekiq_schedule.yml
rights_expiration_check:
  cron: "0 9 * * *"
  class: RightsExpirationNotifierJob
```

Add to Gemfile:
```ruby
gem "sidekiq-cron", "~> 2.0"
```

---

## 7) iOS Changes

### 7.1 Forgot password flow
Add to `LoginView`:
- "Forgot Password?" link below the password field
- Tapping opens a sheet with email input
- Calls `POST /api/v1/auth/password/reset` with email
- Shows confirmation: "If an account exists, a reset link has been sent."
- Password reset itself happens via web (follow link in email)

### 7.2 APIClient additions
```swift
func requestPasswordReset(email: String) async throws
```

---

## 8) Testing Requirements

### Backend tests
- ParentMailer: verify welcome email contains expected content
- ParentMailer: verify password reset email contains token link
- AdminMailer: verify video failure email sent to correct admin roles
- RightsExpirationNotifierJob: verify only sends when rights are expiring
- Delivery: verify all emails use `deliver_later` (async)

### Development testing
- Verify `letter_opener` displays emails in development
- Test email rendering across email clients (Gmail, Apple Mail)

---

## 9) Deliverables for Codex (Email & Notifications)
Implement:
- Action Mailer configuration for chosen provider (Postmark recommended)
- `letter_opener` gem for development
- `premailer-rails` for CSS inlining
- Shared email layout with branding
- ParentMailer: welcome, password_reset, account_deleted, password_changed
- AdminMailer: video_processing_failed, rights_expiring, payouts_ready
- PublisherMailer: statement_available, payment_processed
- Devise `:recoverable` module with password reset endpoints
- RightsExpirationNotifierJob (daily cron via sidekiq-cron)
- iOS: Forgot Password flow on LoginView
- Wire all emails to `deliver_later` for async delivery
- Environment variables in `.env.example`
