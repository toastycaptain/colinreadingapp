require "csv"
require "fileutils"

class GenerateDataExportJob < ApplicationJob
  queue_as :maintenance

  def perform(data_export_id)
    data_export = DataExport.find(data_export_id)
    data_export.update!(status: :processing, error_message: nil)

    csv_data = case data_export.export_type.to_sym
               when :usage_daily
                 usage_daily_csv(data_export)
               when :analytics_daily
                 analytics_daily_csv(data_export)
               when :statement_breakdown
                 statement_breakdown_csv(data_export)
               else
                 raise "Unsupported export type: #{data_export.export_type}"
               end

    path = write_csv_file(data_export.id, csv_data)

    data_export.update!(
      status: :ready,
      generated_at: Time.current,
      file_url: path.to_s,
    )
  rescue StandardError => e
    data_export&.update(status: :failed, error_message: e.message.truncate(1000))
    raise
  end

  private

  def usage_daily_csv(data_export)
    rows = UsageReportQuery.new(
      start_date: parsed_date(data_export.params["start_date"], 30.days.ago.to_date),
      end_date: parsed_date(data_export.params["end_date"], Date.current),
      publisher_id: scoped_publisher_id(data_export),
      book_id: data_export.params["book_id"],
      child_profile_id: data_export.params["child_profile_id"],
    ).call

    CSV.generate(headers: true) do |csv|
      csv << %w[date publisher_name book_id book_title minutes_watched play_starts play_ends unique_children]
      rows.each do |row|
        csv << [
          row[:date],
          row[:publisher_name],
          row[:book_id],
          row[:book_title],
          row[:minutes_watched],
          row[:play_starts],
          row[:play_ends],
          row[:unique_children],
        ]
      end
    end
  end

  def analytics_daily_csv(data_export)
    start_date = parsed_date(data_export.params["start_date"], 30.days.ago.to_date)
    end_date = parsed_date(data_export.params["end_date"], Date.current)

    relation = DailyMetric
      .includes(:publisher, :book)
      .where(metric_date: start_date..end_date)

    relation = relation.where(publisher_id: scoped_publisher_id(data_export)) if scoped_publisher_id(data_export).present?
    relation = relation.where(book_id: data_export.params["book_id"]) if data_export.params["book_id"].present?

    CSV.generate(headers: true) do |csv|
      csv << %w[date publisher_id publisher_name book_id book_title minutes_watched play_starts play_ends unique_children avg_completion_rate]

      relation.order(metric_date: :asc, publisher_id: :asc, book_id: :asc).find_each do |metric|
        csv << [
          metric.metric_date,
          metric.publisher_id,
          metric.publisher&.name,
          metric.book_id,
          metric.book&.title,
          metric.minutes_watched,
          metric.play_starts,
          metric.play_ends,
          metric.unique_children,
          metric.avg_completion_rate,
        ]
      end
    end
  end

  def statement_breakdown_csv(data_export)
    start_date = parsed_date(data_export.params["start_date"], 30.days.ago.to_date)
    end_date = parsed_date(data_export.params["end_date"], Date.current)

    statements = PublisherStatement
      .includes(:publisher, :payout_period)
      .joins(:payout_period)
      .where(payout_periods: { start_date: ..end_date, end_date: start_date.. })

    statements = statements.where(publisher_id: scoped_publisher_id(data_export)) if scoped_publisher_id(data_export).present?

    CSV.generate(headers: true) do |csv|
      csv << %w[
        statement_id payout_period_id payout_start payout_end publisher_id publisher_name status
        book_id book_title minutes_watched gross_revenue_cents payout_amount_cents
      ]

      statements.order("payout_periods.start_date DESC, publisher_statements.id DESC").find_each do |statement|
        breakdown_rows = Array.wrap(statement.breakdown).select { |row| row.is_a?(Hash) }

        if breakdown_rows.empty?
          csv << [
            statement.id,
            statement.payout_period_id,
            statement.payout_period.start_date,
            statement.payout_period.end_date,
            statement.publisher_id,
            statement.publisher.name,
            statement.status,
            nil,
            nil,
            statement.minutes_watched,
            statement.gross_revenue_cents,
            statement.payout_amount_cents,
          ]
          next
        end

        breakdown_rows.each do |row|
          csv << [
            statement.id,
            statement.payout_period_id,
            statement.payout_period.start_date,
            statement.payout_period.end_date,
            statement.publisher_id,
            statement.publisher.name,
            statement.status,
            row["book_id"],
            row["book_title"],
            row["minutes_watched"],
            row["gross_revenue_cents"],
            statement.payout_amount_cents,
          ]
        end
      end
    end
  end

  def scoped_publisher_id(data_export)
    data_export.publisher_id.presence || data_export.params["publisher_id"].presence
  end

  def parsed_date(value, default)
    return default if value.blank?

    Date.parse(value)
  rescue ArgumentError
    default
  end

  def write_csv_file(export_id, csv_data)
    directory = Rails.root.join("tmp", "exports")
    FileUtils.mkdir_p(directory)

    filename = "data_export_#{export_id}_#{Time.current.utc.strftime('%Y%m%d%H%M%S')}.csv"
    path = directory.join(filename)
    File.write(path, csv_data)
    path
  end
end
