class RoyaltyCalculator
  PLAY_START = UsageEvent.event_types.fetch("play_start")
  PLAY_END = UsageEvent.event_types.fetch("play_end")
  HEARTBEAT = UsageEvent.event_types.fetch("heartbeat")

  def initialize(
    payout_period:,
    price_per_minute_cents: ENV.fetch("PAYOUT_PRICE_PER_MINUTE_CENTS", "2").to_i,
    platform_fee_bps: ENV.fetch("PAYOUT_PLATFORM_FEE_BPS", "1500").to_i
  )
    @payout_period = payout_period
    @price_per_minute_cents = price_per_minute_cents
    @platform_fee_bps = platform_fee_bps
  end

  def call
    publisher_ids = base_scope.distinct.pluck("books.publisher_id")

    publisher_ids.map do |publisher_id|
      publisher = Publisher.find(publisher_id)
      publisher_scope = base_scope.where(books: { publisher_id: publisher_id })

      watched_seconds = publisher_scope.where(event_type: [HEARTBEAT, PLAY_END]).sum(:position_seconds)
      minutes_watched = (watched_seconds.to_f / 60.0).round(2)
      play_starts = publisher_scope.where(event_type: PLAY_START).count
      play_ends = publisher_scope.where(event_type: PLAY_END).count
      unique_children = publisher_scope.select(:child_profile_id).distinct.count

      gross_revenue_cents = (minutes_watched * @price_per_minute_cents).round
      platform_fee_cents = (gross_revenue_cents * @platform_fee_bps / 10_000.0).round
      net_revenue_cents = [gross_revenue_cents - platform_fee_cents, 0].max

      rev_share_bps = active_rev_share_bps(publisher)
      payout_amount_cents = (net_revenue_cents * rev_share_bps / 10_000.0).round

      {
        publisher: publisher,
        minutes_watched: minutes_watched,
        play_starts: play_starts,
        play_ends: play_ends,
        unique_children: unique_children,
        gross_revenue_cents: gross_revenue_cents,
        platform_fee_cents: platform_fee_cents,
        net_revenue_cents: net_revenue_cents,
        rev_share_bps: rev_share_bps,
        payout_amount_cents: payout_amount_cents,
        breakdown: book_breakdown(publisher_scope),
      }
    end
  end

  private

  def base_scope
    UsageEvent.joins(book: :publisher).where(occurred_at: time_range)
  end

  def time_range
    @payout_period.start_date.beginning_of_day..@payout_period.end_date.end_of_day
  end

  def active_rev_share_bps(publisher)
    publisher.partnership_contracts
      .active_on(@payout_period.end_date)
      .order(start_date: :desc)
      .limit(1)
      .pick(:rev_share_bps)
      .to_i
  end

  def book_breakdown(publisher_scope)
    rows = publisher_scope
      .joins(:book)
      .where(event_type: [HEARTBEAT, PLAY_END])
      .group("books.id", "books.title")
      .select(
        "books.id AS book_id",
        "books.title AS book_title",
        "SUM(usage_events.position_seconds) AS watched_seconds"
      )

    rows.map do |row|
      minutes = row.watched_seconds.to_f / 60.0
      {
        book_id: row.book_id,
        book_title: row.book_title,
        minutes_watched: minutes.round(2),
        gross_revenue_cents: (minutes * @price_per_minute_cents).round,
      }
    end
  end
end
