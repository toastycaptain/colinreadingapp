require "rails_helper"

RSpec.describe DailyMetricsAggregator do
  it "stores aggregated daily metrics" do
    publisher = create(:publisher)
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
           occurred_at: Date.current.noon)

    create(:usage_event,
           child_profile: child,
           book: book,
           playback_session: playback_session,
           event_type: :heartbeat,
           position_seconds: 30,
           occurred_at: Date.current.noon + 30.seconds)

    create(:usage_event,
           child_profile: child,
           book: book,
           playback_session: playback_session,
           event_type: :heartbeat,
           position_seconds: 60,
           occurred_at: Date.current.noon + 60.seconds)

    create(:usage_event,
           child_profile: child,
           book: book,
           playback_session: playback_session,
           event_type: :play_end,
           position_seconds: 60,
           occurred_at: Date.current.noon + 70.seconds)

    count = described_class.new(metric_date: Date.current).call

    expect(count).to eq(1)
    metric = DailyMetric.find_by(metric_date: Date.current, publisher: publisher, book: book)
    expect(metric).to be_present
    expect(metric.play_starts).to eq(1)
    expect(metric.play_ends).to eq(1)
    expect(metric.minutes_watched.to_f).to eq(1.0)
  end
end
