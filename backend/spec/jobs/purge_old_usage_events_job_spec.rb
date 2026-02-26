require "rails_helper"

RSpec.describe PurgeOldUsageEventsJob, type: :job do
  it "removes old usage and playback records" do
    child = create(:child_profile)
    book = create(:book)

    old_event = create(:usage_event, child_profile: child, book: book, occurred_at: 400.days.ago)
    keep_event = create(:usage_event, child_profile: child, book: book, occurred_at: 2.days.ago)

    old_session = create(:playback_session, child_profile: child, book: book, expires_at: 400.days.ago, issued_at: 401.days.ago)
    keep_session = create(:playback_session, child_profile: child, book: book, expires_at: 1.day.from_now)

    described_class.perform_now(365)

    expect(UsageEvent.where(id: old_event.id)).to be_empty
    expect(UsageEvent.where(id: keep_event.id)).to be_present

    expect(PlaybackSession.where(id: old_session.id)).to be_empty
    expect(PlaybackSession.where(id: keep_session.id)).to be_present
  end
end
