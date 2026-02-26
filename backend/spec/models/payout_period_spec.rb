require "rails_helper"

RSpec.describe PayoutPeriod, type: :model do
  it { is_expected.to validate_presence_of(:start_date) }
  it { is_expected.to validate_presence_of(:end_date) }
  it { is_expected.to validate_presence_of(:currency) }
  it { is_expected.to have_many(:publisher_statements).dependent(:destroy) }

  it do
    is_expected.to define_enum_for(:status).with_values(
      draft: 0,
      calculating: 1,
      ready: 2,
      paid: 3,
      failed: 4,
    )
  end
end
