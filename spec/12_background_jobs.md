# Storytime Video Library — Background Jobs & Async Processing Spec
> **Goal:** Migrate synchronous operations to Sidekiq background jobs and establish job infrastructure for all async processing needs. Sidekiq and Redis are already configured but zero job classes exist.
> **Depends on:** `01_backend_rails_api.md` (Sidekiq setup), `07_publisher_payout_system.md` (payout jobs), `09_coppa_compliance.md` (data retention job), `10_email_and_notifications.md` (email delivery), `11_analytics_engine.md` (aggregation job).

---

## 0) Current State

What exists:
- Sidekiq gem installed and configured (10 concurrency, `default` queue)
- Redis gem installed
- `config/sidekiq.yml` with single `default` queue
- `ApplicationJob < ActiveJob::Base` (empty base class)
- All webhook processing is synchronous
- All email delivery is synchronous (not yet configured)
- No scheduled/recurring jobs

What's missing:
- No actual job classes
- No queue prioritization
- No job monitoring or alerting
- No error handling/retry strategy
- No scheduled job infrastructure (cron-like recurring jobs)

---

## 1) Queue Architecture

### 1.1 Queue definitions
Define multiple queues with priority ordering:

```yaml
# config/sidekiq.yml
:concurrency: 10
:queues:
  - [critical, 6]
  - [default, 4]
  - [bulk, 2]
  - [scheduled, 1]
```

**Queue purposes:**
- `critical` — Webhook processing, payment operations, time-sensitive work
- `default` — Email delivery, standard async operations
- `bulk` — Analytics aggregation, data exports, report generation
- `scheduled` — Recurring cron jobs (rights expiration checks, data cleanup)

### 1.2 Base job class
Update `ApplicationJob` with standard configuration:

```ruby
class ApplicationJob < ActiveJob::Base
  queue_as :default

  # Retry configuration
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  # Discard jobs that fail permanently
  discard_on ActiveJob::DeserializationError

  # Log all job executions
  around_perform do |job, block|
    Rails.logger.tagged("Job:#{job.class.name}") do
      Rails.logger.info("Starting job with args: #{job.arguments.inspect}")
      block.call
      Rails.logger.info("Completed job successfully")
    end
  end
end
```

---

## 2) Webhook Processing Jobs

### 2.1 MuxWebhookProcessorJob
Move webhook processing from synchronous controller to async job.

**Queue:** `critical`

**Current flow (synchronous):**
```
POST /webhooks/mux → verify signature → process event → respond 200
```

**New flow (async):**
```
POST /webhooks/mux → verify signature → store WebhookEvent → enqueue job → respond 200
POST /webhooks/stripe → verify signature → store WebhookEvent → enqueue job → respond 200
```

**Implementation:**
1. Controller verifies signature and stores raw event in `webhook_events` table (status: `received`)
2. Controller enqueues `MuxWebhookProcessorJob` with `webhook_event_id`
3. Controller returns 200 immediately
4. Job processes the event asynchronously
5. Job updates webhook_event status to `processed` or `failed`

**Benefits:**
- Webhook endpoint responds immediately (Mux has a 5-second timeout)
- Processing failures don't cause webhook retries from Mux
- Failed processing can be retried from the job queue

**Retry strategy:** 3 attempts with exponential backoff

### 2.2 StripeWebhookProcessorJob
Same pattern as Mux webhook processor.

**Queue:** `critical`

Handle events:
- `transfer.created` — log confirmation
- `transfer.failed` — update statement status, notify admin
- `account.updated` — update publisher Stripe status

---

## 3) Email Delivery Jobs

### 3.1 Standard email delivery
All emails use `deliver_later` which automatically queues via ActiveJob/Sidekiq.

**Queue:** `default`

No custom job classes needed — Action Mailer's built-in `deliver_later` handles this. Ensure `config.active_job.queue_adapter = :sidekiq` is set.

### 3.2 Bulk email job (future)
For sending publisher statements to multiple publishers:

**BulkPublisherNotificationJob**
**Queue:** `bulk`

Iterates through approved statements and sends individual emails:
```ruby
class BulkPublisherNotificationJob < ApplicationJob
  queue_as :bulk

  def perform(payout_period_id)
    period = PayoutPeriod.find(payout_period_id)
    period.publisher_statements.approved.find_each do |statement|
      PublisherMailer.statement_available(statement).deliver_later
    end
  end
end
```

---

## 4) Analytics & Aggregation Jobs

### 4.1 DailyMetricsAggregationJob
See `11_analytics_engine.md` for full specification.

**Queue:** `bulk`
**Schedule:** Daily at 2:00 AM UTC

### 4.2 DataRetentionCleanupJob
See `09_coppa_compliance.md` for full specification.

**Queue:** `scheduled`
**Schedule:** Weekly on Sunday at 3:00 AM UTC

---

## 5) Payout Processing Jobs

### 5.1 PayoutCalculationJob
Wraps `PayoutCalculationService` from `07_publisher_payout_system.md`.

**Queue:** `bulk`

```ruby
class PayoutCalculationJob < ApplicationJob
  queue_as :bulk

  def perform(payout_period_id)
    period = PayoutPeriod.find(payout_period_id)
    PayoutCalculationService.new(period).calculate_all
    period.update!(status: :reviewed)
    AdminMailer.payouts_ready_for_review(period, admin_recipients).deliver_later
  end

  private

  def admin_recipients
    AdminUser.where(role: [:finance_admin, :super_admin])
  end
end
```

### 5.2 PayoutProcessingJob
Processes individual publisher payouts via Stripe.

**Queue:** `critical`

