class Publisher::DashboardController < Publisher::BaseController
  before_action :require_analytics_access!

  def show
    @start_date = parsed_date(params[:start], 30.days.ago.to_date)
    @end_date = parsed_date(params[:end], Date.current)

    metrics = DailyMetric.where(
      publisher_id: current_publisher.id,
      metric_date: @start_date..@end_date,
    )

    @minutes_watched = metrics.sum(:minutes_watched).to_f
    @play_starts = metrics.sum(:play_starts)
    @play_ends = metrics.sum(:play_ends)
    @avg_completion_rate = metrics.average(:avg_completion_rate).to_f
    @unique_children = metrics.sum(:unique_children)

    @top_books = metrics
      .joins(:book)
      .group("books.id", "books.title")
      .select(
        "books.id AS book_id",
        "books.title AS book_title",
        "SUM(daily_metrics.minutes_watched) AS minutes_watched",
        "SUM(daily_metrics.unique_children) AS unique_children",
      )
      .order("minutes_watched DESC")
      .limit(10)
  end
end
