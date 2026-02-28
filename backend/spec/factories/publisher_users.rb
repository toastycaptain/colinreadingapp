FactoryBot.define do
  factory :publisher_user do
    association :publisher
    sequence(:email) { |n| "publisher-user#{n}@example.com" }
    password { "Password123!" }
    password_confirmation { "Password123!" }
    role { :owner }
  end
end
