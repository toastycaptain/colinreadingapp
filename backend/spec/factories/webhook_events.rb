FactoryBot.define do
  factory :webhook_event do
    provider { "mux" }
    sequence(:event_id) { |n| "evt_#{n}" }
    event_type { "video.asset.ready" }
    status { :received }
    payload { { "type" => event_type, "id" => event_id } }
    processed_at { nil }
  end
end
