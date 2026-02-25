class UsageReportQuery
  PLAY_START = UsageEvent.event_types.fetch("play_start")
  PLAY_END = UsageEvent.event_types.fetch("play_end")
  HEARTBEAT = UsageEvent.event_types.fetch("heartbeat")

  def initialize(start_date:, end_date:, publisher_id: nil, book_id: nil)
    @start_date = start_date
    @end_date = end_date
    @publisher_id = publisher_id
    @book_id = book_id
  end

  def call
    relation = UsageEvent
      .joins(book: :publisher)
      .where(occurred_at: time_range)

    relation = relation.where(books: { publisher_id: @publisher_id }) if @publisher_id.present?
    relation = relation.where(book_id: @book_id) if @book_id.present?

    relation
      .select(
        "DATE(usage_events.occurred_at) AS report_date",
        "publishers.name AS publisher_name",
        "books.id AS book_id",
        "books.title AS book_title",
        "COALESCE(SUM(CASE WHEN usage_events.event_type IN (#{PLAY_END}, #{HEARTBEAT}) THEN usage_events.position_seconds ELSE 0 END) / 60.0, 0) AS minutes_watched",
        "SUM(CASE WHEN usage_events.event_type = #{PLAY_START} THEN 1 ELSE 0 END) AS play_starts",
        "SUM(CASE WHEN usage_events.event_type = #{PLAY_END} THEN 1 ELSE 0 END) AS play_ends",
        "COUNT(DISTINCT usage_events.child_profile_id) AS unique_children",
      )
      .group("DATE(usage_events.occurred_at)", "publishers.name", "books.id", "books.title")
      .order("report_date DESC, publisher_name ASC, book_title ASC")
      .map do |row|
        {
          date: row.report_date,
          publisher_name: row.publisher_name,
          book_id: row.book_id,
          book_title: row.book_title,
          minutes_watched: row.minutes_watched.to_f.round(2),
          play_starts: row.play_starts.to_i,
          play_ends: row.play_ends.to_i,
          unique_children: row.unique_children.to_i,
        }
      end
  end

  private

  def time_range
    @start_date.beginning_of_day..@end_date.end_of_day
  end
end
