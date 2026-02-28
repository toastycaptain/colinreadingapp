require "rails_helper"

RSpec.describe AuditLog, type: :model do
  it { is_expected.to validate_presence_of(:action) }
  it "auto-populates occurred_at on create" do
    log = described_class.create!(actor: create(:admin_user), action: "view_child_profile")
    expect(log.occurred_at).to be_present
  end

  it "records a typed audit event" do
    admin = create(:admin_user)
    child = create(:child_profile)

    log = described_class.record!(
      actor: admin,
      action: "view_child_profile",
      subject: child,
      metadata: { source: "spec" },
    )

    expect(log.actor).to eq(admin)
    expect(log.subject).to eq(child)
    expect(log.metadata["source"]).to eq("spec")
  end
end
