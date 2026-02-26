require "rails_helper"

RSpec.describe DailyMetricsAggregator do
  it "stores aggregated daily metrics" do
    publisher = create(:publisher)
    parent = create(:user)
    child = create(:child_profile, user: parent)
    book = create(:book, publisher: publisher)

    create(:usage_event,
           child_profile: child,
           book: book,
           event_type: :play_start,
           occurred_at: Date.current.noon)

    create(:usage_event,
           child_profile: child,
           book: book,
           event_type: :play_end,
           position_seconds: 120,
           occurred_at: Date.current.noon)

    count = described_class.new(metric_date: Date.current).call

    expect(count).to eq(1)
    metric = DailyMetric.find_by(metric_date: Date.current, publisher: publisher, book: book)
    expect(metric).to be_present
    expect(metric.play_starts).to eq(1)
    expect(metric.play_ends).to eq(1)
  end
end
