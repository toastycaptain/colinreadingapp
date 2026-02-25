require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it { is_expected.to have_many(:child_profiles).dependent(:destroy) }
  it { is_expected.to define_enum_for(:role).with_values(parent: 0, admin: 1) }

  it "is valid with factory defaults" do
    expect(user).to be_valid
  end
end
