require "rails_helper"

RSpec.describe UsageEvent, type: :model do
  it { is_expected.to belong_to(:child_profile) }
  it { is_expected.to belong_to(:book) }
  it { is_expected.to belong_to(:playback_session).optional }
  it { is_expected.to validate_presence_of(:event_type) }
  it { is_expected.to validate_presence_of(:occurred_at) }
  it { is_expected.to define_enum_for(:event_type).with_values(play_start: 0, pause: 1, resume: 2, play_end: 3, heartbeat: 4) }
  it { is_expected.to validate_numericality_of(:watched_seconds).is_greater_than_or_equal_to(0).allow_nil }
end
