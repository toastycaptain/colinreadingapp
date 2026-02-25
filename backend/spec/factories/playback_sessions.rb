FactoryBot.define do
  factory :playback_session do
    association :child_profile
    association :book
    issued_at { Time.current }
    expires_at { 5.minutes.from_now }
    cloudfront_policy { nil }
  end
end
