FactoryBot.define do
  factory :usage_event do
    association :child_profile
    association :book
    playback_session { nil }
    event_type { :play_start }
    position_seconds { 10 }
    watched_seconds { nil }
    client_event_id { nil }
    occurred_at { Time.current }
    metadata { {} }
  end
end
