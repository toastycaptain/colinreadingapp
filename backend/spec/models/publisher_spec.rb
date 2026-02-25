require "rails_helper"

RSpec.describe Publisher, type: :model do
  subject(:publisher) { build(:publisher) }

  it { is_expected.to have_many(:books) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to define_enum_for(:status).with_values(active: 0, inactive: 1) }

  it "validates uniqueness of name" do
    create(:publisher, name: "Unique Name")
    duplicate = build(:publisher, name: "Unique Name")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to include("has already been taken")
  end
end
