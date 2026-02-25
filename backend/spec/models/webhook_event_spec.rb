require "rails_helper"

RSpec.describe WebhookEvent, type: :model do
  it { is_expected.to validate_presence_of(:provider) }
  it { is_expected.to validate_presence_of(:event_id) }
  it { is_expected.to validate_presence_of(:event_type) }

  it "validates provider-scoped uniqueness for event_id" do
    create(:webhook_event, provider: "mux", event_id: "evt_1")
    duplicate = build(:webhook_event, provider: "mux", event_id: "evt_1")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:event_id]).to include("has already been taken")
  end

  it "supports expected status values" do
    event = build(:webhook_event, status: :processed)

    expect(event).to be_valid
    expect(described_class.statuses).to eq(
      "received" => "received",
      "processed" => "processed",
      "failed" => "failed",
    )
  end
end
