FactoryBot.define do
  factory :parental_consent do
    association :user
    policy_version { "2026-02" }
    consented_at { Time.current }
    metadata { {} }
    revoked_at { nil }
  end
end
