require "rails_helper"

RSpec.describe Book, type: :model do
  it { is_expected.to belong_to(:publisher).optional }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:author) }
  it { is_expected.to define_enum_for(:status).with_values(draft: 0, active: 1, inactive: 2) }

  it "rejects age ranges where min is above max" do
    book = build(:book, age_min: 8, age_max: 3)

    expect(book).not_to be_valid
    expect(book.errors[:age_max]).to include("must be greater than or equal to age_min")
  end
end
