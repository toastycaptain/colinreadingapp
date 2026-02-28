class WatchedSecondsQuery
  HEARTBEAT = UsageEvent.event_types.fetch("heartbeat")
  PLAY_END = UsageEvent.event_types.fetch("play_end")
  MAX_DELTA_SECONDS = 300
  SESSION_GAP_SECONDS = 10.minutes.to_i

  class << self
    def relation(base_scope = UsageEvent.all)
      scoped_sql = base_scope.except(:select, :order).select("usage_events.*").to_sql
      UsageEvent.from("(#{annotated_sql(scoped_sql)}) usage_events")
    end

    private

    def annotated_sql(scoped_sql)
      <<~SQL.squish
        SELECT lagged_events.*,
               CASE
                 WHEN lagged_events.watched_seconds IS NOT NULL THEN GREATEST(lagged_events.watched_seconds, 0)
                 WHEN lagged_events.event_type IN (#{HEARTBEAT}, #{PLAY_END}) THEN
                   CASE
                     WHEN lagged_events.position_seconds IS NULL THEN 0
                     WHEN lagged_events.previous_position_seconds IS NULL THEN 0
                     WHEN lagged_events.previous_occurred_at IS NOT NULL
                          AND EXTRACT(EPOCH FROM (lagged_events.occurred_at - lagged_events.previous_occurred_at)) > #{SESSION_GAP_SECONDS}
                       THEN 0
                     WHEN lagged_events.position_seconds - lagged_events.previous_position_seconds < 0 THEN 0
                     WHEN lagged_events.position_seconds - lagged_events.previous_position_seconds > #{MAX_DELTA_SECONDS} THEN 0
                     ELSE lagged_events.position_seconds - lagged_events.previous_position_seconds
                   END
                 ELSE 0
               END AS computed_watched_seconds
        FROM (
          SELECT scoped_events.*,
                 LAG(scoped_events.position_seconds) OVER (
                   PARTITION BY #{partition_key_sql("scoped_events")}
                   ORDER BY scoped_events.occurred_at, scoped_events.id
                 ) AS previous_position_seconds,
                 LAG(scoped_events.occurred_at) OVER (
                   PARTITION BY #{partition_key_sql("scoped_events")}
                   ORDER BY scoped_events.occurred_at, scoped_events.id
                 ) AS previous_occurred_at
          FROM (#{scoped_sql}) scoped_events
        ) lagged_events
      SQL
    end

    def partition_key_sql(table_alias)
      "COALESCE(#{table_alias}.playback_session_id::text, CONCAT(#{table_alias}.child_profile_id::text, '-', #{table_alias}.book_id::text))"
    end
  end
end
