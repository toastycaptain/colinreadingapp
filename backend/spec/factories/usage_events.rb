FactoryBot.define do
  factory :usage_event do
    association :child_profile
    association :book
    event_type { :play_start }
    position_seconds { 10 }
    occurred_at { Time.current }
    metadata { {} }
  end
end
