require "rails_helper"

RSpec.describe ParentalConsent, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:policy_version) }
  it { is_expected.to validate_presence_of(:consented_at) }
end
