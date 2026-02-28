require "rails_helper"

RSpec.describe DataExport, type: :model do
  it { is_expected.to belong_to(:publisher).optional }
  it { is_expected.to validate_presence_of(:export_type) }

  it do
    is_expected.to define_enum_for(:export_type).with_values(
      usage_daily: 0,
      analytics_daily: 1,
      statement_breakdown: 2,
    )
  end

  it "requires publisher_id for publisher user requests" do
    publisher_user = create(:publisher_user)
    export = build(:data_export, requested_by: publisher_user, publisher: nil)

    expect(export).not_to be_valid
    expect(export.errors[:publisher_id]).to include("can't be blank")
  end
end
