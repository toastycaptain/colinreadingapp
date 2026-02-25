class LibraryItem < ApplicationRecord
  belongs_to :child_profile
  belongs_to :book
  belongs_to :added_by_user, class_name: "User", inverse_of: :library_items

  validates :book_id, uniqueness: { scope: :child_profile_id }
end
