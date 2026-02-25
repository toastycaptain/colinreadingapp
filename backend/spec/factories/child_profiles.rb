FactoryBot.define do
  factory :child_profile do
    association :user
    sequence(:name) { |n| "Child #{n}" }
    avatar_url { "https://example.com/avatar.png" }
  end
end
