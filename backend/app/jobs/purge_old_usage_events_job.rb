class PurgeOldUsageEventsJob < ApplicationJob
  queue_as :maintenance

  def perform(retention_days = ENV.fetch("DATA_RETENTION_DAYS", "365").to_i)
    cutoff = retention_days.days.ago

    UsageEvent.where("occurred_at < ?", cutoff).delete_all
    PlaybackSession.where("expires_at < ?", cutoff).delete_all
    WebhookEvent.where("created_at < ?", cutoff).delete_all
  rescue StandardError => e
    AdminAlertMailer.with(subject: "Retention purge failed", body: e.message).generic_alert.deliver_later
    raise
  end
end
