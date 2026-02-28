require "rails_helper"

RSpec.describe AdminAuthorizationAdapter do
  def adapter_for(admin)
    described_class.new(nil, admin)
  end

  it "allows support admins to read child resources only" do
    admin = create(:admin_user, role: :support_admin)
    adapter = adapter_for(admin)

    expect(adapter.authorized?(:read, ChildProfile)).to be(true)
    expect(adapter.authorized?(:read, UsageEvent)).to be(true)
    expect(adapter.authorized?(:update, PayoutPeriod)).to be(false)
  end

  it "allows finance admins to manage payout periods and view statements" do
    admin = create(:admin_user, role: :finance_admin)
    adapter = adapter_for(admin)

    expect(adapter.authorized?(:update, PayoutPeriod)).to be(true)
    expect(adapter.authorized?(:read, PublisherStatement)).to be(true)
    expect(adapter.authorized?(:read, ChildProfile)).to be(false)
  end

  it "allows compliance admins to process deletion requests" do
    admin = create(:admin_user, role: :compliance_admin)
    adapter = adapter_for(admin)

    expect(adapter.authorized?(:mark_processing, DeletionRequest)).to be(true)
    expect(adapter.authorized?(:read, ParentalConsent)).to be(true)
    expect(adapter.authorized?(:read, PublisherStatement)).to be(false)
  end
end
