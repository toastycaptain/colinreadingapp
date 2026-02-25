require "rails_helper"

RSpec.describe UsageEvent, type: :model do
  it { is_expected.to belong_to(:child_profile) }
  it { is_expected.to belong_to(:book) }
  it { is_expected.to validate_presence_of(:event_type) }
  it { is_expected.to validate_presence_of(:occurred_at) }
  it { is_expected.to define_enum_for(:event_type).with_values(play_start: 0, pause: 1, resume: 2, play_end: 3, heartbeat: 4) }
end
