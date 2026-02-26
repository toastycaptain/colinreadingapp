require "rails_helper"

RSpec.describe PublisherStatement, type: :model do
  it { is_expected.to belong_to(:payout_period) }
  it { is_expected.to belong_to(:publisher) }

  it "enforces one statement per publisher per payout period" do
    period = create(:payout_period)
    publisher = create(:publisher)
    create(:publisher_statement, payout_period: period, publisher: publisher)

    duplicate = build(:publisher_statement, payout_period: period, publisher: publisher)
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:publisher_id]).to include("has already been taken")
  end

  it do
    is_expected.to define_enum_for(:status).with_values(
      draft: 0,
      approved: 1,
      paid: 2,
      failed: 3,
    )
  end
end
