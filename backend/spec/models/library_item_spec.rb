require "rails_helper"

RSpec.describe LibraryItem, type: :model do
  it { is_expected.to belong_to(:child_profile) }
  it { is_expected.to belong_to(:book) }
  it { is_expected.to belong_to(:added_by_user).class_name("User") }

  it "enforces unique child_profile/book pairs" do
    child = create(:child_profile)
    book = create(:book)
    create(:library_item, child_profile: child, book: book)

    duplicate = build(:library_item, child_profile: child, book: book)
    expect(duplicate).not_to be_valid
  end
end
