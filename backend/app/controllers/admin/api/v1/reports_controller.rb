require "csv"

class Admin::Api::V1::ReportsController < Admin::Api::V1::BaseController
  before_action :require_finance_admin!

  def usage
    rows = UsageReportQuery.new(
      start_date: parsed_date_param(:start, 30.days.ago.to_date),
      end_date: parsed_date_param(:end, Date.current),
      publisher_id: params[:publisher_id],
      book_id: params[:book_id],
    ).call

    respond_to do |format|
      format.json { render json: rows }
      format.csv do
        send_data to_csv(rows),
                  filename: "usage-report-#{params[:start]}-to-#{params[:end]}.csv",
                  type: "text/csv"
      end
    end
  end

  def analytics
    start_date = parsed_date_param(:start, 30.days.ago.to_date)
    end_date = parsed_date_param(:end, Date.current)

    relation = DailyMetric
      .includes(:publisher, :book)
      .where(metric_date: start_date..end_date)

    relation = relation.where(publisher_id: params[:publisher_id]) if params[:publisher_id].present?
    relation = relation.where(book_id: params[:book_id]) if params[:book_id].present?

    rows = relation.order(metric_date: :desc, minutes_watched: :desc).map do |metric|
      {
        date: metric.metric_date,
        publisher_id: metric.publisher_id,
        publisher_name: metric.publisher&.name,
        book_id: metric.book_id,
        book_title: metric.book&.title,
        minutes_watched: metric.minutes_watched.to_f.round(2),
        play_starts: metric.play_starts,
        play_ends: metric.play_ends,
        unique_children: metric.unique_children,
        avg_completion_rate: metric.avg_completion_rate.to_f.round(4),
      }
    end

    render json: rows
  end

  private

  def parsed_date_param(key, default)
    value = params[key]
    return default if value.blank?

    Date.parse(value)
  rescue ArgumentError
    default
  end

  def to_csv(rows)
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
end
