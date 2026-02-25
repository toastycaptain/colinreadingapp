FactoryBot.define do
  factory :rights_window do
    association :publisher
    association :book
    start_at { 1.day.ago }
    end_at { 7.days.from_now }
    territory { "GLOBAL" }

    trait :expired do
      start_at { 14.days.ago }
      end_at { 7.days.ago }
    end
  end
end
