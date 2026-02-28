require "rails_helper"

RSpec.describe AdminUser, type: :model do
  it do
    is_expected.to define_enum_for(:role).with_values(
      super_admin: 0,
      content_admin: 1,
      finance_admin: 2,
      support_admin: 3,
      analytics_admin: 4,
      compliance_admin: 5,
    )
  end

  it "builds with valid defaults" do
    expect(build(:admin_user)).to be_valid
  end
end