```ruby
class PayoutProcessingJob < ApplicationJob
  queue_as :critical
  retry_on Stripe::StripeError, wait: 5.minutes, attempts: 3

  def perform(publisher_statement_id)
    statement = PublisherStatement.find(publisher_statement_id)
    PayoutProcessorService.new.process(statement)
  end
end
```

### 5.3 BulkPayoutProcessingJob
Processes all approved statements for a period.

**Queue:** `bulk`

```ruby
class BulkPayoutProcessingJob < ApplicationJob
  queue_as :bulk

  def perform(payout_period_id)
    period = PayoutPeriod.find(payout_period_id)
    period.publisher_statements.approved.find_each do |statement|
      PayoutProcessingJob.perform_later(statement.id)
    end
  end
end
```

---

## 6) Scheduled Jobs (Cron)

### 6.1 Setup sidekiq-cron
Add scheduling configuration:

```yaml
# config/schedule.yml
daily_metrics_aggregation:
  cron: "0 2 * * *"
  class: DailyMetricsAggregationJob
  queue: bulk
  description: "Aggregate daily usage metrics"

data_retention_cleanup:
  cron: "0 3 * * 0"
  class: DataRetentionCleanupJob
  queue: scheduled
  description: "Clean up expired data per COPPA retention policy"

rights_expiration_check:
  cron: "0 9 * * *"
  class: RightsExpirationNotifierJob
  queue: scheduled
  description: "Notify admins of expiring rights windows"

partition_maintenance:
  cron: "0 1 1 * *"
  class: PartitionMaintenanceJob
  queue: scheduled
  description: "Create next month's usage_events partition"
```

### 6.2 Initializer
```ruby
# config/initializers/sidekiq_cron.rb
if Sidekiq.server?
  schedule = YAML.load_file(Rails.root.join("config", "schedule.yml"))
  Sidekiq::Cron::Job.load_from_hash(schedule)
end
```

---

## 7) Monitoring & Error Handling

### 7.1 Sidekiq Web UI
Mount Sidekiq web interface for admin monitoring:

```ruby
# config/routes.rb
require "sidekiq/web"
require "sidekiq/cron/web"

authenticate :admin_user do
  mount Sidekiq::Web => "/admin/sidekiq"
end
```

**Access control:** Only admin users can access the Sidekiq dashboard. Use the existing ActiveAdmin/Devise authentication.

### 7.2 Dead job handling
Configure dead job behavior:

```ruby
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.death_handlers << ->(job, ex) do
    # Log to error tracking service (Sentry, Honeybadger, etc.)
    Rails.logger.error("Job #{job['class']} died: #{ex.message}")

    # Notify admins for critical job failures
    if job["queue"] == "critical"
      AdminMailer.critical_job_failed(job, ex.message).deliver_later(queue: :default)
    end
  end
end
```

### 7.3 Job-specific error handling patterns

**Idempotent jobs:** All jobs should be safe to retry. Use database unique constraints and `find_or_create_by` patterns to prevent duplicate work.

**Non-retryable errors:** Use `discard_on` for errors that will never succeed on retry:
```ruby
discard_on ActiveRecord::RecordNotFound
discard_on ArgumentError
```

**Retryable errors:** Use `retry_on` with appropriate backoff:
```ruby
retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 5
retry_on Stripe::RateLimitError, wait: 1.minute, attempts: 3
```

---

## 8) Usage Event Ingestion Optimization

### 8.1 Batch insert job
Currently, each usage event from iOS creates an individual database INSERT. At scale, batch insert:

**UsageEventBatchInsertJob**
**Queue:** `default`

**Flow:**
1. iOS sends events to `POST /api/v1/usage_events` (unchanged)
2. Controller pushes event data to a Redis list instead of immediate DB insert
3. Job runs every 30 seconds, pops batch from Redis list, bulk inserts

**When to implement:** Not needed until usage events exceed ~100/second. For MVP, direct insert is fine. Document as a TODO with the threshold.

### 8.2 Heartbeat deduplication
Prevent duplicate heartbeats (e.g., if iOS retries a failed request):
- Add unique constraint or dedup logic: same child_id + book_id + event_type + occurred_at (within 10-second window)
- Implement in the ingestion path, not as a separate job

---

## 9) Testing Requirements

### Job tests
- MuxWebhookProcessorJob: processes each event type correctly
- MuxWebhookProcessorJob: handles missing VideoAsset gracefully
- PayoutCalculationJob: triggers service and updates period status
- PayoutProcessingJob: retries on Stripe errors, discards on RecordNotFound
- BulkPayoutProcessingJob: enqueues individual jobs for each statement

### Integration tests
- Webhook flow: POST webhook → event stored → job processed → model updated
- Email flow: trigger action → job enqueued → email delivered (use `perform_enqueued_jobs`)

### Scheduling tests
- Verify schedule.yml loads without errors
- Verify cron expressions produce expected next-run times

---

## 10) Deliverables for Codex (Background Jobs)
Implement:
- Updated `config/sidekiq.yml` with prioritized queues
- Updated `ApplicationJob` with retry/discard/logging configuration
- MuxWebhookProcessorJob (refactor from synchronous controller)
- StripeWebhookProcessorJob
- PayoutCalculationJob and PayoutProcessingJob wrappers
- BulkPayoutProcessingJob
- RightsExpirationNotifierJob
- PartitionMaintenanceJob (create next month's usage_events partition)
- `config/schedule.yml` with all recurring job definitions
- Sidekiq cron initializer
- Sidekiq Web UI mounted at `/admin/sidekiq` with auth
- Dead job notification handler
- Update webhook controllers to enqueue jobs instead of processing synchronously
- RSpec tests for all jobs
