require "rails_helper"

RSpec.describe PartnershipContract, type: :model do
  it { is_expected.to belong_to(:publisher) }
  it { is_expected.to validate_presence_of(:contract_name) }
  it { is_expected.to define_enum_for(:payment_model).with_values(flat_fee: 0, rev_share: 1, hybrid: 2) }

  it "rejects end_date before start_date" do
    contract = build(:partnership_contract, start_date: Date.current, end_date: 1.day.ago.to_date)

    expect(contract).not_to be_valid
    expect(contract.errors[:end_date]).to include("must be on or after start_date")
  end
end
