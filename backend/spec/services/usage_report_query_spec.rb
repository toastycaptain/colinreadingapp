require "rails_helper"

RSpec.describe UsageReportQuery do
  let(:publisher) { create(:publisher, name: "Acorn House") }
  let(:parent) { create(:user) }
  let(:child) { create(:child_profile, user: parent) }
  let(:book) { create(:book, publisher: publisher, title: "Moon Story") }
  let(:metric_date) { Date.current }

  def report_for_today
    described_class.new(start_date: metric_date, end_date: metric_date).call.first
  end

  it "uses watched deltas instead of summing absolute positions" do
    session = create(:playback_session, child_profile: child, book: book)

    create(:usage_event, child_profile: child, book: book, playback_session: session, event_type: :play_start, position_seconds: 0, occurred_at: metric_date.noon)
    create(:usage_event, child_profile: child, book: book, playback_session: session, event_type: :heartbeat, position_seconds: 30, occurred_at: metric_date.noon + 30.seconds)
    create(:usage_event, child_profile: child, book: book, playback_session: session, event_type: :heartbeat, position_seconds: 60, occurred_at: metric_date.noon + 60.seconds)

    row = report_for_today

    expect(row).to be_present
    expect(row[:minutes_watched]).to eq(1.0)
    expect(row[:play_starts]).to eq(1)
    expect(row[:unique_children]).to eq(1)
  end

  it "clamps backwards seeks and large forward jumps" do
    session = create(:playback_session, child_profile: child, book: book)

    create(:usage_event, child_profile: child, book: book, playback_session: session, event_type: :play_start, position_seconds: 0, occurred_at: metric_date.noon)
    create(:usage_event, child_profile: child, book: book, playback_session: session, event_type: :heartbeat, position_seconds: 40, occurred_at: metric_date.noon + 40.seconds)
    create(:usage_event, child_profile: child, book: book, playback_session: session, event_type: :heartbeat, position_seconds: 20, occurred_at: metric_date.noon + 80.seconds)
    create(:usage_event, child_profile: child, book: book, playback_session: session, event_type: :heartbeat, position_seconds: 420, occurred_at: metric_date.noon + 120.seconds)

    row = report_for_today

    expect(row).to be_present
    expect(row[:minutes_watched]).to eq(0.67)
  end
end
