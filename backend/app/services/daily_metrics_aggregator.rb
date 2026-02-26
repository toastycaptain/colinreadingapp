class DailyMetricsAggregator
  PLAY_START = UsageEvent.event_types.fetch("play_start")
  PLAY_END = UsageEvent.event_types.fetch("play_end")
  HEARTBEAT = UsageEvent.event_types.fetch("heartbeat")

  def initialize(metric_date: Date.current)
    @metric_date = metric_date
  end

  def call
    rows = aggregated_rows

    DailyMetric.transaction do
      DailyMetric.where(metric_date: @metric_date).delete_all

      rows.each do |row|
        DailyMetric.create!(
          metric_date: @metric_date,
          publisher_id: row.publisher_id,
          book_id: row.book_id,
          play_starts: row.play_starts.to_i,
          play_ends: row.play_ends.to_i,
          unique_children: row.unique_children.to_i,
          minutes_watched: row.minutes_watched.to_f.round(2),
          avg_completion_rate: row.avg_completion_rate.to_f.round(4),
        )
      end
    end

    rows.size
  end

  private

  def aggregated_rows
    UsageEvent
      .joins(book: :publisher)
      .left_joins(book: :video_asset)
      .where(occurred_at: @metric_date.beginning_of_day..@metric_date.end_of_day)
      .group("books.publisher_id", "usage_events.book_id")
      .select(
        "books.publisher_id AS publisher_id",
        "usage_events.book_id AS book_id",
        "SUM(CASE WHEN usage_events.event_type = #{PLAY_START} THEN 1 ELSE 0 END) AS play_starts",
        "SUM(CASE WHEN usage_events.event_type = #{PLAY_END} THEN 1 ELSE 0 END) AS play_ends",
        "COUNT(DISTINCT usage_events.child_profile_id) AS unique_children",
        "COALESCE(SUM(CASE WHEN usage_events.event_type IN (#{PLAY_END}, #{HEARTBEAT}) THEN usage_events.position_seconds ELSE 0 END) / 60.0, 0) AS minutes_watched",
        "COALESCE(AVG(CASE WHEN usage_events.event_type = #{PLAY_END} AND video_assets.duration_seconds > 0 THEN LEAST(usage_events.position_seconds::numeric / video_assets.duration_seconds, 1.0) ELSE NULL END), 0) AS avg_completion_rate",
      )
  end
end
