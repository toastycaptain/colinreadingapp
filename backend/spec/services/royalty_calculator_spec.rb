require "rails_helper"

RSpec.describe RoyaltyCalculator do
  it "builds publisher royalty rows for a payout period" do
    payout_period = create(:payout_period, start_date: Date.current.beginning_of_month, end_date: Date.current.end_of_month)
    publisher = create(:publisher)
    create(:partnership_contract,
           publisher: publisher,
           status: :active,
           payment_model: :rev_share,
           rev_share_bps: 4000,
           start_date: payout_period.start_date,
           end_date: payout_period.end_date)

    parent = create(:user)
    child = create(:child_profile, user: parent)
    book = create(:book, publisher: publisher)
    playback_session = create(:playback_session, child_profile: child, book: book)

    create(:usage_event,
           child_profile: child,
           book: book,
           playback_session: playback_session,
           event_type: :play_start,
           position_seconds: 0,
           occurred_at: payout_period.start_date.noon)

    create(:usage_event,
           child_profile: child,
           book: book,
           playback_session: playback_session,
           event_type: :heartbeat,
           position_seconds: 30,
           occurred_at: payout_period.start_date.noon + 30.seconds)

    create(:usage_event,
           child_profile: child,
           book: book,
           playback_session: playback_session,
           event_type: :heartbeat,
           position_seconds: 60,
           occurred_at: payout_period.start_date.noon + 60.seconds)

    create(:usage_event,
           child_profile: child,
           book: book,
           playback_session: playback_session,
           event_type: :heartbeat,
           position_seconds: 20,
           occurred_at: payout_period.start_date.noon + 90.seconds)

    create(:usage_event,
           child_profile: child,
           book: book,
           playback_session: playback_session,
           event_type: :heartbeat,
           position_seconds: 420,
           occurred_at: payout_period.start_date.noon + 120.seconds)

    rows = described_class.new(payout_period: payout_period).call

    expect(rows.size).to eq(1)
    expect(rows.first[:publisher]).to eq(publisher)
    expect(rows.first[:minutes_watched]).to eq(1.0)
    expect(rows.first[:gross_revenue_cents]).to be > 0
    expect(rows.first[:payout_amount_cents]).to be > 0
  end
end
