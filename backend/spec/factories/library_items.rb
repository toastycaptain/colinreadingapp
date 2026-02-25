FactoryBot.define do
  factory :library_item do
    association :child_profile
    association :book
    association :added_by_user, factory: :user
  end
end
