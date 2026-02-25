FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "parent#{n}@example.com" }
    password { "Password123!" }
    role { :parent }
    jti { SecureRandom.uuid }
  end
end
