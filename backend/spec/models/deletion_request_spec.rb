require "rails_helper"

RSpec.describe DeletionRequest, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:child_profile).optional }
  it { is_expected.to validate_presence_of(:requested_at) }

  it "supports expected status values" do
    expect(described_class.statuses).to eq(
      "requested" => "requested",
      "processing" => "processing",
      "completed" => "completed",
      "failed" => "failed",
    )
  end
end
