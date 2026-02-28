class Publisher::AnalyticsController < Publisher::BaseController
  before_action :require_analytics_access!

  def show
    @start_date = parsed_date(params[:start], 30.days.ago.to_date)
    @end_date = parsed_date(params[:end], Date.current)
    @book_id = params[:book_id].presence

    @books = current_publisher.books.order(:title)

    @metrics = DailyMetric
      .where(publisher_id: current_publisher.id, metric_date: @start_date..@end_date)
      .includes(:book)

    @metrics = @metrics.where(book_id: @book_id) if @book_id.present?
    @metrics = @metrics.order(metric_date: :asc)

    @daily_rows = @metrics.map do |metric|
      {
        date: metric.metric_date,
        book_id: metric.book_id,
        book_title: metric.book&.title,
        minutes_watched: metric.minutes_watched.to_f,
        unique_children: metric.unique_children,
        play_starts: metric.play_starts,
        play_ends: metric.play_ends,
        avg_completion_rate: metric.avg_completion_rate.to_f,
      }
    end

    @top_books = @metrics
      .group(:book_id)
      .sum(:minutes_watched)
      .sort_by { |(_, minutes)| -minutes.to_f }
      .first(10)
      .map do |book_id, minutes|
        book = @books.find { |row| row.id == book_id }
        { book_id: book_id, book_title: book&.title, minutes_watched: minutes.to_f }
      end
  end
end
