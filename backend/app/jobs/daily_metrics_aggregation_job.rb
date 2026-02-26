class DailyMetricsAggregationJob < ApplicationJob
  queue_as :analytics

  def perform(metric_date = Date.yesterday)
    DailyMetricsAggregator.new(metric_date: Date.parse(metric_date.to_s)).call
  rescue StandardError => e
    AdminAlertMailer.with(subject: "Daily metrics aggregation failed", body: e.message).generic_alert.deliver_later
    raise
  end
end
