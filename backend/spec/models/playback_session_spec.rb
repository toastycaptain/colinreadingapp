require "rails_helper"

RSpec.describe PlaybackSession, type: :model do
  it { is_expected.to belong_to(:child_profile) }
  it { is_expected.to belong_to(:book) }
  it { is_expected.to validate_presence_of(:issued_at) }
  it { is_expected.to validate_presence_of(:expires_at) }

  it "requires expires_at to be after issued_at" do
    session = build(:playback_session, issued_at: Time.current, expires_at: 1.minute.ago)

    expect(session).not_to be_valid
    expect(session.errors[:expires_at]).to include("must be after issued_at")
  end
end
